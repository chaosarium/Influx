#![allow(unused_imports)]
use ts_rs::TS;
use axum::{
    extract::{Path, Query, State},
    response::IntoResponse, http::StatusCode, Json, response::Response
};
use serde::{Deserialize, Serialize};
use crate::{ServerState, db::models::{lang::LanguageEntry, vocab::{TokenStatus, SRSInfo, self}, phrase::{mk_phrase_trie, Phrase}}, utils::trie::Trie};
use crate::{db::{DB, models::vocab::Token}, doc_store};
use crate::doc_store::DocEntry;
use crate::doc_store::{
    gt_md_file_list_w_metadata,
    read_md_file,
};
use crate::prelude::*;
use serde_json::json;
use surrealdb::sql;
use crate::nlp;
use std::path::PathBuf;

// https://github.com/tokio-rs/axum/blob/main/examples/anyhow-error-response/src/main.rs
pub struct ServerError(anyhow::Error);
impl IntoResponse for ServerError {
    fn into_response(self) -> Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Something went wrong: {}", self.0),
        )
            .into_response()
    }
}
impl<E> From<E> for ServerError
where
    E: Into<anyhow::Error>,
{
    fn from(err: E) -> Self {
        Self(err.into())
    }
}

pub async fn hello_world() -> &'static str {
    "hello world from the influx server :p root route might not be the most useful"
}

pub async fn connection_test() -> impl IntoResponse {
    StatusCode::OK
}

#[deprecated]
pub async fn todos_index(
    State(ServerState { db, .. }): State<ServerState>, 
) -> impl IntoResponse {
    let todos = db.get_todos_sql().await.unwrap();
    Json(todos)
}

#[deprecated]
#[derive(Debug, Deserialize)]
pub struct CreateTodo {
    text: String,
}

#[deprecated]
pub async fn todos_create(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<CreateTodo>,
) -> impl IntoResponse {
    let todo = db.add_todo_sql(payload.text).await.unwrap();

    (StatusCode::CREATED, Json(todo))
}

#[deprecated]
pub async fn todos_delete(
    State(ServerState { db, .. }): State<ServerState>, 
    Path(id): Path<String>
) -> impl IntoResponse {
    // db.delete_todo_sql(
    //     surrealdb::sql::thing(&id).unwrap()
    // ).await.unwrap();
    (StatusCode::NO_CONTENT, Json(()))
}

#[derive(Debug, Deserialize)]
pub struct GetDocsList {
    lang: String,
}

// #[derive(TS)]
// #[ts(export, export_to = "../influx_ui/src/lib/types/")]
// struct GetLangListResponse (Vec<LanguageEntry>);

pub async fn get_language_list(
    State(ServerState { influx_path, db }): State<ServerState>, 
) -> Result<Json<Vec<LanguageEntry>>, ServerError> {
    let languages = db.get_languages_vec().await?;
    Ok(Json(languages))
}

pub async fn get_language_by_id(
    State(ServerState { influx_path, db }): State<ServerState>, 
    Path(id): Path<String>
) -> Result<Json<Option<LanguageEntry>>, ServerError> {
    let language = db.get_language(id).await?;
    Ok(Json(language))
}


pub async fn get_docs_list(
    State(ServerState { influx_path, .. }): State<ServerState>, 
    Path(lang_id): Path<String>
) -> Response {

    // check if lang_id exists, if not return 404
    let settings = doc_store::read_settings_file(influx_path.clone()).unwrap();
    let lang_exists = settings.lang.iter().any(|l| l.identifier == lang_id);
    if !lang_exists {
        return (StatusCode::NOT_FOUND, Json(json!({
            "error": format!("lang_id {} not found", lang_id),
        }))).into_response()
    }

    match gt_md_file_list_w_metadata(
        influx_path.join(PathBuf::from(lang_id))
    ) {
        Ok(list) => (StatusCode::OK, Json(list)).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({
            "error": format!("failed to access lang_id content folder on disk: {}", e),
        }))).into_response()
    }

}

pub fn get_language_code(settings: &doc_store::Settings, lang_id: String) -> Option<String> {
    settings
        .lang
        .iter()
        .find(|l| l.identifier == lang_id)
        .map(|l| l.code.clone())
}


// TODO do error handling like above
pub async fn get_doc(
    State(ServerState { db, influx_path }): State<ServerState>, 
    Path((lang_id, file)): Path<(String, String)>
) -> impl IntoResponse {

    // check if lang_id exists, if not return 404
    let settings = doc_store::read_settings_file(influx_path.clone()).unwrap();
    let lang_exists = settings.lang.iter().any(|l| l.identifier == lang_id);
    if !lang_exists {
        return (StatusCode::NOT_FOUND, Json(json!({
            "error": format!("lang_id {} not found", lang_id),
        }))).into_response()
    }

    let language_code = get_language_code(&settings, lang_id.clone()).unwrap();

    let filepath = influx_path.join(PathBuf::from(&lang_id)).join(PathBuf::from(&file));
    println!("trying to access {}", &filepath.display());

    let (metadata, text) = read_md_file(filepath).unwrap();

    let parsed_doc: nlp::AnnotatedDocument = nlp::tokenise_pipeline(text.as_str(), language_code.clone()).unwrap();

    let tokens_dict = db.get_dict_from_text_seq(parsed_doc.token_texts.clone(), lang_id.clone()).await.unwrap();
    let potential_phrases: Vec<Phrase> = db.get_phrases_from_text_seq(parsed_doc.token_texts.clone(), lang_id.clone()).await.unwrap();
    let phrase_trie: Trie<String, Phrase> = mk_phrase_trie(potential_phrases);

    let parsed_doc2 = nlp::phrase_fit_pipeline(parsed_doc, phrase_trie);

    (StatusCode::OK, Json(json!({
        "metadata": metadata,
        "text": text,
        "parsed_doc": parsed_doc2,
        "tokens_dict": tokens_dict,
    }))).into_response()
}

// #[derive(Debug, Deserialize)]
// pub struct CreateTokenPayload {
//     pub lang_id: String,

//     pub orthography: String,
//     pub phonetic: String,
//     pub definition: String,
//     pub notes: String,
//     pub original_context: String,
    
//     pub status: TokenStatus,
//     pub tags: Vec<String>, 
// }

#[derive(Debug, Deserialize)]
pub struct DeleteTokenPayload {
    pub id: String,
}

pub async fn create_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token create attempt payload: {:?}", payload);
    
    let token = db.create_token(payload).await?;

   Ok(Json(token))
}

pub async fn delete_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<DeleteTokenPayload>,
) -> Result<Json<Token>, ServerError> {
    println!("token delete attempt payload: {:?}", payload);
    let token = db.delete_token_by_id(payload.id).await?;
    Ok(Json(token))
}

pub async fn lookup_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Path((lang_id, orthography)): Path<(String, String)>
) -> Result<Json<Option<Token>>, ServerError> {
    let token = db.query_token_by_orthography(orthography, lang_id).await?;
    Ok(Json(token))
}

// #[derive(Debug, Deserialize)]
// pub struct UpdateTokenPayload {
//     pub id: String,
//     pub lang_id: String,

//     pub orthography: String,
//     pub phonetic: String,
//     pub definition: String,
//     pub notes: String,
//     pub original_context: String,
    
//     pub status: TokenStatus,
//     pub tags: Vec<String>, 
// }

pub async fn update_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {

    println!("token update attempt payload: {:?}", payload);

    let token = db.update_token_by_id(payload).await?;

   Ok(Json(token))
}

pub async fn get_settings(
    State(ServerState { influx_path, .. }): State<ServerState>, 
) -> impl IntoResponse {
    Json(
        doc_store::read_settings_file(influx_path).unwrap()
    )
}
#![allow(unused_imports)]

use axum::{
    extract::{Path, Query, State},
    response::IntoResponse, http::StatusCode, Json, response::Response
};
use serde::{Deserialize, Serialize};
use crate::ServerState;
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

pub async fn hello_world() -> &'static str {
    "hello world from the influx server :p root route might not be the most useful"
}

pub async fn connection_test() -> impl IntoResponse {
    StatusCode::OK
}

pub async fn todos_index(
    State(ServerState { db, .. }): State<ServerState>, 
) -> impl IntoResponse {
    let todos = db.get_todos_sql().await.unwrap();
    Json(todos)
}

#[derive(Debug, Deserialize)]
pub struct CreateTodo {
    text: String,
}

pub async fn todos_create(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<CreateTodo>,
) -> impl IntoResponse {
    let todo = db.add_todo_sql(payload.text).await.unwrap();

    (StatusCode::CREATED, Json(todo))
}

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

pub async fn get_language_list(
    State(ServerState { influx_path, .. }): State<ServerState>, 
) -> impl IntoResponse {
    let settings = doc_store::read_settings_file(influx_path).unwrap();
    Json(settings.lang)
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

    let (parsed_doc, tokens_strings): (nlp::Document, Vec<String>) = nlp::tokenise_pipeline(text.as_str(), language_code.clone()).unwrap();

    let tokens_dict = db.get_token_set_from_orthography_seq(tokens_strings.clone(), lang_id).await.unwrap();

    (StatusCode::OK, Json(json!({
        "metadata": metadata,
        "text": text,
        "tokens_strs": tokens_strings,
        "tokens_dict": tokens_dict,
        "parsed_doc": parsed_doc,
    }))).into_response()
}

#[derive(Debug, Deserialize)]
pub struct CreateToken {
    pub lang_id: String,

    pub orthography: String,
    pub phonetic: String,
    pub lemma: String,
    
    pub status: crate::db::models::vocab::TokenStatus,
    pub definition: String,
    pub notes: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateToken {
    pub id: String,
    pub lang_id: String,

    pub orthography: String,
    pub phonetic: String,
    pub lemma: String,
    
    pub status: crate::db::models::vocab::TokenStatus,
    pub definition: String,
    pub notes: String,
}
#[derive(Debug, Deserialize)]
pub struct DeleteToken {
    pub id: String,
}

pub async fn create_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<CreateToken>,
) -> impl IntoResponse {

    println!("token create attempt payload: {:?}", payload);

    let token = db.create_token(
        Token {
            id: None,
            lang_id: payload.lang_id.clone(),
            orthography: payload.orthography.clone(),
            phonetic: payload.phonetic.clone(),
            lemma: payload.lemma.clone(),
            status: payload.status.clone(),
            definition: payload.definition.clone(),
            notes: payload.notes.clone(),
        }
    ).await.unwrap();

   Json(json!({
       "success": true,
       "token": token,
   }))
}

pub async fn delete_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<DeleteToken>,
) -> impl IntoResponse {

    println!("token delete attempt payload: {:?}", payload);

    let token = db.delete_token(payload.id).await.unwrap();

   Json(json!({
       "success": true,
       "token": token,
   }))
}

pub async fn lookup_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Path((lang_id, orthography)): Path<(String, String)>
) -> impl IntoResponse {

    let token = db.query_token_by_orthography(orthography, lang_id).await.unwrap();

    Json(json!({
        "success": true,
        "token": token,
    }))
}

pub async fn update_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<UpdateToken>,
) -> impl IntoResponse {

    println!("token update attempt payload: {:?}", payload);

    let token = db.update_token(
        Token {
            // BUG doesn't handle wrong token id but orthography in database
            // anyway now let's just assume whoever calling this not mess up the id
            id: Some(sql::thing(format!("tokens:{}", &payload.id).as_str()).unwrap()),
            lang_id: payload.lang_id.clone(),
            orthography: payload.orthography.clone(),
            phonetic: payload.phonetic.clone(),
            lemma: payload.lemma.clone(),
            status: payload.status.clone(),
            definition: payload.definition.clone(),
            notes: payload.notes.clone(),
        }
    ).await.unwrap();

   Json(json!({
       "success": true,
       "token": token,
   }))
}

pub async fn get_settings(
    State(ServerState { influx_path, .. }): State<ServerState>, 
) -> impl IntoResponse {
    Json(
        doc_store::read_settings_file(influx_path).unwrap()
    )
}
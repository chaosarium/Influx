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
use std::{path::PathBuf, collections::{HashMap, HashSet}};

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

pub mod lang_handlers;

pub async fn get_docs_list(
    State(ServerState { influx_path, db }): State<ServerState>, 
    Path(lang_id): Path<String>
) -> Response {

    // check if lang_id exists, if not return 404
    if !db.language_exists(lang_id.clone()).await.unwrap() {
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

#[deprecated]
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
    if !db.language_exists(lang_id.clone()).await.unwrap() {
        return (StatusCode::NOT_FOUND, Json(json!({
            "error": format!("lang_id {} not found", lang_id),
        }))).into_response()
    }

    let language_code = db.get_code_for_language(lang_id.clone()).await.unwrap().unwrap();

    let filepath = influx_path.join(PathBuf::from(&lang_id)).join(PathBuf::from(&file));
    println!("trying to access {}", &filepath.display());

    let (metadata, text) = read_md_file(filepath).unwrap();

    // tokenization
    let mut annotated_doc1: nlp::AnnotatedDocument = nlp::tokenise_pipeline(text.as_str(), language_code.clone()).await.unwrap();
    let tokens_dict: HashMap<String, Token> = db.get_dict_from_orthography_set(
        annotated_doc1.orthography_set.union(&annotated_doc1.lemma_set).cloned().collect::<HashSet<String>>(),
        lang_id.clone()
    ).await.unwrap();
    annotated_doc1.set_token_dict(tokens_dict);

    // phrase annotation
    let potential_phrases: Vec<Phrase> = db.query_phrase_by_onset_orthographies(annotated_doc1.orthography_set.clone(), lang_id.clone()).await.unwrap();
    let phrase_trie: Trie<String, Phrase> = mk_phrase_trie(potential_phrases);
    let annotated_doc2 = nlp::phrase_fit_pipeline(annotated_doc1, phrase_trie);

    (StatusCode::OK, Json(json!({
        "metadata": metadata,
        "text": text,
        "annotated_doc": annotated_doc2,
    }))).into_response()
}

pub mod vocab_handlers;
pub mod phrase_handlers;

// #[deprecated]
// pub async fn get_settings(
//     State(ServerState { influx_path, .. }): State<ServerState>, 
// ) -> impl IntoResponse {
//     Json(
//         doc_store::read_settings_file(influx_path).unwrap()
//     )
// }
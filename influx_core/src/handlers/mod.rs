#![allow(unused_imports)]
use tracing::info;
use ts_rs::TS;
use axum::{
    extract::{Path, Query, State},
    response::IntoResponse, http::StatusCode, Json, response::Response
};
use serde::{Deserialize, Serialize};
use crate::{db::models::{lang::LanguageEntry, phrase::{mk_phrase_trie, Phrase}, vocab::{self, TokenStatus}}, doc_store::write_md_file, utils::trie::Trie, ServerState};
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
use md5;
use std::fs;
use serde_json;

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
    if !db.language_identifier_exists(lang_id.clone()).await.unwrap() {
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


fn text_checksum(text: String) -> String {
    let digest = md5::compute(text);
    format!("{:x}", digest)
}



// TODO do error handling like above
pub async fn get_doc(
    State(ServerState { db, influx_path }): State<ServerState>, 
    Path((lang_identifier, file)): Path<(String, String)>
) -> impl IntoResponse {
    
    info!("getting doc: lang_identifier = {}, file = {}", lang_identifier, file);

    // check if lang_id exists, if not return 404
    if !db.language_identifier_exists(lang_identifier.clone()).await.unwrap() {
        return (StatusCode::NOT_FOUND, Json(json!({
            "error": format!("lang_id {} not found", lang_identifier),
        }))).into_response()
    }
    
    let lang_entry = db.get_language_by_identifier(lang_identifier.clone()).await.unwrap().unwrap();
    let lang_id = lang_entry.id.clone().unwrap();
    let lang_code = lang_entry.code.clone();

    let filepath = influx_path.join(PathBuf::from(&lang_identifier)).join(PathBuf::from(&file));
    println!("trying to access {}", &filepath.display());

    let (metadata, text) = read_md_file(filepath.clone()).unwrap();
    let text_checksum: String = text_checksum(text.clone());
    
    let nlp_filepath = influx_path.join(PathBuf::from("_influx_nlp_cache")).join(PathBuf::from(format!("{}.nlp", &text_checksum)));
    
    let mut tokenised_doc: nlp::AnnotatedDocument = if nlp_filepath.exists() {
        let nlp_file_content = fs::read_to_string(nlp_filepath).unwrap();
        let it: nlp::AnnotatedDocument = serde_json::from_str(&nlp_file_content).unwrap();
        assert_eq!(it.text, text); // if this fails... md5 checksum collision?
        it
    } else {
        // run tokenisation pipeline and cache it
        let it = nlp::tokenise_pipeline(text.as_str(), lang_code.clone()).await.unwrap();
        let serialized_doc = serde_json::to_string(&it).unwrap();
        if !nlp_filepath.exists() {
            fs::create_dir_all(nlp_filepath.parent().unwrap()).unwrap();
        }
        fs::write(nlp_filepath.clone(), serialized_doc).unwrap();
        info!("wrote nlp cache file to {}", nlp_filepath.display());
        it
    };
    
    let tokens_dict: HashMap<String, Token> = db.get_dict_from_orthography_set(
        lang_id.clone(),
        tokenised_doc.orthography_set.union(&tokenised_doc.lemma_set).cloned().collect::<HashSet<String>>(),
    ).await.unwrap();
    tokenised_doc.set_token_dict(tokens_dict);

    // phrase annotation
    let potential_phrases: Vec<Phrase> = db.query_phrase_by_onset_orthographies(lang_id.clone(), tokenised_doc.orthography_set.clone()).await.unwrap();
    let phrase_trie: Trie<String, Phrase> = mk_phrase_trie(potential_phrases);
    let tokenised_phrased_annotated_doc = nlp::phrase_fit_pipeline(tokenised_doc, phrase_trie);

    (StatusCode::OK, Json(json!({
        "metadata": metadata,
        "text": text,
        "annotated_doc": tokenised_phrased_annotated_doc,
    }))).into_response()
}

pub mod vocab_handlers;
pub mod phrase_handlers;
pub mod integration_handlers;

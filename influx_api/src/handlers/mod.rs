#![allow(unused_imports)]

use axum::{
    extract::{Path, Query, State},
    response::IntoResponse, http::StatusCode, Json,
};
use serde::{Deserialize, Serialize};

use crate::db::{DB, models::vocab::Token};
use crate::doc_store::DocEntry;
use crate::doc_store::{
    gt_md_file_list_w_metadata,
    read_md_file,
};
use crate::prelude::*;
use serde_json::json;
use surrealdb::sql;

pub async fn hello_world() -> &'static str {
    "Hello, World!"
}

pub async fn todos_index(State(db): State<DB>) -> impl IntoResponse {
    let todos = db.get_todos_sql().await.unwrap();
    Json(todos)
}

#[derive(Debug, Deserialize)]
pub struct CreateTodo {
    text: String,
}

pub async fn todos_create(
    State(db): State<DB>,
    Json(payload): Json<CreateTodo>,
) -> impl IntoResponse {
    let todo = db.add_todo_sql(payload.text).await.unwrap();

    (StatusCode::CREATED, Json(todo))
}

pub async fn todos_delete(Path(id): Path<String>, State(db): State<DB>) -> impl IntoResponse {
    // db.delete_todo_sql(
    //     surrealdb::sql::thing(&id).unwrap()
    // ).await.unwrap();
    (StatusCode::NO_CONTENT, Json(()))
}

#[derive(Debug, Deserialize)]
pub struct GetDocsList {
    lang: String,
}

pub async fn get_docs_list(Path(lang): Path<String>) -> impl IntoResponse {
    let list = gt_md_file_list_w_metadata(
        format!("/Users/chaosarium/Documents/Dev/Influx/toy_content/{}", lang).as_str()
    ).unwrap();

    Json(list)
}

pub async fn get_doc(
    State(db): State<DB>, 
    Path((lang, file)): Path<(String, String)>
) -> impl IntoResponse {
    println!("trying to access {}", format!("/Users/chaosarium/Documents/Dev/Influx/toy_content/{}/{}", lang, file).as_str());

    let (metadata, text) = read_md_file(
        format!("/Users/chaosarium/Documents/Dev/Influx/toy_content/{}/{}", lang, file).as_str()
    ).unwrap();

    // TODO figure out how to tokenize
    let tokens_strs: Vec<&str> = text.split_whitespace().collect();
    let tokens_strings: Vec<String> = tokens_strs.iter().clone().map(|s| s.to_string()).collect();
    let tokens_dict = db.get_token_set_from_orthography_seq(tokens_strings, lang).await.unwrap();

    Json(json!({
        "metadata": metadata,
        "text": text,
        "tokens_strs": tokens_strs,
        "tokens_dict": tokens_dict,
    }))  
}

#[derive(Debug, Deserialize)]
pub struct UpdateToken {
    pub id: Option<String>,
    pub language: String,

    pub orthography: String,
    pub phonetic: String,
    pub lemma: String,
    
    pub status: crate::db::models::vocab::TokenStatus,
    pub definition: String,
    pub notes: String,

}

pub async fn update_token(
    State(db): State<DB>, 
    Json(payload): Json<UpdateToken>,
) -> impl IntoResponse {

    println!("token update attempt payload: {:?}", payload);

    let token = match payload.id {
        Some(id) => {
            db.update_token(
                Token {
                    // BUG doesn't handle wrong token id but orthography in database
                    id: Some(sql::thing(format!("tokens:{}", &id).as_str()).unwrap()),
                    language: payload.language.clone(),
                    orthography: payload.orthography.clone(),
                    phonetic: payload.phonetic.clone(),
                    lemma: payload.lemma.clone(),
                    status: payload.status.clone(),
                    definition: payload.definition.clone(),
                    notes: payload.notes.clone(),
                }
            ).await.unwrap()
        },
        None => {
            db.create_token(
                Token {
                    id: None,
                    language: payload.language.clone(),
                    orthography: payload.orthography.clone(),
                    phonetic: payload.phonetic.clone(),
                    lemma: payload.lemma.clone(),
                    status: payload.status.clone(),
                    definition: payload.definition.clone(),
                    notes: payload.notes.clone(),
                }
            ).await.unwrap()
        }
    };

   Json(json!({
       "success": true,
       "token": token,
   }))
}
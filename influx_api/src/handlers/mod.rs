#![allow(unused_imports)]

use axum::{
    extract::{Path, Query, State},
    response::IntoResponse, http::StatusCode, Json,
};
use serde::{Deserialize, Serialize};

use crate::db::DB;
use crate::doc_store::DocEntry;
use crate::doc_store::{
    gt_md_file_list_w_metadata,
    read_md_file,
};
use crate::prelude::*;
use serde_json::json;

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
        format!("/Users/chaosarium/Desktop/influx_content/{}", lang).as_str()
    ).unwrap();

    Json(list)
}

pub async fn get_doc(Path((lang, file)): Path<(String, String)>) -> impl IntoResponse {
    println!("trying to access {}", format!("/Users/chaosarium/Desktop/influx_content/{}/{}", lang, file).as_str());

    let (metadata, text) = read_md_file(
        format!("/Users/chaosarium/Desktop/influx_content/{}/{}", lang, file).as_str()
    ).unwrap();

    // TODO figure out how to tokenize
    let tokens: Vec<&str> = text.split_whitespace().collect();

    Json(json!({
        "metadata": metadata,
        "text": text,
        "tokenized": tokens,
    }))  

}
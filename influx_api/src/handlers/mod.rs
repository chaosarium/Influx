#![allow(unused_imports)]

use axum::{
    extract::{Path, Query, State},
    response::IntoResponse, http::StatusCode, Json,
};
use serde::{Deserialize, Serialize};

use crate::db::DB;

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
    db.delete_todo_sql(
        surrealdb::sql::thing(&id).unwrap()
    ).await.unwrap();
    (StatusCode::NO_CONTENT, Json(()))
}
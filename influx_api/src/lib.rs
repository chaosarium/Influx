#![allow(dead_code, unused_variables, unused_macros)]

use axum::{
    Router,
    routing::{get, delete},
};
use tokio::net::TcpListener;

use db::DB;
mod db;
mod doc_store;
mod utils;
mod handlers;
mod prelude;
mod error;

pub async fn launch(disk: bool, seed: bool) {
    println!("launching with disk: {}, seed: {}", disk, seed);

    let db = DB::create_db(disk).await;

    if seed {
        db.add_todo_sql("todo1".into()).await.unwrap();
        db.add_todo_sql("todo2".into()).await.unwrap();
    }

    let app = Router::new()
        .route("/", get(handlers::hello_world))
        .route("/docs/:lang", get(handlers::get_docs_list))
        .route("/docs/:lang/:file", get(handlers::get_doc))
        .route("/todos", get(handlers::todos_index).post(handlers::todos_create))
        .route("/todos/:id", delete(handlers::todos_delete))
        .with_state(db);

    let listener = TcpListener::bind("127.0.0.1:3000").await.unwrap();
    println!("listener is http://{:?}", listener.local_addr().unwrap());
    axum::serve(listener, app).await.unwrap();
}
#![allow(dead_code, unused_variables, unused_macros, unused_imports)]

use axum::{
    Router,
    routing::{get, delete}, http::Method,
};
use tokio::net::TcpListener;
use tower_http::cors::{Any, CorsLayer};

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
        let _ = db.seed_todo_table().await;
        
    }

    let cors = CorsLayer::new()
        // allow `GET` and `POST` when accessing the resource
        // .allow_methods([Method::GET, Method::POST])
        // allow requests from any origin
        .allow_origin(Any);

    let app = Router::new()
        .route("/", get(handlers::hello_world))
        .route("/docs/:lang", get(handlers::get_docs_list))
        .route("/docs/:lang/:file", get(handlers::get_doc))
        .route("/todos", get(handlers::todos_index).post(handlers::todos_create))
        .route("/todos/:id", delete(handlers::todos_delete))
        .layer(cors)
        .with_state(db);

    let listener = TcpListener::bind("127.0.0.1:3000").await.unwrap();
    println!("listener is http://{:?}", listener.local_addr().unwrap());
    axum::serve(listener, app).await.unwrap();
}
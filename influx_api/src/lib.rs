#![allow(dead_code, unused_variables, unused_macros, unused_imports)]

use axum::{
    Router,
    routing::{get, post, delete}, http::Method,
};
use tokio::net::TcpListener;
use tower_http::cors::{Any, CorsLayer};
use std::path::{Path, PathBuf};

mod db;
mod doc_store;
mod utils;
mod handlers;
mod prelude;
mod error;
mod nlp;

use db::DB;
use std::env;

#[derive(Clone)] // TODO later use this as state rather than db itself
pub struct ServerState {
    db: DB,
    influx_path: PathBuf,
}

pub async fn launch(disk: bool, seed: bool, influx_path: PathBuf) {
    println!("launching with disk: {}, seed: {}", disk, seed);

    let db = DB::create_db(disk).await;

    if seed {
        let _ = db.seed_todo_table().await;
        let _ = db.seed_vocab_table().await;
    }

    let cors = CorsLayer::permissive();

    // a stricter version that broke something i don't remember
    // let cors = CorsLayer::new()
        // allow `GET` and `POST` when accessing the resource
        // .allow_methods(Any)
        // allow requests from any origin
        // .allow_origin(Any);

    let app = Router::new()
        .route(
            "/", 
            get(handlers::hello_world)
        )
        .route(
            "/test", 
            get(handlers::connection_test)
        )
        // toy examples below
        .route(
            "/todos", 
            get(handlers::todos_index)
            .post(handlers::todos_create)
        )
        .route(
            "/todos/:id", 
            delete(handlers::todos_delete)
        )
        .route(
            "/docs/:language_identifier", 
            get(handlers::get_docs_list)
        )
        .route(
            "/docs/:language_identifier/:file", 
            get(handlers::get_doc)
        )
        .route(
            "/vocab/token", 
            post(handlers::update_token)
        )
        .route(
            "/settings",
            get(handlers::get_settings)
        )
        .route(
            "/settings/lang",
            get(handlers::get_language_list)
        )
        .layer(cors)
        .with_state(
            ServerState {
                db,
                influx_path,
            }
        );

    let listener = TcpListener::bind("127.0.0.1:3000").await.unwrap();
    println!("Starting Influx server at http://{:?}", listener.local_addr().unwrap());
    axum::serve(listener, app).await.unwrap();
}
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
mod integration;

use db::DB;
use db::DBLocation;
use std::env;

#[derive(Clone)] // TODO later use this as state rather than db itself
pub struct ServerState {
    db: DB,
    influx_path: PathBuf,
}

pub async fn launch(disk: bool, seed: bool, influx_path: PathBuf) {
    println!("launching with disk: {}, seed: {}", disk, seed);

    let db = DB::create_db({
        match disk {
            true => DBLocation::Disk(influx_path.canonicalize().unwrap().join("database.db")),
            false => DBLocation::Mem,
        }
    }).await;

    // println!("initializing python");
    // let _ = nlp::run_some_python().unwrap();

    if seed {
        let _ = db.seed_all_tables().await;
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
        // .route(
        //     "/todos",
        //     get(handlers::todos_index)
        //     .post(handlers::todos_create)
        // )
        // .route(
        //     "/todos/:id",
        //     delete(handlers::todos_delete)
        // )
        .route(
            "/docs/:language_identifier",
            get(handlers::get_docs_list)
        )
        .route(
            "/docs/:language_identifier/:file",
            get(handlers::get_doc)
        )
        .route(
            "/vocab/token/:language_identifier/:orthography",
            get(handlers::vocab_handlers::lookup_token)
        )
        .route(
            "/vocab/delete_token",
            delete(handlers::vocab_handlers::delete_token)
        )
        .route(
            "/vocab/update_token",
            post(handlers::vocab_handlers::update_token)
        )
        .route(
            "/vocab/create_token",
            post(handlers::vocab_handlers::create_token)
        )
        .route(
            "/phrase/update_phrase",
            post(handlers::phrase_handlers::update_phrase)
        )
        .route(
            "/phrase/delete_phrase",
            delete(handlers::phrase_handlers::delete_phrase)
        )
        // .route(
        //     "/settings",
        //     get(handlers::get_settings)
        // )
        .route(
            "/lang",
            get(handlers::lang_handlers::get_language_list)
        )
        .route(
            "/lang/:id",
            get(handlers::lang_handlers::get_language_by_id)
        )
        .route(
            "/extern/macos_dict/:language_identifier/:orthography",
            get(handlers::integration_handlers::lookup_in_macos_dict)
        )
        .route(
            "/extern/translate",
            post(handlers::integration_handlers::extern_translate)
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

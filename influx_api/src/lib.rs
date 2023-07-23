#![allow(dead_code, unused_variables, unused_macros)]

use axum::{
    Router,
    routing::{get, delete},
};
use std::net::SocketAddr;

use db::DB;
mod db;
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
        .route("/todos", get(handlers::todos_index).post(handlers::todos_create))
        .route("/todos/:id", delete(handlers::todos_delete))
        .with_state(db);

    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    println!("listening on http://{}", addr);
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}
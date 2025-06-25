#![allow(warnings)]

use axum::{
    Router,
    routing::{get, post, delete}, http::Method,
};
use clap::{Parser, ValueEnum};
use tokio::net::TcpListener;
use tower_http::cors::{Any, CorsLayer};
use std::path::{Path, PathBuf};
use log::{info, trace, warn};
use std::fs::write;

pub mod db;
pub(crate) mod doc_store;
mod utils;
mod handlers;
mod prelude;
mod nlp;
mod integration;

use db::DB;
use db::DBLocation;
use std::env;

#[derive(Debug, ValueEnum, Clone, Copy)]
pub enum DBChoice {
    SurrealMemory,
    SurrealDisk,
    SurrealServer,
    PostgresServer,
    // IDEA might be able to embed DuckDB
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
pub struct InfluxCoreArgs {
    /// what database backend to use
    #[arg(short, long, default_value = "surreal-server")]
    pub db_choice: DBChoice,
    
    /// Whether to seed database
    #[arg(short, long, default_value_t = false)]
    pub seed: bool,

    /// path to content directory
    #[arg(short, long, default_value = "../toy_content")]
    pub influx_path: String,
}

#[derive(Clone)]
pub struct ServerState {
    db: DB,
    influx_path: PathBuf,
}

pub async fn launch(args: InfluxCoreArgs) -> anyhow::Result<()> {
    info!("Whether to seed: {}", args.seed);

    let db = DB::create_db(args.db_choice).await?;

    if args.seed {
        let _ = db.seed_all_tables().await;
    }

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
            "/docs/{language_identifier}",
            get(handlers::get_docs_list)
        )
        .route(
            "/docs/{language_identifier}/{file}",
            get(handlers::get_doc)
        )
        .route(
            "/vocab/token/{language_identifier}/{orthography}",
            get(handlers::vocab_handlers::lookup_token)
        )
        .route(
            "/vocab/delete_token",
            post(handlers::vocab_handlers::delete_token)
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
            post(handlers::phrase_handlers::delete_phrase)
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
            "/lang/{id}",
            get(handlers::lang_handlers::get_language_by_identifier)
        )
        .route(
            "/extern/macos_dict/{language_identifier}/{orthography}",
            get(handlers::integration_handlers::lookup_in_macos_dict)
        )
        .route(
            "/extern/translate",
            post(handlers::integration_handlers::extern_translate)
        )
        .layer(CorsLayer::permissive())
        .with_state(
            ServerState {
                db,
                influx_path: args.influx_path.into(),
            }
        );

    let listener = TcpListener::bind("127.0.0.1:3000").await?;
    info!("Starting Influx server at http://{:?}", listener.local_addr()?);
    axum::serve(listener, app).await?;
    Ok(())
}


#[cfg(test)]
mod tests {
    use crate::db::models;

    use super::*;

    #[test]
    fn generate_elm_bindings() {
        use crate::db::models::lang;
        use crate::doc_store;
        
        let mut out_buf = vec![];
        elm_rs::export!("Bindings", &mut out_buf, {
            encoders: [
                db::InfluxResourceId,
                lang::LanguageEntry, 
                doc_store::DocType,
                doc_store::DocMetadata,
                doc_store::DocEntry,
                db::models::vocab::Token,
                db::models::vocab::TokenStatus,
                db::models::phrase::Phrase,
                nlp::DocumentConstituent,
                nlp::SentenceConstituent,
                handlers::GetDocResponse,
                nlp::AnnotatedDocument,
            ],
            decoders: [
                db::InfluxResourceId,
                lang::LanguageEntry, 
                doc_store::DocType,
                doc_store::DocMetadata,
                doc_store::DocEntry,
                db::models::vocab::Token,
                db::models::vocab::TokenStatus,
                db::models::phrase::Phrase,
                nlp::DocumentConstituent,
                nlp::SentenceConstituent,
                handlers::GetDocResponse,
                nlp::AnnotatedDocument,
            ],
            queries: [],
            query_fields: [],
        })
        .unwrap();
        let out_str = String::from_utf8(out_buf).unwrap();

        let out_path = "../influx_client/src/Bindings.elm";
        write(out_path, out_str).expect("Unable to write file");
    }
}

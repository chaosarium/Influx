#![allow(unused_variables, dead_code)]
use axum::{
    routing::{get, post},
    Router,
};
use clap::{Parser, ValueEnum};
use tokio::net::TcpListener;
use tower_http::cors::CorsLayer;
use tracing::info;

pub mod db;
pub mod embedded_db;
pub mod fsrs_scheduler;
mod handlers;
pub mod integration;
mod nlp;
mod prelude;
mod utils;

pub mod test_utils;

use db::DB;
use integration::stardict::StardictManager;
use std::sync::Arc;
use tokio::sync::Mutex;

#[macro_use]
extern crate macro_rules_attribute;

#[derive(Debug, ValueEnum, Clone, Copy)]
pub enum DBChoice {
    // SurrealMemory,
    // SurrealDisk,
    // SurrealServer,
    PostgresServer,
    PostgresEmbedded,
    // IDEA: might be able to embed DuckDB
}

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
pub struct InfluxCoreArgs {
    /// what database backend to use
    #[arg(short, long, default_value = "postgres-embedded")]
    pub db_choice: DBChoice,

    /// Whether to seed database
    #[arg(short, long, default_value_t = false)]
    pub seed: bool,

    /// Port to bind the server to
    #[arg(short, long, default_value_t = 3000)]
    pub port: u16,

    /// URL of the NLP service
    #[arg(short, long, default_value = "http://127.0.0.1:3001")]
    pub nlp_url: String,
}

#[derive(Clone)]
pub struct ServerState {
    pub db: DB,
    pub nlp_url: String,
    pub stardict_manager: Arc<Mutex<StardictManager>>,
}

pub fn create_app_router(state: ServerState) -> Router {
    Router::new()
        .route("/connection_test", get(handlers::connection_test))
        .route("/docs", post(handlers::doc_handlers::get_docs_list))
        .route("/doc/{id}", get(handlers::doc_handlers::get_doc))
        .route("/doc/edit", post(handlers::doc_handlers::update_document))
        .route("/term/edit", post(handlers::term_handlers::edit_term))
        .route("/lang", get(handlers::lang_handlers::get_language_list))
        .route(
            "/lang/{lang_id}",
            get(handlers::lang_handlers::get_language_by_id),
        )
        .route("/lang/edit", post(handlers::lang_handlers::update_language))
        .route(
            "/extern/macos_dict/{language_identifier}/{orthography}",
            get(handlers::integration_handlers::lookup_in_macos_dict),
        )
        .route(
            "/extern/translate",
            post(handlers::integration_handlers::extern_translate),
        )
        .route(
            "/dictionary/lookup",
            get(handlers::integration_handlers::stardict_lookup),
        )
        .layer(CorsLayer::permissive())
        .with_state(state)
}

pub async fn launch(args: InfluxCoreArgs) -> anyhow::Result<()> {
    info!("Whether to seed: {}", args.seed);

    let db = DB::create_db(args.db_choice).await?;

    if args.seed {
        let _ = db.seed_all_tables().await;
    }

    let app = create_app_router(ServerState {
        db,
        nlp_url: args.nlp_url.clone(),
        stardict_manager: Arc::new(Mutex::new(StardictManager::new())),
    });

    let bind_addr = format!("127.0.0.1:{}", args.port);
    let listener = TcpListener::bind(&bind_addr).await?;
    info!(
        "Starting Influx server at http://{:?}",
        listener.local_addr()?
    );
    axum::serve(listener, app).await?;
    Ok(())
}

#[cfg(test)]
mod tests {

    use super::*;
    use anyhow::Context;
    use std::fs;

    #[test]
    fn generate_elm_bindings() -> anyhow::Result<()> {
        use crate::db::models::lang;
        use crate::fsrs_scheduler;

        let mut out_buf = vec![];
        elm_rs::export!("Bindings", &mut out_buf, {
            encoders: [
                db::InfluxResourceId,
                lang::Language,
                lang::ParserConfig,
                db::models::document::Document,
                db::models::document::DocPackage,
                db::models::vocab::Token,
                db::models::vocab::TokenStatus,
                db::models::phrase::Phrase,
                db::models::fsrs::CardType,
                db::models::fsrs::CardState,
                db::models::fsrs::FSRSLanguageConfig,
                db::models::fsrs::Card,
                db::models::fsrs::ReviewLog,
                fsrs_scheduler::SerializableMemoryState,
                handlers::Term,
                handlers::TermEditAction,
                handlers::GetDocResponse,
                handlers::TermEditRequest,
                handlers::TermEditResponse,
                handlers::GetDocsRequest,
                handlers::ReviewableCardId,
                handlers::CardWithTerm,
                handlers::GetNextDueCardRequest,
                handlers::GetNextDueCardResponse,
                handlers::SubmitReviewRequest,
                handlers::SubmitReviewResponse,
                handlers::UpdateFSRSConfigRequest,
                handlers::UpdateFSRSConfigResponse,
                handlers::SetCardStateRequest,
                handlers::SetCardStateResponse,
                handlers::integration_handlers::WordDefinition,
                handlers::integration_handlers::WordDefinitionSegment,
                nlp::TermDictionary,
                nlp::AnnotatedDocV2,
                nlp::DocSegV2,
                nlp::DocSegVariants,
                nlp::SentSegV2,
                nlp::SentSegVariants,
                nlp::SegAttribute,
                nlp::ConjugationStep,
            ],
            decoders: [
                db::InfluxResourceId,
                lang::Language,
                lang::ParserConfig,
                db::models::document::Document,
                db::models::document::DocPackage,
                db::models::vocab::Token,
                db::models::vocab::TokenStatus,
                db::models::phrase::Phrase,
                db::models::fsrs::CardType,
                db::models::fsrs::CardState,
                db::models::fsrs::FSRSLanguageConfig,
                db::models::fsrs::Card,
                db::models::fsrs::ReviewLog,
                fsrs_scheduler::SerializableMemoryState,
                handlers::Term,
                handlers::TermEditAction,
                handlers::GetDocResponse,
                handlers::TermEditRequest,
                handlers::TermEditResponse,
                handlers::GetDocsRequest,
                handlers::ReviewableCardId,
                handlers::CardWithTerm,
                handlers::GetNextDueCardRequest,
                handlers::GetNextDueCardResponse,
                handlers::SubmitReviewRequest,
                handlers::SubmitReviewResponse,
                handlers::UpdateFSRSConfigRequest,
                handlers::UpdateFSRSConfigResponse,
                handlers::SetCardStateRequest,
                handlers::SetCardStateResponse,
                handlers::integration_handlers::WordDefinition,
                handlers::integration_handlers::WordDefinitionSegment,
                nlp::TermDictionary,
                nlp::AnnotatedDocV2,
                nlp::DocSegV2,
                nlp::DocSegVariants,
                nlp::SentSegV2,
                nlp::SentSegVariants,
                nlp::SegAttribute,
                nlp::ConjugationStep,
            ],
            queries: [],
            query_fields: [],
        })
        .context("Failed to generate Elm bindings")?;
        let out_str =
            String::from_utf8(out_buf).context("Failed to convert Elm bindings to UTF-8")?;

        let out_path = "../influx_client/src/Bindings.elm";
        fs::write(out_path, out_str).context("Failed to write Elm bindings file")?;
        Ok(())
    }
}

use super::api_interfaces::*;
use super::ServerError;
use crate::db::models::document::{DocPackage, Document};
use crate::db::models::phrase::mk_phrase_trie;
use crate::db::models::phrase::Phrase;
use crate::db::models::vocab::Token;
use crate::db::InfluxResourceId;
use crate::nlp;
use crate::ServerState;
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    response::Response,
    Json,
};
use md5;
use serde_json::json;
use std::collections::{BTreeMap, BTreeSet};
use tracing::{debug, info};

const USE_CACHE: bool = false;

pub async fn get_docs_list(
    State(ServerState { db }): State<ServerState>,
    Json(request): Json<GetDocsRequest>,
) -> Response {
    match db.get_documents(request.language_id).await {
        Ok(doc_packages) => (StatusCode::OK, Json(doc_packages)).into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "error": format!("Failed to retrieve documents: {}", e),
            })),
        )
            .into_response(),
    }
}

fn text_checksum(text: String) -> String {
    let digest = md5::compute(text);
    format!("{:x}", digest)
}

async fn load_cached_nlp_data(
    db: &crate::db::DB,
    document_id: InfluxResourceId,
    text_checksum: &str,
    parser_config: &crate::db::models::lang::ParserConfig,
) -> Result<Option<nlp::AnnotatedDocV2>, anyhow::Error> {
    if let Some(cached_json) = db
        .get_annotated_document_cache(document_id.clone(), text_checksum)
        .await?
    {
        let cached_doc: nlp::AnnotatedDocV2 = serde_json::from_value(cached_json)?;

        // Check if parser config matches - invalidate cache if different
        if &(cached_doc.parser_config) != parser_config {
            info!(
                "Parser config mismatch for document_id: {:?}, invalidating cache. Cached: {:?}, Current: {:?}",
                document_id, cached_doc.parser_config, parser_config
            );
            return Ok(None);
        }

        Ok(Some(cached_doc))
    } else {
        Ok(None)
    }
}

pub(crate) async fn get_annotated_doc_logic(
    state: &ServerState,
    document_id: InfluxResourceId,
) -> Result<GetDocResponse, ServerError> {
    info!("getting doc: document_id = {:?}", document_id);

    // Get document from database
    let document = state
        .db
        .get_document_by_id(document_id.clone())
        .await?
        .ok_or_else(|| ServerError(anyhow::anyhow!("Document not found")))?;

    // Get language from the document
    let lang_entry = state
        .db
        .get_language(document.lang_id.clone())
        .await?
        .ok_or_else(|| ServerError(anyhow::anyhow!("Language not found for document")))?;
    let lang_id = lang_entry
        .id
        .clone()
        .ok_or_else(|| ServerError(anyhow::anyhow!("Language entry missing ID")))?;

    // Derive language code from name for tokenisation pipeline
    let lang_code = match lang_entry.name.as_str() {
        "French" => "fr",
        "English" => "en",
        "Japanese" => "ja",
        "Mandarin" => "zh-hant",
        _ => "en", // fallback to English
    }
    .to_string();

    let text = document.content.clone();

    // Create DocPackage
    let doc_package = DocPackage {
        document_id: document_id.clone(),
        language_id: lang_id.clone(),
        document: document.clone(),
        language: lang_entry.clone(),
    };

    let text_checksum: String = text_checksum(text.clone());

    let tokenised_doc: nlp::AnnotatedDocV2 = match load_cached_nlp_data(
        &state.db,
        document_id.clone(),
        &text_checksum,
        &lang_entry.parser_config,
    )
    .await
    {
        Ok(Some(cached_doc)) if USE_CACHE => {
            info!(
                "Using cached NLP data for document_id: {:?}, checksum: {}",
                document_id, text_checksum
            );
            cached_doc
        }
        _ => {
            // run tokenisation pipeline and cache it
            let it = nlp::tokenise_pipeline(
                text.as_str(),
                lang_code.clone(),
                lang_entry.parser_config.clone(),
            )
            .await?;
            let serialized_json = serde_json::to_value(&it)?;
            state
                .db
                .set_annotated_document_cache(document_id.clone(), &text_checksum, &serialized_json)
                .await?;
            info!(
                "Cached NLP data in database for document_id: {:?}, checksum: {}",
                document_id, text_checksum
            );
            it
        }
    };

    let tokens_dict: BTreeMap<String, Token> = state
        .db
        .get_dict_from_orthography_set(
            lang_id.clone(),
            tokenised_doc
                .orthography_set
                .union(&tokenised_doc.lemma_set)
                .cloned()
                .collect::<BTreeSet<String>>(),
        )
        .await?
        .into_iter()
        .collect();

    let potential_phrases: Vec<Phrase> = state
        .db
        .query_phrase_by_onset_orthographies(lang_id.clone(), tokenised_doc.orthography_set.clone())
        .await?;
    let phrase_dict: BTreeMap<String, Phrase> = potential_phrases
        .iter()
        .map(|phrase| {
            let key = phrase.orthography_seq.join(" ");
            (key, phrase.clone())
        })
        .collect();
    let phrase_trie = mk_phrase_trie(potential_phrases);
    let annotated_doc = nlp::phrase_fit_pipeline(tokenised_doc, phrase_trie);

    let result = GetDocResponse {
        doc_package,
        annotated_doc,
        term_dict: nlp::TermDictionary {
            token_dict: tokens_dict,
            phrase_dict,
        },
    };
    Ok(result)
}

pub async fn get_doc(
    State(state): State<ServerState>,
    Path(id): Path<String>,
) -> Result<Json<GetDocResponse>, ServerError> {
    let document_id = InfluxResourceId::SerialId(
        id.parse::<i64>()
            .map_err(|_| ServerError(anyhow::anyhow!("Invalid document ID: {}", id)))?,
    );
    let response = get_annotated_doc_logic(&state, document_id).await?;
    Ok(Json(response))
}

pub async fn update_document(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Document>,
) -> Result<Json<Document>, ServerError> {
    debug!(document_id = ?payload.id, title = %payload.title, "Updating document");
    Ok(Json(db.update_document(payload).await?))
}

use super::api_interfaces::*;
use super::ServerError;
use crate::db::models::document::DocPackage;
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
use std::fs;
use std::path::PathBuf;
use tracing::info;

const USE_CACHE: bool = true;

pub async fn get_docs_list(
    State(ServerState { influx_path: _, db }): State<ServerState>,
    Json(request): Json<GetDocsRequest>,
) -> Response {
    match request.language_id {
        None => match db.get_all_documents().await {
            Ok(doc_packages) => (StatusCode::OK, Json(doc_packages)).into_response(),
            Err(e) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({
                    "error": format!("Failed to retrieve all documents: {}", e),
                })),
            )
                .into_response(),
        },
        Some(lang_id) => {
            // Return documents for specific language
            panic!("not yet implemented")
        }
    }
}

fn text_checksum(text: String) -> String {
    let digest = md5::compute(text);
    format!("{:x}", digest)
}

fn load_cached_nlp_data(
    nlp_filepath: &PathBuf,
    text: &str,
) -> Result<nlp::AnnotatedDocV2, anyhow::Error> {
    if nlp_filepath.exists() {
        let nlp_file_content = fs::read_to_string(nlp_filepath)?;
        let cached_doc: nlp::AnnotatedDocV2 = serde_json::from_str(&nlp_file_content)?;
        if cached_doc.text == text {
            Ok(cached_doc)
        } else {
            Err(anyhow::anyhow!(
                "Cached NLP data does not match the provided text"
            ))
        }
    } else {
        Err(anyhow::anyhow!(
            "NLP cache file does not exist at path: {}",
            nlp_filepath.display()
        ))
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
    let lang_id = lang_entry.id.clone().unwrap();
    let lang_code = lang_entry.code.clone();

    let text = document.content.clone();

    // Create DocPackage
    let doc_package = DocPackage {
        document_id: document_id.clone(),
        language_id: lang_id.clone(),
        document: document.clone(),
        language: lang_entry.clone(),
    };

    let text_checksum: String = text_checksum(text.clone());

    let nlp_filepath = state
        .influx_path
        .join(PathBuf::from("_influx_nlp_cache"))
        .join(PathBuf::from(format!("{}.nlp", &text_checksum)));

    let tokenised_doc: nlp::AnnotatedDocV2 = match load_cached_nlp_data(&nlp_filepath, &text) {
        Ok(cached_doc) if USE_CACHE => cached_doc,
        _ => {
            // run tokenisation pipeline and cache it
            let it = nlp::tokenise_pipeline(text.as_str(), lang_code.clone()).await?;
            let serialized_doc = serde_json::to_string(&it)?;
            if !nlp_filepath.exists() {
                fs::create_dir_all(nlp_filepath.parent().unwrap())?;
            }
            fs::write(nlp_filepath.clone(), serialized_doc)?;
            info!("wrote nlp cache file to {}", nlp_filepath.display());
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

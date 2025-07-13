use super::ServerError;
use crate::db::models::phrase::{mk_phrase_trie, Phrase};
use crate::db::models::vocab::Token;
use crate::doc_store::read_md_file;
use crate::handlers::api_interfaces::*;
use crate::nlp::{self, phrase_fit_pipeline};
use crate::ServerState;
use axum::extract::State;
use axum::Json;
use md5;
use std::collections::BTreeSet;
use std::fs;
use std::path::PathBuf;
use tracing::info;

pub async fn create_token(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token create attempt payload: {:?}", payload);
    Ok(Json(db.create_token(payload).await?))
}

async fn create_phrase(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Phrase>,
) -> Result<Json<Phrase>, ServerError> {
    println!("phrase create attempt payload: {:?}", payload);
    Ok(Json(db.create_phrase(payload).await?))
}

pub async fn update_token(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token update attempt payload: {:?}", payload);
    Ok(Json(db.update_token(payload).await?))
}

pub async fn update_phrase(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Phrase>,
) -> Result<Json<Phrase>, ServerError> {
    println!("phrase update attempt payload: {:?}", payload);
    Ok(Json(db.update_phrase(payload).await?))
}

pub async fn delete_token(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token delete attempt payload: {:?}", payload);
    Ok(Json(db.delete_token_and_return_unmarked(payload).await?))
}

pub async fn delete_phrase(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Phrase>,
) -> Result<Json<Phrase>, ServerError> {
    println!("phrase delete attempt payload: {:?}", payload);
    Ok(Json(db.delete_phrase_and_return_deleted(payload).await?))
}


const USE_CACHE: bool = true;

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

// TODO this is mostly a copy of get_doc, but without the final phrase fitting
// and without populating the token dict.
async fn get_annotated_doc_for_term_edit(
    db: &crate::db::DB,
    influx_path: &PathBuf,
    doc_path: DocPath,
) -> Result<nlp::AnnotatedDocV2, ServerError> {
    let lang_identifier = doc_path.lang;
    let file = doc_path.file;

    info!(
        "getting doc for term edit: lang_identifier = {}, file = {}",
        lang_identifier, file
    );

    if !db
        .language_identifier_exists(lang_identifier.clone())
        .await
        .unwrap()
    {
        return Err(ServerError(anyhow::anyhow!(
            "lang_id {} not found",
            lang_identifier
        )));
    }

    let lang_entry = db
        .get_language_by_identifier(lang_identifier.clone())
        .await?
        .ok_or_else(|| ServerError(anyhow::anyhow!("Language not found")))?;
    let lang_code = lang_entry.code.clone();

    let filepath = influx_path
        .join(PathBuf::from(&lang_identifier))
        .join(PathBuf::from(&file));
    println!("trying to access {}", &filepath.display());

    let (_metadata, text) = read_md_file(filepath.clone())?;
    let text_checksum: String = text_checksum(text.clone());

    let nlp_filepath = influx_path
        .join(PathBuf::from("_influx_nlp_cache"))
        .join(PathBuf::from(format!("{}.nlp", &text_checksum)));

    let mut tokenised_doc: nlp::AnnotatedDocV2 = match load_cached_nlp_data(&nlp_filepath, &text) {
        Ok(cached_doc) if USE_CACHE => cached_doc,
        _ => {
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

    tokenised_doc.token_dict = None;
    tokenised_doc.phrase_dict = None;

    Ok(tokenised_doc)
}


pub async fn edit_term(
    State(ServerState { db, .. }): State<ServerState>,
    Json(request): Json<TermEditRequest>,
) -> Result<Json<TermEditResponse>, ServerError> {
    println!("term edit attempt request: {:?}", request);
    use Term::*;
    use TermEditAction::*;
    let term_becomes = match (&request.requested_action, request.term) {
        (CreateTerm, TokenTerm(token)) => TokenTerm(db.create_token(token).await?),
        (CreateTerm, PhraseTerm(phrase)) => PhraseTerm(db.create_phrase(phrase).await?),
        (UpdateTerm, TokenTerm(token)) => TokenTerm(db.update_token(token).await?),
        (UpdateTerm, PhraseTerm(phrase)) => PhraseTerm(db.update_phrase(phrase).await?),
        (DeleteTerm, TokenTerm(token)) => {
            TokenTerm(db.delete_token_and_return_unmarked(token).await?)
        }
        (DeleteTerm, PhraseTerm(phrase)) => {
            PhraseTerm(db.delete_phrase_and_return_unmarked(phrase).await?)
        }
    };

    let updated_annotated_doc = if let Some(doc_path) = request.doc_path {
        let lang_identifier = doc_path.lang.clone();
        let lang_entry = db
            .get_language_by_identifier(lang_identifier.clone())
            .await?
            .ok_or_else(|| ServerError(anyhow::anyhow!("Language not found")))?;
        let lang_id = lang_entry.id.clone().unwrap();

        let tokenised_doc = get_annotated_doc_for_term_edit(db, &state.influx_path, doc_path).await?;

        let potential_phrases: Vec<Phrase> = db
            .query_phrase_by_onset_orthographies(
                lang_id.clone(),
                tokenised_doc.orthography_set.clone(),
            )
            .await?;
        let phrase_trie = mk_phrase_trie(potential_phrases);
        let tokenised_phrased_annotated_doc = phrase_fit_pipeline(tokenised_doc, phrase_trie);

        Some(tokenised_phrased_annotated_doc)
    } else {
        None
    };

    Ok(Json(TermEditResponse {
        term: term_becomes,
        performed_action: request.requested_action,
        updated_annotated_doc,
    }))
}
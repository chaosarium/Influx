use super::ServerError;
use crate::integration;
use crate::integration::ExternalDict;
use crate::integration::ExternalTranslator;
use crate::prelude::*;
use crate::ServerState;
use axum::extract::Path;
use axum::extract::Query;
use axum::extract::State;
use axum::Json;
use serde::Deserialize;
use tracing::debug;

pub async fn lookup_in_macos_dict(
    State(ServerState { db, .. }): State<ServerState>,
    Path((lang_id, orthography)): Path<(String, String)>,
) -> Result<(), ServerError> {
    let dict = integration::MacOSDict;
    debug!(orthography = %orthography, language = %lang_id, "Looking up word in macOS dictionary");
    dict.open_dictionary(orthography).await;
    Ok(())
}

#[derive(Deserialize)]
pub struct ExternTranslatePayload {
    pub from_lang_id: String,
    pub to_lang_id: String,
    pub source_sequence: String,
    pub provider: String,
}

#[derive(serde::Serialize)]
pub struct ExternTranslateResponse {
    pub translated_text: String,
}

pub async fn extern_translate(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<ExternTranslatePayload>,
) -> Result<Json<ExternTranslateResponse>, ServerError> {
    let translator: Box<dyn ExternalTranslator + Send + Sync> = match payload.provider.as_str() {
        "google" => Box::new(integration::GoogleTranslate),
        "deepl" => Box::new(integration::DeeplTranslate),
        _ => {
            return Err(ServerError(anyhow::anyhow!(
                "unsupported provider: {}",
                payload.provider
            )))
        }
    };
    let translated_text = translator
        .translate_sequence(
            payload.source_sequence,
            payload.from_lang_id,
            payload.to_lang_id,
        )
        .await?;

    let response = ExternTranslateResponse {
        translated_text: translated_text,
    };

    return Ok(Json(response));
}

#[derive(Deserialize)]
pub struct StardictLookupQuery {
    pub dict_path: String,
    pub query: String,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, Eq, ElmDerives!)]
pub enum StardictType {
    Html,
    Other(String),
}

impl From<String> for StardictType {
    fn from(type_str: String) -> Self {
        match type_str.as_str() {
            "h" => StardictType::Html,
            _ => StardictType::Other(type_str),
        }
    }
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, Eq, ElmDerives!)]
pub struct WordDefinitionSegment {
    pub types: StardictType,
    pub text: String,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, Eq, ElmDerives!)]
pub struct WordDefinition {
    pub word: String,
    pub segments: Vec<WordDefinitionSegment>,
}

impl From<stardict::WordDefinition> for WordDefinition {
    fn from(def: stardict::WordDefinition) -> Self {
        Self {
            word: def.word,
            segments: def
                .segments
                .into_iter()
                .map(|seg| WordDefinitionSegment {
                    types: seg.types.into(),
                    text: seg.text,
                })
                .collect(),
        }
    }
}

pub async fn stardict_lookup(
    State(state): State<ServerState>,
    Query(query): Query<StardictLookupQuery>,
) -> Result<Json<Vec<WordDefinition>>, ServerError> {
    debug!(dict_path = %query.dict_path, query = %query.query, "Looking up word in stardict");

    // TODO maybe can do rwlock instead, but mutex should be fine for now
    let mut stardict_manager = state.stardict_manager.lock().await;
    let result = stardict_manager.lookup_word(query.dict_path, &query.query)?;

    match result {
        Some(definitions) => Ok(Json(
            definitions.into_iter().map(|def| def.into()).collect(),
        )),
        None => Ok(Json(vec![])),
    }
}

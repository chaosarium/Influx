use super::ServerError;
use crate::data_dir;
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
pub struct DictionaryInfo {
    pub name: String,           // Human-readable name (e.g., "French - English")
    pub directory_name: String, // Directory name for resources (e.g., "French - English")
    pub base_url: String,       // Complete base URL for resources
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
    pub dictionary_info: DictionaryInfo,
}

impl WordDefinition {
    fn from_stardict_with_metadata(def: stardict::WordDefinition, dict_path: &str) -> Self {
        // Extract directory name from dict_path
        // dict_path format: "French - English/French - English.ifo"
        let directory_name = dict_path.split('/').next().unwrap_or("unknown").to_string();

        // Create base URL for resources
        // Use the directory name directly since it should be safe for URLs
        let base_url = format!(
            "http://127.0.0.1:3000/influx_app_data/dictionaries/stardicts/{}/res",
            directory_name.replace(" ", "%20") // Simple space encoding
        );

        let dictionary_info = DictionaryInfo {
            name: directory_name.clone(),
            directory_name: directory_name.clone(),
            base_url,
        };

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
            dictionary_info,
        }
    }
}

pub async fn stardict_lookup(
    State(state): State<ServerState>,
    Query(query): Query<StardictLookupQuery>,
) -> Result<Json<Vec<WordDefinition>>, ServerError> {
    debug!(dict_path = %query.dict_path, query = %query.query, "Looking up word in stardict");

    // Resolve relative path to absolute path
    let absolute_path = data_dir::resolve_dict_path(&query.dict_path)
        .map_err(|e| ServerError(e))?
        .to_string_lossy()
        .to_string();

    // TODO maybe can do rwlock instead, but mutex should be fine for now
    let mut stardict_manager = state.stardict_manager.lock().await;
    let result = stardict_manager.lookup_word(absolute_path, &query.query)?;

    match result {
        Some(definitions) => Ok(Json(
            definitions
                .into_iter()
                .map(|def| WordDefinition::from_stardict_with_metadata(def, &query.dict_path))
                .collect(),
        )),
        None => Ok(Json(vec![])),
    }
}

pub async fn list_dictionaries() -> Result<Json<Vec<String>>, ServerError> {
    let dictionaries_dir = data_dir::get_dictionaries_dir().map_err(|e| ServerError(e))?;

    let mut dictionary_names = Vec::new();

    if let Ok(entries) = std::fs::read_dir(&dictionaries_dir) {
        for entry in entries {
            if let Ok(entry) = entry {
                let path = entry.path();
                if path.is_dir() {
                    if let Some(dir_name) = path.file_name().and_then(|n| n.to_str()) {
                        // Look for any .ifo files in the directory
                        if let Ok(dir_entries) = std::fs::read_dir(&path) {
                            for dir_entry in dir_entries {
                                if let Ok(dir_entry) = dir_entry {
                                    let file_path = dir_entry.path();
                                    if let Some(extension) = file_path.extension() {
                                        if extension == "ifo" {
                                            if let Some(file_name) =
                                                file_path.file_name().and_then(|n| n.to_str())
                                            {
                                                dictionary_names
                                                    .push(format!("{}/{}", dir_name, file_name));
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    dictionary_names.sort();
    Ok(Json(dictionary_names))
}

pub async fn open_app_data_dir() -> Result<Json<()>, ServerError> {
    let data_dir = data_dir::get_data_dir().map_err(|e| ServerError(e))?;

    if let Err(e) = open::that(data_dir) {
        return Err(ServerError(anyhow::anyhow!(
            "Failed to open directory: {}",
            e
        )));
    }

    Ok(Json(()))
}

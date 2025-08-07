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
use axum::http::header;
use axum::http::StatusCode;
use axum::response::Response;
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
            definitions.into_iter().map(|def| def.into()).collect(),
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

// TODO this is very hacky... is there a cleaner way to do this?
// but it works for now
pub async fn serve_dictionary_resource(
    Path((dict_name, resource_path)): Path<(String, String)>,
) -> Result<Response<axum::body::Body>, StatusCode> {
    debug!(dict_name = %dict_name, resource_path = %resource_path, "Serving dictionary resource");

    let dictionaries_dir = match data_dir::get_dictionaries_dir() {
        Ok(dir) => dir,
        Err(_) => return Err(StatusCode::INTERNAL_SERVER_ERROR),
    };

    let dict_dir = dictionaries_dir.join(&dict_name);
    let resource_file = dict_dir.join(&resource_path);

    // Security check: ensure the requested file is within the dictionary directory
    if !resource_file.starts_with(&dict_dir) {
        debug!(
            "Invalid resource path: {} not within {}",
            resource_file.display(),
            dict_dir.display()
        );
        return Err(StatusCode::BAD_REQUEST);
    }

    // Check if file exists
    if !resource_file.exists() {
        debug!("Resource not found: {}", resource_file.display());
        return Err(StatusCode::NOT_FOUND);
    }

    // Read file content
    let content = match std::fs::read(&resource_file) {
        Ok(content) => content,
        Err(e) => {
            debug!("Error reading file {}: {}", resource_file.display(), e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // Determine content type based on file extension
    let content_type = match resource_file
        .extension()
        .and_then(|ext| ext.to_str())
        .unwrap_or("")
    {
        "css" => "text/css",
        "js" => "application/javascript",
        "png" => "image/png",
        "jpg" | "jpeg" => "image/jpeg",
        "gif" => "image/gif",
        "svg" => "image/svg+xml",
        "woff" => "font/woff",
        "woff2" => "font/woff2",
        "ttf" => "font/ttf",
        _ => "application/octet-stream",
    };

    // Build response
    match Response::builder()
        .status(StatusCode::OK)
        .header(header::CONTENT_TYPE, content_type)
        .header(header::CACHE_CONTROL, "public, max-age=3600") // Cache for 1 hour
        .body(axum::body::Body::from(content))
    {
        Ok(response) => Ok(response),
        Err(e) => {
            debug!("Error building response: {}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

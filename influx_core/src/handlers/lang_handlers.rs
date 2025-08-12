use axum::extract::Path;

use super::ServerError;

use crate::db::models::lang::{Language, ParserConfig};

use axum::Json;

use crate::ServerState;

use crate::db::InfluxResourceId;
use axum::extract::State;
use axum::http::StatusCode;
use tracing::debug;

#[derive(
    serde::Deserialize, serde::Serialize, elm_rs::Elm, elm_rs::ElmEncode, elm_rs::ElmDecode,
)]
pub struct LanguageCreateRequest {
    pub name: String,
    pub dicts: Vec<String>,
    pub tts_rate: Option<f64>,
    pub tts_pitch: Option<f64>,
    pub tts_voice: Option<String>,
    pub deepl_source_lang: Option<String>,
    pub deepl_target_lang: Option<String>,
    pub parser_config: ParserConfig,
}

impl From<LanguageCreateRequest> for Language {
    fn from(req: LanguageCreateRequest) -> Self {
        Language {
            id: None,
            name: req.name,
            dicts: req.dicts,
            tts_rate: req.tts_rate,
            tts_pitch: req.tts_pitch,
            tts_voice: req.tts_voice,
            deepl_source_lang: req.deepl_source_lang,
            deepl_target_lang: req.deepl_target_lang,
            parser_config: req.parser_config,
        }
    }
}

pub async fn get_language_list(
    State(ServerState { db, .. }): State<ServerState>,
) -> Result<Json<Vec<Language>>, ServerError> {
    debug!("Fetching language list");
    let languages = db.get_languages_vec().await?;
    Ok(Json(languages))
}

pub async fn get_language_by_id(
    State(ServerState { db, .. }): State<ServerState>,
    Path(lang_id): Path<String>,
) -> Result<Json<Option<Language>>, ServerError> {
    let id = lang_id
        .parse::<i64>()
        .map_err(|_| anyhow::anyhow!("Invalid language ID format"))?;
    let resource_id = crate::db::InfluxResourceId::from(id);
    let language = db.get_language(resource_id).await?;
    if language.is_none() {
        return Err(anyhow::anyhow!("Language not found").into());
    }
    Ok(Json(language))
}

pub async fn update_language(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Language>,
) -> Result<Json<Language>, ServerError> {
    debug!(language_id = ?payload.id, name = %payload.name, "Updating language");
    Ok(Json(db.update_language(payload).await?))
}

pub async fn create_language(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<LanguageCreateRequest>,
) -> Result<Json<Language>, ServerError> {
    debug!(name = %payload.name, "Creating language");
    let language: Language = payload.into();
    Ok(Json(db.create_language(language).await?))
}

pub async fn delete_language(
    State(ServerState { db, .. }): State<ServerState>,
    Path(id): Path<String>,
) -> Result<StatusCode, ServerError> {
    let language_id = InfluxResourceId::SerialId(
        id.parse::<i64>()
            .map_err(|_| ServerError(anyhow::anyhow!("Invalid language ID: {}", id)))?,
    );
    debug!(language_id = ?language_id, "Deleting language");
    db.delete_language(language_id).await?;
    Ok(StatusCode::NO_CONTENT)
}

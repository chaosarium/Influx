use axum::extract::Path;

use super::ServerError;

use crate::db::models::lang::LanguageEntry;

use axum::Json;

use crate::ServerState;

use axum::extract::State;
use tracing::debug;

pub async fn get_language_list(
    State(ServerState { influx_path, db }): State<ServerState>,
) -> Result<Json<Vec<LanguageEntry>>, ServerError> {
    debug!("Fetching language list");
    let languages = db.get_languages_vec().await?;
    Ok(Json(languages))
}

pub async fn get_language_by_id(
    State(ServerState { influx_path, db }): State<ServerState>,
    Path(lang_id): Path<String>,
) -> Result<Json<Option<LanguageEntry>>, ServerError> {
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
    Json(payload): Json<LanguageEntry>,
) -> Result<Json<LanguageEntry>, ServerError> {
    debug!(language_id = ?payload.id, code = %payload.code, name = %payload.name, "Updating language");
    Ok(Json(db.update_language(payload).await?))
}

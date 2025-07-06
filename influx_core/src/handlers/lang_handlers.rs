use axum::extract::Path;

use super::ServerError;

use crate::db::models::lang::LanguageEntry;

use axum::Json;

use crate::ServerState;

use axum::extract::State;

pub async fn get_language_list(
    State(ServerState { influx_path, db }): State<ServerState>,
) -> Result<Json<Vec<LanguageEntry>>, ServerError> {
    println!("get_language_list");
    let languages = db.get_languages_vec().await?;
    Ok(Json(languages))
}

pub async fn get_language_by_identifier(
    State(ServerState { influx_path, db }): State<ServerState>,
    Path(id): Path<String>,
) -> Result<Json<Option<LanguageEntry>>, ServerError> {
    let language = db.get_language_by_identifier(id).await?;
    if language.is_none() {
        return Err(anyhow::anyhow!("Language not found").into());
    }
    Ok(Json(language))
}

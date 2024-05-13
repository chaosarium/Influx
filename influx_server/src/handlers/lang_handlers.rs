use axum::extract::Path;

use super::ServerError;

use crate::db::models::lang::LanguageEntry;

use axum::Json;

use crate::ServerState;

use axum::extract::State;

pub async fn get_language_list(
    State(ServerState { influx_path, db }): State<ServerState>, 
) -> Result<Json<Vec<LanguageEntry>>, ServerError> {
    let languages = db.get_languages_vec().await?;
    Ok(Json(languages))
}

pub async fn get_language_by_id(
    State(ServerState { influx_path, db }): State<ServerState>, 
    Path(id): Path<String>
) -> Result<Json<Option<LanguageEntry>>, ServerError> {
    let language = db.get_language(id).await?;
    Ok(Json(language))
}

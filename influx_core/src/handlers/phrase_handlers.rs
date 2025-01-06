use super::ServerError;

use crate::db::models::phrase::Phrase;

use axum::Json;
use serde::Deserialize;

use crate::ServerState;

use axum::extract::State;

pub async fn update_phrase(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<Phrase>,
) -> Result<Json<Phrase>, ServerError> {
    println!("phrase update attempt payload: {:?}", payload);
    let phrase = db.update_phrase_by_id(payload).await?;
    Ok(Json(phrase))
}

pub async fn delete_phrase(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<Phrase>,
) -> Result<Json<Phrase>, ServerError> {
    println!("phrase delete attempt payload: {:?}", payload);
    match payload.id {
        None => {
            return Err(ServerError(anyhow::anyhow!("cannot delete if no id")));
        },
        Some(thing) => {
            let phrase = db.delete_phrase_by_thing(thing).await?;
            Ok(Json(phrase))
        },
    }
}

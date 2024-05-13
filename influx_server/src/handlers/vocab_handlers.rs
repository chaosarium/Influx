use axum::extract::Path;
use serde::Deserialize;
use super::ServerError;
use crate::db::models::vocab::Token;
use axum::Json;
use crate::ServerState;
use axum::extract::State;

pub async fn create_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token create attempt payload: {:?}", payload);

    let token = db.create_token(payload).await?;

   Ok(Json(token))
}

pub async fn delete_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token delete attempt payload: {:?}", payload);
    match payload.id {
        None => {
            return Err(ServerError(anyhow::anyhow!("cannot delete if no id")));
        },
        Some(thing) => {
            let token = db.delete_token_by_thing(thing).await?;
            Ok(Json(token))
        },
    }
}

pub async fn lookup_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Path((lang_id, orthography)): Path<(String, String)>
) -> Result<Json<Option<Token>>, ServerError> {
    let token = db.query_token_by_orthography(orthography, lang_id).await?;
    Ok(Json(token))
}

pub async fn update_token(
    State(ServerState { db, .. }): State<ServerState>, 
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token update attempt payload: {:?}", payload);
    let token = db.update_token_by_id(payload).await?;
    Ok(Json(token))
}
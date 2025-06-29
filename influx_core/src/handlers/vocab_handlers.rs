use super::ServerError;
use crate::db::models::vocab::{Token, TokenStatus};
use crate::ServerState;
use axum::extract::Path;
use axum::extract::State;
use axum::Json;
use serde::Deserialize;

pub async fn create_token(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token create attempt payload: {:?}", payload);
    if payload.status == TokenStatus::UNMARKED {
        return Err(ServerError(anyhow::anyhow!(
            "cannot create token with status UNMARKED"
        )));
    }
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
        }
        Some(id) => {
            let deleted_token = db.delete_token(id).await?;
            println!("deleted token: {:?}", deleted_token);
            let unmarked_token = Token::unmarked_token(payload.lang_id, &payload.orthography);
            Ok(Json(unmarked_token))
        }
    }
}

pub async fn lookup_token(
    State(ServerState { db, .. }): State<ServerState>,
    Path((lang_id, orthography)): Path<(String, String)>,
) -> Result<Json<Option<Token>>, ServerError> {
    let token = db
        .query_token_by_lang_identifier_and_orthography(lang_id, orthography)
        .await?;
    Ok(Json(token))
}

pub async fn update_token(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token update attempt payload: {:?}", payload);
    let token = db.update_token(payload).await?;
    Ok(Json(token))
}

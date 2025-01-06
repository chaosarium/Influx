use axum::extract::Path;
use serde::Deserialize;
use super::ServerError;
use crate::db::models::vocab::Token;
use axum::Json;
use crate::ServerState;
use axum::extract::State;
use crate::integration;
use crate::integration::ExternalDict;
use crate::integration::ExternalTranslator;

pub async fn lookup_in_macos_dict (
    State(ServerState { db, .. }): State<ServerState>, 
    Path((lang_id, orthography)): Path<(String, String)>
) -> Result<(), ServerError> {
    let dict = integration::MacOSDict;
    println!("lookup_in_macos_dict: {:?}", orthography);
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

pub async fn extern_translate (
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<ExternTranslatePayload>,
) -> Result<Json<ExternTranslateResponse>, ServerError> {
    if payload.provider != "google" {
        return Err(ServerError(anyhow::anyhow!("unsupported provider")));
    }
    let translator = integration::GoogleTranslate;
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

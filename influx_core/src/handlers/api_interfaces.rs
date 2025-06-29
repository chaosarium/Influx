use crate::db::models::vocab::Token;
use crate::doc_store;
use crate::nlp;
use crate::prelude::*;
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};

// https://github.com/tokio-rs/axum/blob/main/examples/anyhow-error-response/src/main.rs
pub struct ServerError(pub anyhow::Error);
impl IntoResponse for ServerError {
    fn into_response(self) -> Response {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Something went wrong: {}", self.0),
        )
            .into_response()
    }
}
impl<E> From<E> for ServerError
where
    E: Into<anyhow::Error>,
{
    fn from(err: E) -> Self {
        Self(err.into())
    }
}

// TERMS

pub type TokenEditRequest = Token;
pub type TokenEditResponse = Token;
pub type PhraseEditRequest = Token;
pub type PhraseEditResponse = Token;
pub enum TermEditRequest {
    TokenEdit(TokenEditRequest),
    PhraseEdit(PhraseEditRequest),
}
pub enum TermEditResponse {
    TokenEdit(TokenEditResponse),
    PhraseEdit(PhraseEditResponse),
}

// DOCUMENT

#[derive(Serialize, Deserialize, Debug, Clone, Elm, ElmEncode, ElmDecode)]
pub struct GetDocResponse {
    pub metadata: doc_store::DocMetadata,
    pub text: String,
    pub annotated_doc: nlp::AnnotatedDocument,
}

use crate::db::models::phrase::Phrase;
use crate::db::models::vocab::Token;
use crate::db::InfluxResourceId;
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

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash, Elm, ElmEncode, ElmDecode)]
pub enum Term {
    TokenTerm(Token),
    PhraseTerm(Phrase),
}
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash, Elm, ElmEncode, ElmDecode)]
pub enum TermEditAction {
    CreateTerm,
    UpdateTerm,
    DeleteTerm,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash, Elm, ElmEncode, ElmDecode)]
pub struct TermEditRequest {
    pub requested_action: TermEditAction,
    pub term: Term,
}
#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash, Elm, ElmEncode, ElmDecode)]
pub struct TermEditResponse {
    pub performed_action: TermEditAction,
    pub term: Term,
}

// DOCUMENT

#[derive(Serialize, Deserialize, Debug, Clone, Elm, ElmEncode, ElmDecode)]
pub struct GetDocResponse {
    pub metadata: doc_store::DocMetadata,
    pub lang_id: InfluxResourceId,
    pub text: String,
    pub annotated_doc: nlp::AnnotatedDocV2,
}

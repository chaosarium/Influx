use crate::db::models::fsrs;
use crate::db::models::phrase::Phrase;
use crate::db::models::vocab::Token;
use crate::db::InfluxResourceId;
use crate::nlp;
use crate::prelude::*;
use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};

// https://github.com/tokio-rs/axum/blob/main/examples/anyhow-error-response/src/main.rs
#[derive(Debug)]
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

#[derive(Debug, SerdeDerives!, Clone, PartialEq, Eq, Hash, ElmDerives!)]
pub enum Term {
    TokenTerm(Token),
    PhraseTerm(Phrase),
}

impl Term {
    pub fn as_token(&self) -> Option<&Token> {
        match self {
            Term::TokenTerm(token) => Some(token),
            Term::PhraseTerm(_) => None,
        }
    }

    pub fn as_phrase(&self) -> Option<&Phrase> {
        match self {
            Term::TokenTerm(_) => None,
            Term::PhraseTerm(phrase) => Some(phrase),
        }
    }

    pub fn get_lang_id(&self) -> InfluxResourceId {
        match self {
            Term::TokenTerm(token) => token.lang_id.clone(),
            Term::PhraseTerm(phrase) => phrase.lang_id.clone(),
        }
    }
}
#[derive(Debug, SerdeDerives!, Clone, PartialEq, Eq, Hash, ElmDerives!)]
pub enum TermEditAction {
    CreateTerm,
    UpdateTerm,
    DeleteTerm,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, Eq, Hash, ElmDerives!)]
pub struct GetDocsRequest {
    pub language_id: Option<InfluxResourceId>,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, Eq, Hash, ElmDerives!)]
pub struct TermEditRequest {
    pub requested_action: TermEditAction,
    pub term: Term,
    pub document_id: Option<InfluxResourceId>,
}

#[derive(Debug, SerdeDerives!, Clone, ElmDerives!)]
pub struct TermEditResponse {
    pub performed_action: TermEditAction,
    pub term: Term,
    pub updated_annotated_doc: Option<nlp::AnnotatedDocV2>,
}

// DOCUMENT

#[derive(SerdeDerives!, Debug, Clone, ElmDerives!)]
pub struct GetDocResponse {
    pub doc_package: crate::db::models::document::DocPackage,
    pub annotated_doc: nlp::AnnotatedDocV2,
    pub term_dict: nlp::TermDictionary,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, Eq, ElmDerives!)]
pub enum ReviewableCardId {
    ExistingCard(InfluxResourceId),
    NewTokenCard {
        token_id: InfluxResourceId,
        card_type: fsrs::CardType,
    },
    NewPhraseCard {
        phrase_id: InfluxResourceId,
        card_type: fsrs::CardType,
    },
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, ElmDerives!)]
pub struct CardWithTerm {
    pub card: fsrs::Card,
    pub term: Term,
    pub is_new_card: bool, // True if this is an implicit new card (not yet in database)
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, ElmDerives!)]
pub struct GetNextDueCardRequest {
    pub lang_id: InfluxResourceId,
    pub card_types: Option<Vec<fsrs::CardType>>,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, ElmDerives!)]
pub struct GetNextDueCardResponse {
    pub card: Option<CardWithTerm>,
    pub remaining_due_count: usize,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, ElmDerives!)]
pub struct SubmitReviewRequest {
    pub card_identifier: ReviewableCardId,
    pub rating: i32, // TODO should use enum instead
    pub review_time_ms: Option<i32>,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, ElmDerives!)]
pub struct SubmitReviewResponse {
    pub updated_card: fsrs::Card,
    pub review_log: fsrs::ReviewLog,
    pub next_due_date: chrono::DateTime<chrono::Utc>,
    pub was_new_card: bool, // True if card was created during this review
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, ElmDerives!)]
pub struct UpdateFSRSConfigRequest {
    pub new_config: fsrs::FSRSLanguageConfig,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, ElmDerives!)]
pub struct UpdateFSRSConfigResponse {
    pub updated_config: fsrs::FSRSLanguageConfig,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, ElmDerives!)]
pub struct SetCardStateRequest {
    pub card_id: InfluxResourceId,
    pub new_state: fsrs::CardState,
}

#[derive(Debug, SerdeDerives!, Clone, PartialEq, ElmDerives!)]
pub struct SetCardStateResponse {
    pub updated_card: fsrs::Card,
}

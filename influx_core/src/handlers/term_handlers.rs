use super::ServerError;
use crate::db::models::phrase::Phrase;
use crate::db::models::vocab::Token;
use crate::handlers::api_interfaces::*;
use crate::ServerState;
use axum::extract::State;
use axum::Json;

pub async fn create_token(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token create attempt payload: {:?}", payload);
    Ok(Json(db.create_token(payload).await?))
}

async fn create_phrase(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Phrase>,
) -> Result<Json<Phrase>, ServerError> {
    println!("phrase create attempt payload: {:?}", payload);
    Ok(Json(db.create_phrase(payload).await?))
}

pub async fn update_token(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token update attempt payload: {:?}", payload);
    Ok(Json(db.update_token(payload).await?))
}

pub async fn update_phrase(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Phrase>,
) -> Result<Json<Phrase>, ServerError> {
    println!("phrase update attempt payload: {:?}", payload);
    Ok(Json(db.update_phrase(payload).await?))
}

pub async fn delete_token(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Token>,
) -> Result<Json<Token>, ServerError> {
    println!("token delete attempt payload: {:?}", payload);
    Ok(Json(db.delete_token_and_return_unmarked(payload).await?))
}

pub async fn delete_phrase(
    State(ServerState { db, .. }): State<ServerState>,
    Json(payload): Json<Phrase>,
) -> Result<Json<Phrase>, ServerError> {
    println!("phrase delete attempt payload: {:?}", payload);
    Ok(Json(db.delete_phrase_and_return_deleted(payload).await?))
}

pub async fn edit_term(
    State(state): State<ServerState>,
    Json(request): Json<TermEditRequest>,
) -> Result<Json<TermEditResponse>, ServerError> {
    println!("term edit attempt request: {:?}", request);
    use Term::*;
    use TermEditAction::*;
    let term_becomes = match (&request.requested_action, request.term) {
        (CreateTerm, TokenTerm(token)) => TokenTerm(state.db.create_token(token).await?),
        (CreateTerm, PhraseTerm(phrase)) => PhraseTerm(state.db.create_phrase(phrase).await?),
        (UpdateTerm, TokenTerm(token)) => TokenTerm(state.db.update_token(token).await?),
        (UpdateTerm, PhraseTerm(phrase)) => PhraseTerm(state.db.update_phrase(phrase).await?),
        (DeleteTerm, TokenTerm(token)) => {
            TokenTerm(state.db.delete_token_and_return_unmarked(token).await?)
        }
        (DeleteTerm, PhraseTerm(phrase)) => {
            PhraseTerm(state.db.delete_phrase_and_return_unmarked(phrase).await?)
        }
    };

    let updated_annotated_doc = if let Some(doc_path) = request.doc_path {
        let response =
            super::doc_handlers::get_annotated_doc_logic(&state, doc_path.lang, doc_path.file)
                .await?;
        Some(response.annotated_doc)
    } else {
        None
    };

    Ok(Json(TermEditResponse {
        term: term_becomes,
        performed_action: request.requested_action,
        updated_annotated_doc,
    }))
}

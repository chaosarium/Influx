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
    State(ServerState { db, .. }): State<ServerState>,
    Json(request): Json<TermEditRequest>,
) -> Result<Json<TermEditResponse>, ServerError> {
    println!("term edit attempt request: {:?}", request);
    use Term::*;
    use TermEditAction::*;
    let term_becomes = match (&request.requested_action, request.term) {
        (CreateTerm, TokenTerm(token)) => TokenTerm(db.create_token(token).await?),
        (CreateTerm, PhraseTerm(phrase)) => PhraseTerm(db.create_phrase(phrase).await?),
        (UpdateTerm, TokenTerm(token)) => TokenTerm(db.update_token(token).await?),
        (UpdateTerm, PhraseTerm(phrase)) => PhraseTerm(db.update_phrase(phrase).await?),
        (DeleteTerm, TokenTerm(token)) => {
            TokenTerm(db.delete_token_and_return_unmarked(token).await?)
        }
        (DeleteTerm, PhraseTerm(phrase)) => {
            PhraseTerm(db.delete_phrase_and_return_deleted(phrase).await?)
        } // TODO unmarked phrase isn't really a thing?
    };
    Ok(Json(TermEditResponse {
        term: term_becomes,
        performed_action: request.requested_action,
    }))
}

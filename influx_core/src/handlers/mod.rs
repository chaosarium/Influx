use axum::{http::StatusCode, response::IntoResponse};

pub mod api_interfaces;
pub use api_interfaces::*;
pub mod doc_handlers;
pub mod fsrs_handlers;
pub mod integration_handlers;
pub mod lang_handlers;
pub mod term_handlers;

pub async fn connection_test() -> impl IntoResponse {
    StatusCode::OK
}

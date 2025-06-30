use crate::doc_store::DocEntry;
use crate::doc_store::{gt_md_file_list_w_metadata, read_md_file};
use crate::nlp;
use crate::prelude::*;
use crate::{
    db::models::{
        lang::LanguageEntry,
        phrase::{mk_phrase_trie, Phrase},
        vocab::{self, TokenStatus},
    },
    doc_store::write_md_file,
    utils::trie::Trie,
    ServerState,
};
use crate::{
    db::{models::vocab::Token, DB},
    doc_store,
};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    response::Response,
    Json,
};
use md5;
use serde_json;
use serde_json::json;
use std::fs;
use std::{
    collections::{HashMap, HashSet},
    path::PathBuf,
};
use tracing::info;

pub mod api_interfaces;
pub use api_interfaces::*;
pub mod integration_handlers;
pub mod lang_handlers;
pub mod term_handlers;
pub mod doc_handlers;

pub async fn connection_test() -> impl IntoResponse {
    StatusCode::OK
}


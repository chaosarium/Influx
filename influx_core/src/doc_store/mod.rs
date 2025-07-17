//! provides functionality to work with content stored on disk
#![allow(unused_imports)]

use chrono::{DateTime, Local, Utc};
use elm_rs::{Elm, ElmDecode, ElmEncode, ElmQuery, ElmQueryField};
use md5;
use serde::{Deserialize, Serialize};
use serde_yaml;
use std::error::Error;
use std::ffi::OsStr;
use std::fs;
use std::fs::DirEntry;
use std::io;
use std::path::{Path, PathBuf};
use toml::Table;
use toml::Value;
use yaml_front_matter::Document;
use yaml_front_matter::YamlFrontMatter;

#[derive(Deserialize, PartialEq, Debug, Serialize, Copy, Clone, Elm, ElmEncode, ElmDecode)]
pub enum DocType {
    Text,
    Video,
    Audio,
}

#[derive(Debug, Clone, Deserialize, Serialize, Elm, ElmEncode, ElmDecode)]
pub struct DocEntry {
    pub id: crate::db::InfluxResourceId,
    pub language: crate::db::models::lang::LanguageEntry,
    pub title: String,
    pub doc_type: DocType,
    pub tags: Vec<String>,
    pub date_created: DateTime<Utc>,
    pub date_modified: DateTime<Utc>,
}

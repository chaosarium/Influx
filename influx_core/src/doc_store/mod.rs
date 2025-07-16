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

#[derive(Deserialize, Debug, Serialize, Clone, PartialEq, Elm, ElmEncode, ElmDecode)]
pub struct DocMetadata {
    pub title: String,
    pub doc_type: DocType,
    pub tags: Vec<String>,
    pub date_created: DateTime<Utc>,
    pub date_modified: DateTime<Utc>,
}

#[derive(Debug, Clone, Deserialize, Serialize, Elm, ElmEncode, ElmDecode)]
pub struct DocEntry {
    pub id: crate::db::InfluxResourceId,
    pub metadata: DocMetadata,
}

// #[derive(Serialize, Deserialize, Debug, Elm, ElmEncode, ElmDecode)]
// pub struct LanguageSetting {
//     pub identifier: String,
//     pub display_name: String,
//     pub code: String,
//     pub dict1: Option<String>,
//     pub dict2: Option<String>,
// }

/// Loads a TOML file from the given path and parses it into a type `T`.
///
/// This function reads the file content as a string and then uses the `toml` crate's `from_str` function
/// to parse the string into the type `T`. The type `T` must implement the `Deserialize` trait.
pub fn load_and_parse_toml_file<T: for<'a> Deserialize<'a>>(path: PathBuf) -> anyhow::Result<T> {
    let file_content = fs::read_to_string(path)?;
    let parsed: T = toml::from_str(&file_content)?;
    Ok(parsed)
}

// #[deprecated]
// pub fn read_settings_file(influx_path: PathBuf) -> anyhow::Result<Settings> {
//     let path = influx_path.join("settings.toml");
//     let settings = load_and_parse_toml_file::<Settings>(path);
//     settings
// }

fn get_md_files_list(dir: PathBuf) -> Result<Vec<fs::DirEntry>, io::Error> {
    let entries = fs::read_dir(dir)?;

    let md_entries: Vec<fs::DirEntry> = entries
        .filter_map(|entry| entry.ok())
        .filter(|entry| {
            let path = entry.path();
            path.is_file() && path.extension() == Some(std::ffi::OsStr::new("md"))
        })
        .collect();

    Ok(md_entries)
}

fn get_md_file_metadata(path: PathBuf) -> Result<DocMetadata, io::Error> {
    Ok((read_md_file(path)?).0)
}

pub fn read_md_file(path: PathBuf) -> Result<(DocMetadata, String), io::Error> {
    let file_buf = fs::read_to_string(path)?;
    let document: Document<DocMetadata> = YamlFrontMatter::parse::<DocMetadata>(&file_buf).unwrap();
    Ok((document.metadata, document.content))
}

pub fn write_md_file(
    filepath: PathBuf,
    metadata: DocMetadata,
    content: String,
) -> Result<(), io::Error> {
    let front_matter = serde_yaml::to_string(&metadata).unwrap();
    let file_content = format!("---\n{}\n---\n{}", front_matter, content);
    fs::write(filepath, file_content)?;
    Ok(())
}

//! provides functionality to work with content stored on disk
#![allow(unused_imports)]

use std::error::Error;
use std::ffi::OsStr;
use std::fs;
use std::fs::DirEntry;
use std::io;
use std::path::{Path, PathBuf};
use serde::{Deserialize, Serialize};
use yaml_front_matter::YamlFrontMatter;
use yaml_front_matter::Document;
use chrono::{Local, DateTime, Utc};
use toml::Table;
use toml::Value;

#[derive(Deserialize, PartialEq, Debug, Serialize)]
pub enum DocType {
    Text,
    Video,
    Audio,
}

#[derive(Deserialize, Debug, Serialize)]
pub struct Metadata {
    title: String,
    doc_type: DocType,
    tags: Vec<String>,
    date_created: DateTime::<Utc>,
    date_modified: DateTime::<Utc>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct DocEntry {
    path: PathBuf,
    filename: PathBuf,
    metadata: Metadata,
}


#[derive(Serialize, Deserialize, Debug)]
pub struct Settings {
    pub port: Option<u16>,
    pub lang: Vec<LanguageSetting>,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct LanguageSetting {
    pub identifier: String,
    pub display_name: String,
    pub code: String,
    pub dict1: Option<String>,
    pub dict2: Option<String>,
}

/// Loads a TOML file from the given path and parses it into a type `T`.
///
/// This function reads the file content as a string and then uses the `toml` crate's `from_str` function
/// to parse the string into the type `T`. The type `T` must implement the `Deserialize` trait.
pub fn load_and_parse_toml_file<T: for<'a> Deserialize<'a>>(path: PathBuf) -> anyhow::Result<T> {
    let file_content = fs::read_to_string(path)?;
    let parsed: T = toml::from_str(&file_content)?;
    Ok(parsed)
}

#[deprecated]
pub fn read_settings_file(influx_path: PathBuf) -> anyhow::Result<Settings> {
    let path = influx_path.join("settings.toml");
    let settings = load_and_parse_toml_file::<Settings>(path);
    settings
}


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

fn get_md_file_metadata(path: PathBuf) -> Result<Metadata, io::Error> {
    Ok((read_md_file(path)?).0)
}

pub fn read_md_file(path: PathBuf) -> Result<(Metadata, String), io::Error> {
    let file_buf = fs::read_to_string(path)?;
    let document: Document<Metadata> = YamlFrontMatter::parse::<Metadata>(&file_buf).unwrap();
    Ok((document.metadata, document.content))
}

pub fn gt_md_file_list_w_metadata(dir: PathBuf) -> Result<Vec<DocEntry>, io::Error> {
    let md_entries = get_md_files_list(dir)?;

    let mut doc_entries: Vec<DocEntry> = Vec::new();

    for entry in md_entries {
        let path = entry.path();

        let filename = path.file_name().unwrap().into();

        let metadata = get_md_file_metadata(path.clone())?;
        let doc_entry = DocEntry {
            path,
            filename,
            metadata,
        };
        doc_entries.push(doc_entry);
    }

    doc_entries.sort_by(|a, b| a.metadata.date_created.cmp(&b.metadata.date_created));

    Ok(doc_entries)
}


const SAMPLE_MD_DOC: &str = r#"
---
title: 'Livre premier--Un juste, Chapitre I'
doc_type: 'Text'
tags: ['tag1', 'tag2']
date_created: '2014-11-28T12:45:59.324310806Z'
date_modified: '2015-11-28T12:45:59.324310806Z'
---

Livre premier--Un juste

Chapitre I

Monsieur Myriel

En 1815, M. Charles-François-Bienvenu Myriel était évêque de Digne.
C'était un vieillard d'environ soixante-quinze ans; il occupait le siège
de Digne depuis 1806.

"#;



#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_toml_parsing() {
        let value = "foo = 'bar'".parse::<Table>().unwrap();
        assert_eq!(value["foo"].as_str(), Some("bar"));

        let path = PathBuf::from("../toy_content/settings.toml");
        let settings = load_and_parse_toml_file::<Settings>(path);

        dbg!(&settings);
    
    }


    #[test]
    fn test_list_md_files() {
        let result = get_md_files_list("../toy_content/fr_demo".into());
        assert!(result.is_ok());
    }

    #[test]
    fn test_frontmatter_extract() {
        
        let document: Document<Metadata> = YamlFrontMatter::parse::<Metadata>(&SAMPLE_MD_DOC).unwrap();

        assert_eq!(document.metadata.title, "Livre premier--Un juste, Chapitre I");
        assert_eq!(document.metadata.doc_type, DocType::Text);
        assert_eq!(document.metadata.tags, vec!["tag1", "tag2"]);
        assert_eq!(document.metadata.date_created, "2014-11-28T12:45:59.324310806Z".parse::<DateTime<Utc>>().unwrap());
        assert_eq!(document.metadata.date_modified, "2015-11-28T12:45:59.324310806Z".parse::<DateTime<Utc>>().unwrap());

        println!("{}", document.content)
    }
        
    #[test]
    fn test_get_md_file_metadata() {
        let path = "../toy_content/fr_demo/Les misérables 1.md";
        let result = get_md_file_metadata(path.into());
        
        assert!(result.is_ok());
        let metadata = result.unwrap();
        
        // Add assertions for the expected metadata values
        assert_eq!(metadata.title, "Livre premier--Un juste, Chapitre I");
        assert_eq!(metadata.doc_type, DocType::Text);
        assert_eq!(metadata.tags, vec!["tag1", "tag2"]);
        assert_eq!(metadata.date_created, "2014-11-28T12:45:59.324310806Z".parse::<DateTime<Utc>>().unwrap());
        assert_eq!(metadata.date_modified, "2015-11-28T12:45:59.324310806Z".parse::<DateTime<Utc>>().unwrap());
    }

        
    #[test]
    fn test_list_md_files_metadata() {
        let directory = "../toy_content/fr_demo";
        let result = gt_md_file_list_w_metadata(directory.into());

        assert!(result.is_ok());
        let metadata_list = result.unwrap();

        assert_eq!(metadata_list.len(), 4);
        println!("{:#?}", metadata_list);

        let expected_titles = vec![
            "Livre premier--Un juste, Chapitre I",
            "Livre premier--Un juste, Chapitre II",
            "Livre premier--Un juste, Chapitre III",
            "Toy Example",
        ];
        let expected_doc_types = vec![
            DocType::Text,
            DocType::Text,
            DocType::Text,
            DocType::Text,
        ];
        let expected_tags = vec![
            vec!["tag1", "tag2"],
            vec!["tag2", "tag3"],
            vec!["tag3"],
            vec!["tag1", "tag2"],
        ];

        for (i, DocEntry {path, filename, metadata}) in metadata_list.iter().enumerate() {
            assert_eq!(metadata.title, expected_titles[i]);
            assert_eq!(metadata.doc_type, expected_doc_types[i]);
            assert_eq!(metadata.tags, expected_tags[i]);
        }

    }


}
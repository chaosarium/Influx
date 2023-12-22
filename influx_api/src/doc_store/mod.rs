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


fn get_md_files_list(dir: &str) -> Result<Vec<fs::DirEntry>, io::Error> {
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

fn get_md_file_metadata(path: &str) -> Result<Metadata, io::Error> {
    Ok((read_md_file(path)?).0)
}

pub fn read_md_file(path: &str) -> Result<(Metadata, String), io::Error> {
    let file_buf = fs::read_to_string(path)?;
    let document: Document<Metadata> = YamlFrontMatter::parse::<Metadata>(&file_buf).unwrap();
    Ok((document.metadata, document.content))
}

pub fn gt_md_file_list_w_metadata(dir: &str) -> Result<Vec<DocEntry>, io::Error> {
    let md_entries = get_md_files_list(dir)?;

    let mut doc_entries: Vec<DocEntry> = Vec::new();

    for entry in md_entries {
        let path = entry.path();

        let filename = path.file_name().unwrap().into();

        let metadata = get_md_file_metadata(path.to_str().unwrap())?;
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
    fn test_list_md_files() {
        let result = get_md_files_list("/Users/chaosarium/Desktop/influx_content/fr");
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
        let path = "/Users/chaosarium/Desktop/influx_content/fr/Les misérables 1.md";
        let result = get_md_file_metadata(path);
        
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
        let directory = "/Users/chaosarium/Desktop/influx_content/fr";
        let result = gt_md_file_list_w_metadata(directory);

        assert!(result.is_ok());
        let metadata_list = result.unwrap();

        assert_eq!(metadata_list.len(), 3);
        println!("{:#?}", metadata_list);

        let expected_titles = vec![
            "Livre premier--Un juste, Chapitre I",
            "Livre premier--Un juste, Chapitre II",
            "Livre premier--Un juste, Chapitre III",
        ];
        let expected_doc_types = vec![
            DocType::Text,
            DocType::Text,
            DocType::Text,
        ];
        let expected_tags = vec![
            vec!["tag1", "tag2"],
            vec!["tag2", "tag3"],
            vec!["tag3"],
        ];

        for (i, DocEntry {path, filename, metadata}) in metadata_list.iter().enumerate() {
            assert_eq!(metadata.title, expected_titles[i]);
            assert_eq!(metadata.doc_type, expected_doc_types[i]);
            assert_eq!(metadata.tags, expected_tags[i]);
        }

    }


}
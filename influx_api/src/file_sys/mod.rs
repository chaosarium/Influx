//! provides functionality to work with content stored on disk
#![allow(unused_imports)]

use std::error::Error;
use std::fs;
use std::fs::DirEntry;
use std::io;
use std::path::Path;
use serde::Deserialize;
use yaml_front_matter::YamlFrontMatter;
use yaml_front_matter::Document;

fn list_md_files(dir: &str) -> Result<Vec<fs::DirEntry>, io::Error> {
    let entries = fs::read_dir(dir)?;

    let mut md_entries = Vec::new();

    for entry in entries {
        let entry = entry?;
        let path = entry.path();
        if path.is_file() && path.extension() == Some(std::ffi::OsStr::new("md")) {
            println!("{}", path.display());
            md_entries.push(entry);
        }
    }

    Ok(md_entries)
}

#[derive(Deserialize)]
enum DocType {
    Text,
    Video,
    Audio,
}

#[derive(Deserialize)]
struct Metadata {
    doc_type: DocType,
    title: String,
    tags: Vec<String>,
    similar_posts: Vec<String>,
    date: String,
    favorite_numbers: Vec<f64>,
}

const SAMPLE_MD_DOC: &str = r#"
---
title: 'Livre premier--Un juste, Chapitre I'
doc_type: 'Text'
tags: ['markdown', 'rust', 'files', 'parsing', 'metadata']
similar_posts:
  - 'Rendering markdown'
  - 'Using Rust to render markdown'
date: '2021-09-13T03:48:00'
favorite_numbers:
    - 3.14
    - 1970
    - 12345
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
        let result = list_md_files("/Users/chaosarium/Desktop/influx_content/fr");
        assert!(result.is_ok());
    }

    #[test]
    fn test_frontmatter_extract() {
        
        let document: Document<Metadata> = YamlFrontMatter::parse::<Metadata>(&SAMPLE_MD_DOC).unwrap();

        assert_eq!(document.metadata.title, "Livre premier--Un juste, Chapitre I");
        assert_eq!(
            document.metadata.tags,
            vec!["markdown", "rust", "files", "parsing", "metadata"]
        );
        assert_eq!(
            document.metadata.similar_posts,
            vec!["Rendering markdown", "Using Rust to render markdown"]
        );
        assert_eq!(document.metadata.date, "2021-09-13T03:48:00");
        assert_eq!(document.metadata.favorite_numbers, vec![3.14, 1970., 12345.]);        

        println!("{}", document.content)
    }
}
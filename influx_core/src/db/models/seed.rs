use super::document::Document;
use super::phrase::Phrase;
use super::vocab::{Token, TokenStatus};
use super::DB;
use crate::db::models::lang::LanguageEntry;
use chrono::{DateTime, Utc};

use anyhow::Result;

macro_rules! create_document_from_file {
    ($lang_id:expr, $filename:expr, $title:expr, $file_path:expr, $tags:expr) => {
        Document {
            id: None,
            lang_id: $lang_id.clone(),
            title: $title.to_string(),
            filename: $filename.to_string(),
            content: include_str!($file_path).to_string(),
            doc_type: "Text".to_string(),
            tags: $tags,
            created_ts: Utc::now(),
            updated_ts: Utc::now(),
        }
    };
}

impl DB {
    pub async fn seed_lang_table(&self) -> Result<()> {
        let languages = vec![
            LanguageEntry {
                id: None,
                identifier: "fr_demo".to_string(),
                code: "fr".to_string(),
                name: "French".to_string(),
                dicts: vec![
                    "dict:///###".to_string(),
                    "http://www.wordreference.com/fren/###".to_string(),
                ],
            },
            LanguageEntry {
                id: None,
                identifier: "en_demo".to_string(),
                code: "en".to_string(),
                name: "English".to_string(),
                dicts: vec![
                    "dict:///###".to_string(),
                    "http://www.wordreference.com/enfr/###".to_string(),
                ],
            },
            LanguageEntry {
                id: None,
                identifier: "ja_demo".to_string(),
                code: "ja".to_string(),
                name: "Japanese".to_string(),
                dicts: vec!["dict:///###".to_string()],
            },
            LanguageEntry {
                id: None,
                identifier: "zh-hant_demo".to_string(),
                code: "zh-hant".to_string(),
                name: "Mandarin".to_string(),
                dicts: vec!["dict:///###".to_string()],
            },
            LanguageEntry {
                id: None,
                identifier: "de_not_exist".to_string(),
                code: "de".to_string(),
                name: "Non-existent".to_string(),
                dicts: vec!["dict:///###".to_string()],
            },
        ];

        for language in languages {
            println!("Creating language: {:?}", language);
            self.create_language(language).await.unwrap();
        }

        Ok(())
    }

    pub async fn seed_vocab_table(&self) -> Result<()> {
        let tokens = vec![
            Token::fancier_token(
                self.get_language_by_identifier("en_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                "first",
                "1st",
                "ehh",
                TokenStatus::L5,
            ),
            Token::fancier_token(
                self.get_language_by_identifier("fr_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                "voix",
                "voice",
                "vwa",
                TokenStatus::L5,
            ),
            Token::fancier_token(
                self.get_language_by_identifier("fr_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                "parler",
                "speak",
                "",
                TokenStatus::L5,
            ),
            Token::fancier_token(
                self.get_language_by_identifier("fr_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                "parlerez",
                "speak",
                "inflection of parler",
                TokenStatus::L5,
            ),
            Token::fancier_token(
                self.get_language_by_identifier("fr_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                "habitaient",
                "lived",
                "inflection of habiter",
                TokenStatus::L5,
            ),
            Token::fancier_token(
                self.get_language_by_identifier("fr_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                "cœur",
                "heart",
                "kœʀ",
                TokenStatus::L4,
            ),
            Token::fancier_token(
                self.get_language_by_identifier("fr_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                "qui",
                "谁",
                "",
                TokenStatus::L3,
            ),
            Token::fancier_token(
                self.get_language_by_identifier("fr_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                "au",
                "= à le, or",
                "",
                TokenStatus::L2,
            ),
            Token::fancier_token(
                self.get_language_by_identifier("fr_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                "kiwis",
                "kiwi plural",
                "kiwi",
                TokenStatus::L1,
            ),
            Token::fancier_token(
                self.get_language_by_identifier("fr_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                "les",
                "le -> les",
                "",
                TokenStatus::IGNORED,
            ),
        ];

        for token in tokens {
            self.create_token(token).await?;
        }

        Ok(())
    }

    pub async fn seed_phrase_table(&self) -> Result<()> {
        let phrases = vec![
            Phrase {
                id: None,
                lang_id: self
                    .get_language_by_identifier("en_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                orthography_seq: vec!["hello".to_string(), "world".to_string()],
                definition: "placeholder".to_string(),
                notes: "a very familiar phrase! (for programmers)".to_string(),
                original_context: "".to_string(),
                status: TokenStatus::L5,
            },
            Phrase {
                id: None,
                lang_id: self
                    .get_language_by_identifier("en_demo".into())
                    .await?
                    .unwrap()
                    .id
                    .unwrap(),
                orthography_seq: vec!["world".to_string(), "wide".to_string(), "web".to_string()],
                definition: "placeholder".to_string(),
                notes: "I wonder what this is".to_string(),
                original_context: "".to_string(),
                status: TokenStatus::L3,
            },
        ];

        for phrase in phrases {
            self.create_phrase(phrase).await?;
        }

        Ok(())
    }

    pub async fn seed_document_table(&self) -> Result<()> {
        // Get language IDs
        let en_lang_id = self.get_language_by_identifier("en_demo".into()).await?.unwrap().id.unwrap();
        let fr_lang_id = self.get_language_by_identifier("fr_demo".into()).await?.unwrap().id.unwrap();
        let ja_lang_id = self.get_language_by_identifier("ja_demo".into()).await?.unwrap().id.unwrap();
        let zh_lang_id = self.get_language_by_identifier("zh-hant_demo".into()).await?.unwrap().id.unwrap();

        let mut documents = vec![
            // Original seed documents
            Document {
                id: None,
                lang_id: en_lang_id.clone(),
                title: "Toy Document Seed".to_string(),
                filename: "seed.md".to_string(),
                content: "This is a simple toy document for testing purposes. It contains some basic English text that can be used to test the language learning features.".to_string(),
                doc_type: "Text".to_string(),
                tags: vec!["demo".to_string(), "english".to_string(), "seed".to_string()],
                created_ts: Utc::now(),
                updated_ts: Utc::now(),
            },
            Document {
                id: None,
                lang_id: fr_lang_id.clone(),
                title: "Document Français Seed".to_string(),
                filename: "seed.md".to_string(),
                content: "Ceci est un document de démonstration en français. Il contient du texte simple pour tester les fonctionnalités d'apprentissage des langues. Bonjour le monde!".to_string(),
                doc_type: "Text".to_string(),
                tags: vec!["demo".to_string(), "français".to_string(), "seed".to_string()],
                created_ts: Utc::now(),
                updated_ts: Utc::now(),
            },
            Document {
                id: None,
                lang_id: ja_lang_id.clone(),
                title: "日本語の文書 Seed".to_string(),
                filename: "seed.md".to_string(),
                content: "これは日本語のデモ文書です。言語学習機能をテストするための簡単なテキストが含まれています。こんにちは世界！".to_string(),
                doc_type: "Text".to_string(),
                tags: vec!["demo".to_string(), "日本語".to_string(), "seed".to_string()],
                created_ts: Utc::now(),
                updated_ts: Utc::now(),
            },
        ];

        // Add documents from seed_content files using the macro
        documents.extend(vec![
            // English documents
            create_document_from_file!(
                en_lang_id,
                "toy.md",
                "Toy Example",
                "seed_content/en_demo/toy.txt",
                vec!["demo".to_string(), "english".to_string()]
            ),
            create_document_from_file!(
                en_lang_id,
                "macbeth excerpt.md",
                "Macbeth Excerpt",
                "seed_content/en_demo/macbeth_excerpt.txt",
                vec!["literature".to_string(), "shakespeare".to_string()]
            ),
            create_document_from_file!(
                en_lang_id,
                "long.md",
                "Long Document",
                "seed_content/en_demo/long.txt",
                vec!["demo".to_string(), "long".to_string()]
            ),
            create_document_from_file!(
                en_lang_id,
                "phrase_test.md",
                "Phrase Test",
                "seed_content/en_demo/phrase_test.txt",
                vec!["demo".to_string(), "test".to_string()]
            ),
            
            // French documents
            create_document_from_file!(
                fr_lang_id,
                "toy.md",
                "Exemple Jouet",
                "seed_content/fr_demo/toy.txt",
                vec!["demo".to_string(), "français".to_string()]
            ),
            create_document_from_file!(
                fr_lang_id,
                "les misérables excerpt.md",
                "Les Misérables Excerpt",
                "seed_content/fr_demo/les_miserables_excerpt.txt",
                vec!["literature".to_string(), "hugo".to_string()]
            ),
            create_document_from_file!(
                fr_lang_id,
                "inflection_lemma_test.md",
                "Inflection Lemma Test",
                "seed_content/fr_demo/inflection_lemma_test.txt",
                vec!["demo".to_string(), "test".to_string(), "grammar".to_string()]
            ),
            
            // Japanese documents
            create_document_from_file!(
                ja_lang_id,
                "rashonmon 1.md",
                "羅生門",
                "seed_content/ja_demo/rashonmon_1.txt",
                vec!["literature".to_string(), "akutagawa".to_string()]
            ),
            
            // Chinese documents
            create_document_from_file!(
                zh_lang_id,
                "diary of a madman.md",
                "狂人日記",
                "seed_content/zh-hant_demo/diary_of_a_madman.txt",
                vec!["literature".to_string(), "lu_xun".to_string()]
            ),
        ]);

        for document in documents {
            println!("Creating document: {:?}", document.title);
            self.create_document(document).await?;
        }

        Ok(())
    }

    pub async fn seed_all_tables(&self) -> Result<()> {
        self.seed_lang_table().await?;
        self.seed_vocab_table().await?;
        self.seed_phrase_table().await?;
        self.seed_document_table().await?;
        Ok(())
    }
}

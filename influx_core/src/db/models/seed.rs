use super::document::Document;
use super::phrase::Phrase;
use super::vocab::{Token, TokenStatus};
use super::DB;
use crate::db::models::lang::LanguageEntry;
use chrono::{DateTime, Utc};
use std::collections::HashMap;

use anyhow::Result;

fn create_document(
    lang_id: crate::db::InfluxResourceId,
    title: &str,
    content: &str,
    tags: Vec<String>,
) -> Document {
    Document {
        id: None,
        lang_id,
        title: title.to_string(),
        content: content.to_string(),
        doc_type: "Text".to_string(),
        tags,
        created_ts: Utc::now(),
        updated_ts: Utc::now(),
    }
}

impl DB {
    pub async fn seed_lang_table(&self) -> Result<HashMap<String, crate::db::InfluxResourceId>> {
        let languages = vec![
            LanguageEntry {
                id: None,
                code: "fr".to_string(),
                name: "French".to_string(),
                dicts: vec![
                    "dict:///###".to_string(),
                    "http://www.wordreference.com/fren/###".to_string(),
                ],
            },
            LanguageEntry {
                id: None,
                code: "en".to_string(),
                name: "English".to_string(),
                dicts: vec![
                    "dict:///###".to_string(),
                    "http://www.wordreference.com/enfr/###".to_string(),
                ],
            },
            LanguageEntry {
                id: None,
                code: "ja".to_string(),
                name: "Japanese".to_string(),
                dicts: vec!["dict:///###".to_string()],
            },
            LanguageEntry {
                id: None,
                code: "zh-hant".to_string(),
                name: "Mandarin".to_string(),
                dicts: vec!["dict:///###".to_string()],
            },
        ];

        let mut lang_map = HashMap::new();

        for language in languages {
            println!("Creating language: {:?}", language);
            let code = language.code.clone();
            let created_language = self.create_language(language).await?;
            let lang_id = created_language.id.unwrap();
            lang_map.insert(code, lang_id);
        }

        Ok(lang_map)
    }

    pub async fn seed_vocab_table(
        &self,
        lang_map: &HashMap<String, crate::db::InfluxResourceId>,
    ) -> Result<()> {
        let en_lang_id = lang_map.get("en").unwrap().clone();
        let fr_lang_id = lang_map.get("fr").unwrap().clone();

        let tokens = vec![
            Token::fancier_token(en_lang_id, "first", "1st", "ehh", TokenStatus::L5),
            Token::fancier_token(fr_lang_id.clone(), "voix", "voice", "vwa", TokenStatus::L5),
            Token::fancier_token(fr_lang_id.clone(), "parler", "speak", "", TokenStatus::L5),
            Token::fancier_token(
                fr_lang_id.clone(),
                "parlerez",
                "speak",
                "inflection of parler",
                TokenStatus::L5,
            ),
            Token::fancier_token(
                fr_lang_id.clone(),
                "habitaient",
                "lived",
                "inflection of habiter",
                TokenStatus::L5,
            ),
            Token::fancier_token(fr_lang_id.clone(), "cœur", "heart", "kœʀ", TokenStatus::L4),
            Token::fancier_token(fr_lang_id.clone(), "qui", "谁", "", TokenStatus::L3),
            Token::fancier_token(fr_lang_id.clone(), "au", "= à le, or", "", TokenStatus::L2),
            Token::fancier_token(
                fr_lang_id.clone(),
                "kiwis",
                "kiwi plural",
                "kiwi",
                TokenStatus::L1,
            ),
            Token::fancier_token(fr_lang_id, "les", "le -> les", "", TokenStatus::IGNORED),
        ];

        for token in tokens {
            self.create_token(token).await?;
        }

        Ok(())
    }

    pub async fn seed_phrase_table(
        &self,
        lang_map: &HashMap<String, crate::db::InfluxResourceId>,
    ) -> Result<()> {
        let en_lang_id = lang_map.get("en").unwrap().clone();

        let phrases = vec![
            Phrase {
                id: None,
                lang_id: en_lang_id.clone(),
                orthography_seq: vec!["hello".to_string(), "world".to_string()],
                definition: "placeholder".to_string(),
                notes: "a very familiar phrase! (for programmers)".to_string(),
                original_context: "".to_string(),
                status: TokenStatus::L5,
            },
            Phrase {
                id: None,
                lang_id: en_lang_id,
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

    pub async fn seed_document_table(
        &self,
        lang_map: &HashMap<String, crate::db::InfluxResourceId>,
    ) -> Result<()> {
        let en_lang_id = lang_map.get("en").unwrap().clone();
        let fr_lang_id = lang_map.get("fr").unwrap().clone();
        let ja_lang_id = lang_map.get("ja").unwrap().clone();
        let zh_lang_id = lang_map.get("zh-hant").unwrap().clone();

        let mut documents = vec![
            // Original seed documents
            create_document(
                en_lang_id.clone(),
                "Toy Document Seed",
                "This is a simple toy document for testing purposes. It contains some basic English text that can be used to test the language learning features.",
                vec!["demo".to_string(), "english".to_string(), "seed".to_string()],
            ),
            create_document(
                fr_lang_id.clone(),
                "Document Français Seed",
                "Ceci est un document de démonstration en français. Il contient du texte simple pour tester les fonctionnalités d'apprentissage des langues. Bonjour le monde!",
                vec!["demo".to_string(), "français".to_string(), "seed".to_string()],
            ),
            create_document(
                ja_lang_id.clone(),
                "日本語の文書 Seed",
                "これは日本語のデモ文書です。言語学習機能をテストするための簡単なテキストが含まれています。こんにちは世界！",
                vec!["demo".to_string(), "日本語".to_string(), "seed".to_string()],
            ),
        ];

        // Add documents from seed_content files
        documents.extend(vec![
            // English documents
            create_document(
                en_lang_id.clone(),
                "Toy Example",
                include_str!("seed_content/en_demo/toy.txt"),
                vec!["demo".to_string(), "english".to_string()],
            ),
            create_document(
                en_lang_id.clone(),
                "Macbeth Excerpt",
                include_str!("seed_content/en_demo/macbeth_excerpt.txt"),
                vec!["literature".to_string(), "shakespeare".to_string()],
            ),
            create_document(
                en_lang_id.clone(),
                "Long Document",
                include_str!("seed_content/en_demo/long.txt"),
                vec!["demo".to_string(), "long".to_string()],
            ),
            create_document(
                en_lang_id.clone(),
                "Phrase Test",
                include_str!("seed_content/en_demo/phrase_test.txt"),
                vec!["demo".to_string(), "test".to_string()],
            ),
            // French documents
            create_document(
                fr_lang_id.clone(),
                "Exemple Jouet",
                include_str!("seed_content/fr_demo/toy.txt"),
                vec!["demo".to_string(), "français".to_string()],
            ),
            create_document(
                fr_lang_id.clone(),
                "Les Misérables Excerpt",
                include_str!("seed_content/fr_demo/les_miserables_excerpt.txt"),
                vec!["literature".to_string(), "hugo".to_string()],
            ),
            create_document(
                fr_lang_id.clone(),
                "Inflection Lemma Test",
                include_str!("seed_content/fr_demo/inflection_lemma_test.txt"),
                vec![
                    "demo".to_string(),
                    "test".to_string(),
                    "grammar".to_string(),
                ],
            ),
            // Japanese documents
            create_document(
                ja_lang_id.clone(),
                "羅生門",
                include_str!("seed_content/ja_demo/rashonmon_1.txt"),
                vec!["literature".to_string(), "akutagawa".to_string()],
            ),
            // Chinese documents
            create_document(
                zh_lang_id.clone(),
                "狂人日記",
                include_str!("seed_content/zh-hant_demo/diary_of_a_madman.txt"),
                vec!["literature".to_string(), "lu_xun".to_string()],
            ),
        ]);

        for document in documents {
            println!("Creating document: {:?}", document.title);
            self.create_document(document).await?;
        }

        Ok(())
    }

    pub async fn seed_all_tables(&self) -> Result<()> {
        let lang_map = self.seed_lang_table().await?;
        self.seed_vocab_table(&lang_map).await?;
        self.seed_phrase_table(&lang_map).await?;
        self.seed_document_table(&lang_map).await?;
        Ok(())
    }
}

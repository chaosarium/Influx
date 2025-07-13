use super::phrase::Phrase;
use super::vocab::{Token, TokenStatus};
use super::DB;
use crate::db::models::lang::LanguageEntry;

use anyhow::Result;

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

    pub async fn seed_all_tables(&self) -> Result<()> {
        self.seed_lang_table().await?;
        self.seed_vocab_table().await?;
        self.seed_phrase_table().await?;
        Ok(())
    }
}

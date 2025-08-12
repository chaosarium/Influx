use super::document::{Document, DocumentCreateRequest};
use super::phrase::Phrase;
use super::vocab::{Token, TokenStatus};
use super::DB;
use crate::db::models::lang::{Language, ParserConfig};
use crate::db::InfluxResourceId;
use chrono::Utc;
use std::collections::HashMap;

use anyhow::Result;
use tracing::{debug, info};

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

fn create_language(
    name: &str,
    deepl_source_lang: &str,
    spacy_model: Option<&str>,
    parser: &str,
) -> Language {
    let mut parser_args = HashMap::new();
    if let Some(model) = spacy_model {
        parser_args.insert("spacy_model".to_string(), model.to_string());
    }

    Language {
        id: None,
        name: name.to_string(),
        dicts: vec!["dict:///###".to_string()],
        tts_rate: None,
        tts_pitch: None,
        tts_voice: None,
        deepl_source_lang: Some(deepl_source_lang.to_uppercase()),
        deepl_target_lang: Some("EN".to_string()),
        parser_config: ParserConfig {
            which_parser: parser.to_string(),
            parser_args,
        },
    }
}

fn create_document(
    lang_id: InfluxResourceId,
    title: &str,
    content: &str,
    tags: Vec<&str>,
) -> DocumentCreateRequest {
    DocumentCreateRequest {
        lang_id,
        title: title.to_string(),
        content: content.to_string(),
        doc_type: "Text".to_string(),
        tags: tags.iter().map(|s| s.to_string()).collect(),
    }
}

fn create_token(
    lang_id: InfluxResourceId,
    orthography: &str,
    definition: &str,
    notes: &str,
    status: TokenStatus,
) -> Token {
    Token::fancier_token(lang_id, orthography, definition, notes, status)
}

fn create_phrase(
    lang_id: InfluxResourceId,
    words: Vec<&str>,
    definition: &str,
    notes: &str,
    context: &str,
    status: TokenStatus,
) -> Phrase {
    Phrase {
        id: None,
        lang_id,
        orthography_seq: words.iter().map(|s| s.to_string()).collect(),
        definition: definition.to_string(),
        notes: notes.to_string(),
        original_context: context.to_string(),
        status,
    }
}

// =============================================================================
// MAIN SEED FUNCTION
// =============================================================================

impl DB {
    pub async fn seed_all_tables(&self) -> Result<()> {
        info!("🌱 Starting database seeding process");

        // =============================================================================
        // LANGUAGES
        // =============================================================================
        info!("📚 Seeding languages table");

        let en_lang = self
            .create_language(create_language(
                "English",
                "EN",
                Some("en_core_web_sm"),
                "base_spacy",
            ))
            .await?;
        let fr_lang = self
            .create_language(create_language(
                "French",
                "FR",
                Some("fr_core_news_sm"),
                "base_spacy",
            ))
            .await?;
        let ja_lang = self
            .create_language(create_language("Japanese", "JA", None, "enhanced_japanese"))
            .await?;
        let zh_lang = self
            .create_language(create_language(
                "Mandarin",
                "ZH",
                Some("zh_core_web_sm"),
                "base_spacy",
            ))
            .await?;

        let en_id = en_lang.id.unwrap();
        let fr_id = fr_lang.id.unwrap();
        let ja_id = ja_lang.id.unwrap();
        let zh_id = zh_lang.id.unwrap();

        // =============================================================================
        // DOCUMENTS
        // =============================================================================
        info!("📄 Seeding documents table");

        let documents = vec![
            // Simple demo documents
            create_document(en_id.clone(), "Toy Document Seed", 
                "This is a simple toy document for testing purposes. It contains some basic English text that can be used to test the language learning features.",
                vec!["demo", "english", "seed"]),
            create_document(fr_id.clone(), "Document Français Seed",
                "Ceci est un document de démonstration en français. Il contient du texte simple pour tester les fonctionnalités d'apprentissage des langues. Bonjour le monde!",
                vec!["demo", "français", "seed"]),
            create_document(ja_id.clone(), "日本語の文書 Seed",
                "これは日本語のデモ文書です。言語学習機能をテストするための簡単なテキストが含まれています。こんにちは世界！",
                vec!["demo", "日本語", "seed"]),

            // Documents from seed content files
            create_document(en_id.clone(), "Toy Example", include_str!("seed_content/en_demo/toy.txt"), vec!["demo", "english"]),
            create_document(en_id.clone(), "Macbeth Excerpt", include_str!("seed_content/en_demo/macbeth_excerpt.txt"), vec!["literature", "shakespeare"]),
            create_document(en_id.clone(), "Long Document", include_str!("seed_content/en_demo/long.txt"), vec!["demo", "long"]),
            create_document(en_id.clone(), "Phrase Test", include_str!("seed_content/en_demo/phrase_test.txt"), vec!["demo", "test"]),

            create_document(fr_id.clone(), "Exemple Jouet", include_str!("seed_content/fr_demo/toy.txt"), vec!["demo", "français"]),
            create_document(fr_id.clone(), "Les Misérables Excerpt", include_str!("seed_content/fr_demo/les_miserables_excerpt.txt"), vec!["literature", "hugo"]),
            create_document(fr_id.clone(), "Inflection Lemma Test", include_str!("seed_content/fr_demo/inflection_lemma_test.txt"), vec!["demo", "test", "grammar"]),

            create_document(ja_id.clone(), "羅生門", include_str!("seed_content/ja_demo/rashonmon_1.txt"), vec!["literature", "akutagawa"]),
            create_document(zh_id.clone(), "狂人日記", include_str!("seed_content/zh-hant_demo/diary_of_a_madman.txt"), vec!["literature", "lu_xun"]),
        ];

        for document in documents {
            debug!(title = %document.title, lang_id = ?document.lang_id, "Creating document");
            self.create_document(document).await?;
        }

        // =============================================================================
        // VOCABULARY (TOKENS)
        // =============================================================================
        info!("📝 Seeding vocabulary table");

        let tokens = vec![
            // English tokens from documents
            create_token(
                en_id.clone(),
                "hello",
                "greeting",
                "common greeting",
                TokenStatus::L5,
            ),
            create_token(en_id.clone(), "world", "the earth", "", TokenStatus::L5),
            create_token(en_id.clone(), "quick", "fast", "", TokenStatus::L4),
            create_token(
                en_id.clone(),
                "brown",
                "color",
                "dark orange",
                TokenStatus::L4,
            ),
            create_token(
                en_id.clone(),
                "fox",
                "animal",
                "small mammal",
                TokenStatus::L3,
            ),
            create_token(
                en_id.clone(),
                "jumps",
                "verb",
                "leaps over",
                TokenStatus::L3,
            ),
            create_token(
                en_id.clone(),
                "lazy",
                "adjective",
                "not active",
                TokenStatus::L3,
            ),
            create_token(
                en_id.clone(),
                "dog",
                "animal",
                "domestic animal",
                TokenStatus::L5,
            ),
            create_token(en_id.clone(), "programme", "", "", TokenStatus::L2),
            create_token(
                en_id.clone(),
                "wrote",
                "write",
                "past tense of write",
                TokenStatus::L4,
            ),
            create_token(
                en_id.clone(),
                "first",
                "1st",
                "ordinal number",
                TokenStatus::L5,
            ),
            create_token(
                en_id.clone(),
                "wide",
                "broad",
                "having great width",
                TokenStatus::L4,
            ),
            create_token(
                en_id.clone(),
                "web",
                "network",
                "interconnected system",
                TokenStatus::L3,
            ),
            create_token(
                en_id.clone(),
                "road",
                "street",
                "path for vehicles",
                TokenStatus::L4,
            ),
            create_token(
                en_id.clone(),
                "longer",
                "more long",
                "comparative of long",
                TokenStatus::L3,
            ),
            // French tokens from documents
            create_token(fr_id.clone(), "voix", "voice", "vwa", TokenStatus::L5),
            create_token(fr_id.clone(), "ambiguë", "ambiguous", "", TokenStatus::L2),
            create_token(fr_id.clone(), "cœur", "heart", "kœʀ", TokenStatus::L4),
            create_token(
                fr_id.clone(),
                "zéphyr",
                "zephyr",
                "gentle breeze",
                TokenStatus::L1,
            ),
            create_token(
                fr_id.clone(),
                "préfère",
                "prefers",
                "3rd person singular",
                TokenStatus::L3,
            ),
            create_token(fr_id.clone(), "jattes", "bowls", "", TokenStatus::L1),
            create_token(fr_id.clone(), "kiwis", "kiwis", "plural", TokenStatus::L2),
            create_token(fr_id.clone(), "comme", "like/as", "", TokenStatus::L5),
            create_token(fr_id.clone(), "même", "same/even", "", TokenStatus::L4),
            create_token(fr_id.clone(), "monde", "world", "le monde", TokenStatus::L5),
            create_token(fr_id.clone(), "omelette", "omelet", "", TokenStatus::L3),
            create_token(fr_id.clone(), "rendre", "to render", "", TokenStatus::L3),
            create_token(
                fr_id.clone(),
                "croissant",
                "croissant",
                "pastry",
                TokenStatus::L4,
            ),
            create_token(
                fr_id.clone(),
                "pouvoir",
                "power/can",
                "noun or verb",
                TokenStatus::L4,
            ),
            create_token(
                fr_id.clone(),
                "grève",
                "strike",
                "labor strike",
                TokenStatus::L2,
            ),
            create_token(
                fr_id.clone(),
                "meilleur",
                "better/best",
                "comparative",
                TokenStatus::L3,
            ),
            create_token(
                fr_id.clone(),
                "baguette",
                "baguette",
                "French bread",
                TokenStatus::L4,
            ),
            create_token(
                fr_id.clone(),
                "révolution",
                "revolution",
                "political change",
                TokenStatus::L3,
            ),
            create_token(
                fr_id.clone(),
                "saucisson",
                "sausage",
                "dry sausage",
                TokenStatus::L2,
            ),
            create_token(
                fr_id.clone(),
                "manger",
                "to eat",
                "infinitive verb",
                TokenStatus::L5,
            ),
            create_token(
                fr_id.clone(),
                "très",
                "very",
                "adverb intensifier",
                TokenStatus::L5,
            ),
            // Basic particles and common words
            create_token(
                fr_id.clone(),
                "qui",
                "who/which",
                "relative pronoun",
                TokenStatus::L5,
            ),
            create_token(
                fr_id.clone(),
                "au",
                "= à le",
                "contraction",
                TokenStatus::L5,
            ),
            create_token(
                fr_id.clone(),
                "les",
                "the (plural)",
                "definite article",
                TokenStatus::L5,
            ),
            create_token(
                fr_id.clone(),
                "du",
                "= de le",
                "contraction",
                TokenStatus::L5,
            ),
            create_token(fr_id.clone(), "à", "to/at", "preposition", TokenStatus::L5),
            create_token(
                fr_id.clone(),
                "la",
                "the (fem)",
                "definite article",
                TokenStatus::L5,
            ),
            create_token(
                fr_id.clone(),
                "le",
                "the (masc)",
                "definite article",
                TokenStatus::L5,
            ),
        ];

        for token in tokens {
            self.create_token(token).await?;
        }

        // =============================================================================
        // PHRASES
        // =============================================================================
        info!("🔗 Seeding phrases table");

        let phrases = vec![
            // English phrases from documents
            create_phrase(
                en_id.clone(),
                vec!["hello", "world"],
                "common greeting phrase",
                "very familiar phrase for programmers",
                "Hello world.",
                TokenStatus::L5,
            ),
            create_phrase(
                en_id.clone(),
                vec!["world", "wide", "web"],
                "the internet",
                "global information system",
                "world wide web",
                TokenStatus::L3,
            ),
            create_phrase(
                en_id.clone(),
                vec!["quick", "brown", "fox"],
                "pangram animal",
                "from typing practice sentence",
                "The quick brown fox",
                TokenStatus::L2,
            ),
            create_phrase(
                en_id.clone(),
                vec!["lazy", "dog"],
                "inactive canine",
                "from pangram sentence",
                "the lazy dog",
                TokenStatus::L3,
            ),
            create_phrase(
                en_id.clone(),
                vec!["test", "result"],
                "outcome of testing",
                "common in programming",
                "test result: ok",
                TokenStatus::L4,
            ),
            create_phrase(
                en_id.clone(),
                vec!["wide", "road"],
                "broad street",
                "describing road width",
                "A wide road",
                TokenStatus::L3,
            ),
            // French phrases from documents
            create_phrase(
                fr_id.clone(),
                vec!["voix", "ambiguë"],
                "ambiguous voice",
                "unclear speech",
                "voix ambiguë",
                TokenStatus::L2,
            ),
            create_phrase(
                fr_id.clone(),
                vec!["jattes", "de", "kiwis"],
                "bowls of kiwis",
                "fruit containers",
                "les jattes de kiwis",
                TokenStatus::L1,
            ),
            create_phrase(
                fr_id.clone(),
                vec!["comme", "même"],
                "like even/anyway",
                "common colloquial expression",
                "Comme même",
                TokenStatus::L3,
            ),
            create_phrase(
                fr_id.clone(),
                vec!["très", "manger"],
                "eat a lot",
                "eating intensively",
                "très manger",
                TokenStatus::L4,
            ),
            create_phrase(
                fr_id.clone(),
                vec!["baguette", "du"],
                "baguette of the",
                "bread reference",
                "baguette du",
                TokenStatus::L3,
            ),
        ];

        for phrase in phrases {
            self.create_phrase(phrase).await?;
        }

        info!("✅ Database seeding completed successfully");
        Ok(())
    }
}

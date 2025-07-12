#![allow(unused_imports, unused_must_use)]
use core::panic;
use elm_rs::{Elm, ElmDecode, ElmEncode, ElmQuery, ElmQueryField};
use std::collections::{BTreeMap, HashMap, HashSet};

use anyhow;
use indoc::indoc;
use serde::{Deserialize, Serialize};
use std::collections::VecDeque;
use std::env;
use std::path::PathBuf;
use ts_rs::TS;

use crate::db::models::phrase::Phrase;
use crate::db::models::vocab::Token;
use crate::db::InfluxResourceId;
use crate::utils::trie::Trie;
pub mod phrase_fitting;
use reqwest::Client;
use serde_json::json;
use serde_json::value::Value;

// TODO pull token_dict and phrase_dict out of AnnotatedDocument
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub struct AnnotatedDocument {
    pub text: String,
    pub constituents: Vec<DocumentConstituent>,
    pub num_sentences: usize,
    pub num_tokens: usize,

    pub orthography_set: HashSet<String>,
    pub lemma_set: HashSet<String>,

    pub token_dict: Option<HashMap<String, Token>>,
    // pub phrase_dict: Option<HashMap<Vec<String>, Phrase>>,
    // JavaScript doesn't support HashMaps with non-string keys, sad. We'll concat the keys into a string for now.
    pub phrase_dict: Option<HashMap<String, Phrase>>,
}

impl AnnotatedDocument {
    pub fn set_token_dict(&mut self, token_dict: HashMap<String, Token>) {
        self.token_dict = Some(token_dict);
    }
}

#[deprecated]
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub enum DocumentConstituent {
    Sentence {
        id: usize, // 0-indexed
        text: String,
        start_char: usize,
        end_char: usize,
        constituents: Vec<SentenceConstituent>,
    },
    DocumentWhitespace {
        text: String,
        start_char: usize,
        end_char: usize,
    },
}

#[deprecated]
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub enum SentenceConstituent {
    MultiwordToken {
        sentence_id: usize,
        ids: Vec<usize>,
        text: String,
        orthography: String,
        start_char: usize,
        end_char: usize,
        shadowed: bool,
        shadows: Vec<SentenceConstituent>,
    },
    SubwordToken {
        sentence_id: usize,
        id: usize, // 1-indexed
        text: String,
        orthography: String,
        lemma: String,
        shadowed: bool,
        shadows: Vec<SentenceConstituent>,
    },
    SingleToken {
        sentence_id: usize,
        id: usize, // 1-indexed
        text: String,
        orthography: String,
        lemma: String,
        start_char: usize,
        end_char: usize,
        shadowed: bool,
        shadows: Vec<SentenceConstituent>,
    },
    SentenceWhitespace {
        text: String,
        orthography: String, // trivially the same as text, if things are working
        start_char: usize,
        end_char: usize,
        shadowed: bool,
        shadows: Vec<SentenceConstituent>,
    },
    PhraseToken {
        sentence_id: usize,
        text: String,
        /// lowercase, with each token orthography separated by a space, to support JavaScript key type.
        normalised_orthography: String,
        start_char: usize,
        end_char: usize,
        shadowed: bool,
        shadows: Vec<SentenceConstituent>,
    },
}

/// Segment attribute
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub struct SegAttribute {
    lemma: Option<String>,
    is_punctuation: Option<bool>,
    upos: Option<String>,
    xpos: Option<String>,
    dependency: Option<(usize, String)>, // (parent idx, relation)
    misc: HashMap<String, String>
}

/// Document segment variants.
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub enum DocSegVariants {
    Sentence {
        segments: Vec<SentSegV2>,
    },
    DocumentWhitespace,
}

/// Document segment
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub struct DocSegV2 {
    text: String,
    start_char: usize,
    end_char: usize,
    inner: DocSegVariants, 
}

/// Sentence segment variants
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub enum SentSegVariants {
    TokenCst {
        idx : usize,
        orthography: String,
    }, 
    PhraseCst {
        /// lowercase, with each token orthography separated by a space, to make JavaScript type work out.
        normalised_orthography: String,
        components: Vec<SentSegV2>,
    }, 
    WhitespaceSeg
}

/// Sentence segment
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub struct SentSegV2 {
    sentence_idx: usize, 
    text: String,
    start_char: usize,
    end_char: usize,
    inner: SentSegVariants, 
    attributes: SegAttribute,
}

#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub struct AnnotatedDocV2 {
    pub text: String,
    pub segments: Vec<DocSegV2>,

    pub orthography_set: HashSet<String>,
    pub lemma_set: HashSet<String>,

    pub token_dict: Option<HashMap<String, Token>>,
    // pub phrase_dict: Option<HashMap<Vec<String>, Phrase>>,
    // JavaScript doesn't support HashMaps with non-string keys, sad. We'll concat the keys into a string for now.
    pub phrase_dict: Option<HashMap<String, Phrase>>,
}




impl SentenceConstituent {
    fn mark_shadowed(&mut self) {
        match self {
            SentenceConstituent::MultiwordToken { shadowed, .. } => *shadowed = true,
            SentenceConstituent::SubwordToken { shadowed, .. } => *shadowed = true,
            SentenceConstituent::SingleToken { shadowed, .. } => *shadowed = true,
            SentenceConstituent::SentenceWhitespace { shadowed, .. } => *shadowed = true,
            SentenceConstituent::PhraseToken { shadowed, .. } => *shadowed = true,
        }
    }

    fn push_shadow(&mut self, shadow: SentenceConstituent) {
        match self {
            SentenceConstituent::MultiwordToken { shadows, .. } => shadows.push(shadow),
            SentenceConstituent::SubwordToken { shadows, .. } => shadows.push(shadow),
            SentenceConstituent::SingleToken { shadows, .. } => shadows.push(shadow),
            SentenceConstituent::SentenceWhitespace { shadows, .. } => shadows.push(shadow),
            SentenceConstituent::PhraseToken { shadows, .. } => shadows.push(shadow),
        }
    }

    fn get_text(&self) -> String {
        match self {
            SentenceConstituent::MultiwordToken { text, .. } => text.clone(),
            SentenceConstituent::SubwordToken { text, .. } => text.clone(),
            SentenceConstituent::SingleToken { text, .. } => text.clone(),
            SentenceConstituent::SentenceWhitespace { text, .. } => text.clone(),
            SentenceConstituent::PhraseToken { text, .. } => text.clone(),
        }
    }
    fn has_start_and_end(&self) -> bool {
        match self {
            SentenceConstituent::MultiwordToken { .. } => true,
            SentenceConstituent::SubwordToken { .. } => false,
            SentenceConstituent::SingleToken { .. } => true,
            SentenceConstituent::SentenceWhitespace { .. } => true,
            SentenceConstituent::PhraseToken { .. } => true,
        }
    }
    fn get_start_char(&self) -> usize {
        match self {
            SentenceConstituent::MultiwordToken { start_char, .. } => *start_char,
            SentenceConstituent::SubwordToken { .. } => panic!("SubwordToken has no start_char"),
            SentenceConstituent::SingleToken { start_char, .. } => *start_char,
            SentenceConstituent::SentenceWhitespace { start_char, .. } => *start_char,
            SentenceConstituent::PhraseToken { start_char, .. } => *start_char,
        }
    }
    fn get_end_char(&self) -> usize {
        match self {
            SentenceConstituent::MultiwordToken { end_char, .. } => *end_char,
            SentenceConstituent::SubwordToken { .. } => panic!("SubwordToken has no end_char"),
            SentenceConstituent::SingleToken { end_char, .. } => *end_char,
            SentenceConstituent::SentenceWhitespace { end_char, .. } => *end_char,
            SentenceConstituent::PhraseToken { end_char, .. } => *end_char,
        }
    }
}



/// given text and language, return a tokenised document before phrase fitting
pub async fn tokenise_pipeline(
    text: &str,
    language_code: String,
) -> anyhow::Result<AnnotatedDocV2> {

    let client = Client::new();
    let url = format!("http://127.0.0.1:3001/tokeniser/{}", language_code);
    let payload = json!({
        "text": text
    });
    let response = client.post(&url).json(&payload).send().await?;

    dbg!(&response);
    if response.status().is_success() {
        println!("Request to NLP server succeeded");
        let res_json: AnnotatedDocV2 = response.json::<AnnotatedDocV2>().await?;
        dbg!(&res_json);

        // let annotated_document: AnnotatedDocument = res_json;
        Ok(res_json)
    } else {
        Err(anyhow::anyhow!("Request to NLP server failed"))
    }
}

pub fn phrase_fit_pipeline(
    document: AnnotatedDocument,
    potential_phrases: Trie<String, Phrase>,
) -> AnnotatedDocument {
    dbg!(&potential_phrases);

    let mut phrase_dict: HashMap<String, Phrase> = HashMap::new();
    let fitted_doc_cst: Vec<DocumentConstituent> = document
        .constituents
        .into_iter()
        .map(|document_constituent| {
            match document_constituent {
                DocumentConstituent::DocumentWhitespace {
                    text,
                    start_char,
                    end_char,
                } => DocumentConstituent::DocumentWhitespace {
                    text,
                    start_char,
                    end_char,
                },
                DocumentConstituent::Sentence {
                    id,
                    text,
                    start_char,
                    end_char,
                    constituents,
                } => {
                    let original_constituents = constituents.clone();

                    let lex_constituents = constituents
                        .iter()
                        .enumerate()
                        .filter_map(|(i, x)| match x {
                            SentenceConstituent::SingleToken { orthography, .. } => {
                                Some((i, orthography.clone()))
                            }
                            SentenceConstituent::MultiwordToken { orthography, .. } => {
                                Some((i, orthography.clone()))
                            }
                            _ => None,
                        })
                        .collect::<Vec<(usize, String)>>();
                    let lex_constituents_orthographies = lex_constituents
                        .iter()
                        .map(|(_, orthography)| orthography.clone())
                        .collect::<Vec<String>>();
                    let lex_phrase_slices_indices = phrase_fitting::dp_best_fit(
                        lex_constituents_orthographies.clone(),
                        &potential_phrases,
                    );
                    let lex_phrase_slices_indices = lex_phrase_slices_indices
                        .iter()
                        .filter(|(start, end)| {
                            // remove trivial phrases
                            match end - start {
                                1 => false,
                                _ => true,
                            }
                        })
                        .collect::<Vec<&(usize, usize)>>();
                    if lex_phrase_slices_indices.len() == 0 {
                        // no phrase
                        return DocumentConstituent::Sentence {
                            id,
                            text,
                            start_char,
                            end_char,
                            constituents: original_constituents,
                        };
                    }
                    let phrase_slices = lex_phrase_slices_indices
                        .iter()
                        .map(|(lex_start, lex_end)| {
                            let start = lex_constituents[*lex_start].0;
                            let end = {
                                match lex_end {
                                    0 => 0,
                                    _ => lex_constituents[*lex_end - 1].0 + 1,
                                }
                            };
                            ((start, end), (*lex_start, *lex_end))
                        })
                        .collect::<Vec<((usize, usize), (usize, usize))>>();

                    let phrase_non_phrase_sentence = phrase_slices
                        .iter()
                        .enumerate()
                        .map(|(i, ((start, end), (lex_start, lex_end)))| {
                            if i == 0 && phrase_slices.len() > 1 {
                                // first
                                vec![
                                    ((0, *start), None, false),
                                    ((*start, *end), Some((*lex_start, *lex_end)), true),
                                    ((*end, phrase_slices[i + 1].0 .0), None, false),
                                ]
                            } else if i == 0 && phrase_slices.len() <= 1 {
                                // first and last
                                vec![
                                    ((0, *start), None, false),
                                    ((*start, *end), Some((*lex_start, *lex_end)), true),
                                    ((*end, original_constituents.len()), None, false),
                                ]
                            } else if i == phrase_slices.len() - 1 {
                                // last
                                vec![
                                    ((*start, *end), Some((*lex_start, *lex_end)), true),
                                    ((*end, original_constituents.len()), None, false),
                                ]
                            } else {
                                vec![
                                    ((*start, *end), Some((*lex_start, *lex_end)), true),
                                    ((*end, phrase_slices[i + 1].0 .0), None, false),
                                ]
                            }
                        })
                        .flatten()
                        .map(
                            |((start, end), lex_loc, is_phrase)| match (is_phrase, lex_loc) {
                                (false, None) => {
                                    let non_phrase_tokens =
                                        original_constituents[start..end].to_vec();
                                    non_phrase_tokens
                                }
                                (true, Some((lex_start, lex_end))) => {
                                    let phrase = potential_phrases
                                        .search_for_payload(
                                            lex_constituents_orthographies[lex_start..lex_end]
                                                .to_vec(),
                                        )
                                        .1
                                        .unwrap();
                                    phrase_dict.insert(
                                        lex_constituents_orthographies[lex_start..lex_end]
                                            .join(" "),
                                        phrase.clone(),
                                    );
                                    let phrase_start_char =
                                        original_constituents[start].get_start_char();
                                    let phrase_end_char =
                                        original_constituents[end - 1].get_end_char();
                                    let phrase_text = original_constituents[start..end]
                                        .iter()
                                        .map(|x| x.get_text())
                                        .collect::<Vec<String>>()
                                        .join("");

                                    let mut shadowned_tokens =
                                        original_constituents[start..end].to_vec();
                                    shadowned_tokens.iter_mut().for_each(|x| {
                                        x.mark_shadowed();
                                    });
                                    vec![SentenceConstituent::PhraseToken {
                                        sentence_id: id,
                                        text: phrase_text,
                                        normalised_orthography: lex_constituents_orthographies
                                            [lex_start..lex_end]
                                            .join(" "),
                                        start_char: phrase_start_char,
                                        end_char: phrase_end_char,
                                        shadowed: false,
                                        shadows: shadowned_tokens,
                                    }]
                                }
                                _ => panic!("unreachable"),
                            },
                        )
                        .flatten()
                        .collect::<Vec<SentenceConstituent>>();

                    DocumentConstituent::Sentence {
                        id,
                        text,
                        start_char,
                        end_char,
                        constituents: phrase_non_phrase_sentence,
                    }
                }
            }
        })
        .collect();

    AnnotatedDocument {
        text: document.text,
        constituents: fitted_doc_cst,
        num_sentences: document.num_sentences,
        num_tokens: document.num_tokens,
        orthography_set: document.orthography_set,
        lemma_set: document.lemma_set,
        token_dict: document.token_dict,
        phrase_dict: Some(phrase_dict),
    }
}

#[cfg(test)]
mod tests {
    use axum::body::HttpBody;

    use super::*;

    #[tokio::test]
    async fn test_tokenise_pipeline_small1() {
        const TEXT: &str = "Hello world! Hi!";

        let res = tokenise_pipeline(TEXT, "en".to_string()).await;
        assert!(res.is_ok());
        let res = res.unwrap();
        assert_eq!(
            res,
            AnnotatedDocument {
                text: "Hello world! Hi!".to_string(),
                constituents: vec![
                    DocumentConstituent::Sentence {
                        id: 0,
                        text: "Hello world!".to_string(),
                        start_char: 0,
                        end_char: 12,
                        constituents: vec![
                            SentenceConstituent::SingleToken {
                                sentence_id: 0,
                                id: 1,
                                text: "Hello".to_string(),
                                orthography: "hello".to_string(),
                                lemma: "hello".to_string(),
                                start_char: 0,
                                end_char: 5,
                                shadowed: false,
                                shadows: vec![],
                            },
                            SentenceConstituent::SentenceWhitespace {
                                text: " ".to_string(),
                                orthography: " ".to_string(),
                                start_char: 5,
                                end_char: 6,
                                shadowed: false,
                                shadows: vec![],
                            },
                            SentenceConstituent::SingleToken {
                                sentence_id: 0,
                                id: 2,
                                text: "world".to_string(),
                                orthography: "world".to_string(),
                                lemma: "world".to_string(),
                                start_char: 6,
                                end_char: 11,
                                shadowed: false,
                                shadows: vec![],
                            },
                            SentenceConstituent::SingleToken {
                                sentence_id: 0,
                                id: 3,
                                text: "!".to_string(),
                                orthography: "!".to_string(),
                                lemma: "!".to_string(),
                                start_char: 11,
                                end_char: 12,
                                shadowed: false,
                                shadows: vec![],
                            },
                        ],
                    },
                    DocumentConstituent::DocumentWhitespace {
                        text: " ".to_string(),
                        start_char: 12,
                        end_char: 13,
                    },
                    DocumentConstituent::Sentence {
                        id: 1,
                        text: "Hi!".to_string(),
                        start_char: 13,
                        end_char: 16,
                        constituents: vec![
                            SentenceConstituent::SingleToken {
                                sentence_id: 1,
                                id: 1,
                                text: "Hi".to_string(),
                                orthography: "hi".to_string(),
                                lemma: "hi".to_string(),
                                start_char: 13,
                                end_char: 15,
                                shadowed: false,
                                shadows: vec![],
                            },
                            SentenceConstituent::SingleToken {
                                sentence_id: 1,
                                id: 2,
                                text: "!".to_string(),
                                orthography: "!".to_string(),
                                lemma: "!".to_string(),
                                start_char: 15,
                                end_char: 16,
                                shadowed: false,
                                shadows: vec![],
                            },
                        ],
                    },
                ],
                num_sentences: 2,
                num_tokens: 5,
                lemma_set: [
                    "hello".to_string(),
                    "world".to_string(),
                    "hi".to_string(),
                    "!".to_string()
                ]
                .iter()
                .cloned()
                .collect::<HashSet<String>>(),
                orthography_set: [
                    "hello".to_string(),
                    "world".to_string(),
                    "hi".to_string(),
                    "!".to_string()
                ]
                .iter()
                .cloned()
                .collect::<HashSet<String>>(),
                token_dict: None,
                phrase_dict: None,
            }
        );
    }

    #[tokio::test]
    async fn test_tokenise_pipeline_small2() {
        const TEXT: &str = "Let's  go.";

        let res = tokenise_pipeline(TEXT, "en".to_string()).await;
        assert!(res.is_ok());
        let res = res.unwrap();
        assert_eq!(
            res,
            AnnotatedDocument {
                text: "Let's  go.".to_string(),
                constituents: vec![DocumentConstituent::Sentence {
                    id: 0,
                    text: "Let's  go.".to_string(),
                    start_char: 0,
                    end_char: 10,
                    constituents: vec![
                        SentenceConstituent::MultiwordToken {
                            sentence_id: 0,
                            ids: vec![1, 2,],
                            text: "Let's".to_string(),
                            orthography: "let's".to_string(),
                            start_char: 0,
                            end_char: 5,
                            shadowed: false,
                            shadows: vec![
                                SentenceConstituent::SubwordToken {
                                    sentence_id: 0,
                                    id: 1,
                                    text: "Let".to_string(),
                                    orthography: "let".to_string(),
                                    lemma: "let".to_string(),
                                    shadowed: true,
                                    shadows: vec![],
                                },
                                SentenceConstituent::SubwordToken {
                                    sentence_id: 0,
                                    id: 2,
                                    text: "'s".to_string(),
                                    orthography: "'s".to_string(),
                                    lemma: "'s".to_string(),
                                    shadowed: true,
                                    shadows: vec![],
                                },
                            ]
                        },
                        SentenceConstituent::SentenceWhitespace {
                            text: "  ".to_string(),
                            orthography: "  ".to_string(),
                            start_char: 5,
                            end_char: 7,
                            shadowed: false,
                            shadows: vec![],
                        },
                        SentenceConstituent::SingleToken {
                            sentence_id: 0,
                            id: 3,
                            text: "go".to_string(),
                            orthography: "go".to_string(),
                            lemma: "go".to_string(),
                            start_char: 7,
                            end_char: 9,
                            shadowed: false,
                            shadows: vec![],
                        },
                        SentenceConstituent::SingleToken {
                            sentence_id: 0,
                            id: 4,
                            text: ".".to_string(),
                            orthography: ".".to_string(),
                            lemma: ".".to_string(),
                            start_char: 9,
                            end_char: 10,
                            shadowed: false,
                            shadows: vec![],
                        },
                    ],
                },],
                num_sentences: 1,
                num_tokens: 3,
                orthography_set: [
                    "go".to_string(),
                    ".".to_string(),
                    "let's".to_string(),
                    "let".to_string(),
                    "'s".to_string()
                ]
                .iter()
                .cloned()
                .collect::<HashSet<String>>(),
                lemma_set: [
                    "go".to_string(),
                    ".".to_string(),
                    "'s".to_string(),
                    "let".to_string()
                ]
                .iter()
                .cloned()
                .collect::<HashSet<String>>(),
                token_dict: None,
                phrase_dict: None,
            }
        );
    }

    // TODO phrase fitting tests

    #[tokio::test]
    async fn test_tokenise_pipeline_large() {
        const TEXT: &str = indoc! {
            r#"
            Out, out, brief candle!
            Life's but a walking shadow, a poor player,
            That struts and frets his hour upon the stage,
            And then is heard no more. It is a tale
            Told by an idiot, full of sound and fury,
            Signifying nothing.
            "#
        };

        let res = tokenise_pipeline(TEXT, "en".to_string()).await;
        dbg!(&res);
        assert!(res.is_ok());
    }
}

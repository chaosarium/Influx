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
    TokenSeg {
        idx : usize,
        orthography: String,
    }, 
    PhraseSeg {
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

        let annotated_document: AnnotatedDocV2 = res_json;
        Ok(annotated_document)
    } else {
        Err(anyhow::anyhow!("Request to NLP server failed"))
    }
}

pub fn phrase_fit_pipeline(
    document: AnnotatedDocV2,
    potential_phrases: Trie<String, Phrase>,
) -> AnnotatedDocV2 {
    dbg!(&potential_phrases);

    let mut phrase_dict: HashMap<String, Phrase> = HashMap::new();
    let fitted_doc_seg: Vec<DocSegV2> = document
        .segments
        .into_iter()
        .map(|document_segment| {
            match document_segment.inner {
                DocSegVariants::DocumentWhitespace => DocSegV2 {
                    text: document_segment.text,
                    start_char: document_segment.start_char,
                    end_char: document_segment.end_char,
                    inner: DocSegVariants::DocumentWhitespace,
                },
                DocSegVariants::Sentence { segments } => {
                    let original_segments = segments.clone();

                    let lex_segments = segments
                        .iter()
                        .enumerate()
                        .filter_map(|(i, x)| match &x.inner {
                            SentSegVariants::TokenSeg { orthography, .. } => {
                                Some((i, orthography.clone()))
                            }
                            _ => None,
                        })
                        .collect::<Vec<(usize, String)>>();
                    let lex_segment_orthographies = lex_segments
                        .iter()
                        .map(|(_, orthography)| orthography.clone())
                        .collect::<Vec<String>>();
                    let lex_phrase_slices_indices = phrase_fitting::dp_best_fit(
                        lex_segment_orthographies.clone(),
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
                        return DocSegV2 {
                            text: document_segment.text,
                            start_char: document_segment.start_char,
                            end_char: document_segment.end_char,
                            inner: DocSegVariants::Sentence { segments: original_segments },
                        };
                    }
                    let phrase_slices = lex_phrase_slices_indices
                        .iter()
                        .map(|(lex_start, lex_end)| {
                            let start = lex_segments[*lex_start].0;
                            let end = {
                                match lex_end {
                                    0 => 0,
                                    _ => lex_segments[*lex_end - 1].0 + 1,
                                }
                            };
                            ((start, end), (*lex_start, *lex_end))
                        })
                        .collect::<Vec<((usize, usize), (usize, usize))>>();

                    let phrase_non_phrase_sentence: Vec<SentSegV2> = phrase_slices
                        .iter()
                        .enumerate()
                        .flat_map(|(i, ((start, end), (lex_start, lex_end)))| {
                            let mut segments_to_add: Vec<SentSegV2> = Vec::new();

                            // Add non-phrase tokens before the current phrase
                            if i == 0 && *start > 0 {
                                segments_to_add.extend_from_slice(&original_segments[0..*start]);
                            } else if i > 0 && *start > phrase_slices[i - 1].0 .1 {
                                segments_to_add.extend_from_slice(&original_segments[phrase_slices[i - 1].0 .1..*start]);
                            }

                            // Add the phrase token
                            let phrase = potential_phrases
                                .search_for_payload(
                                    lex_segment_orthographies[*lex_start..*lex_end].to_vec(),
                                )
                                .1
                                .unwrap();
                            phrase_dict.insert(
                                lex_segment_orthographies[*lex_start..*lex_end].join(" "),
                                phrase.clone(),
                            );
                            let phrase_start_char = original_segments[*start].start_char;
                            let phrase_end_char = original_segments[*end - 1].end_char;
                            let phrase_text = original_segments[*start..*end]
                                .iter()
                                .map(|x| x.text.clone())
                                .collect::<Vec<String>>()
                                .join("");

                            segments_to_add.push(SentSegV2 {
                                sentence_idx: original_segments[*start].sentence_idx,
                                text: phrase_text,
                                start_char: phrase_start_char,
                                end_char: phrase_end_char,
                                inner: SentSegVariants::PhraseSeg {
                                    normalised_orthography: lex_segment_orthographies
                                        [*lex_start..*lex_end]
                                        .join(" "),
                                    components: original_segments[*start..*end].to_vec(),
                                },
                                attributes: SegAttribute {
                                    lemma: None,
                                    is_punctuation: None,
                                    upos: None,
                                    xpos: None,
                                    dependency: None,
                                    misc: HashMap::new(),
                                },
                            });

                            // Add non-phrase tokens after the last phrase
                            if i == phrase_slices.len() - 1 && *end < original_segments.len() {
                                segments_to_add.extend_from_slice(&original_segments[*end..original_segments.len()]);
                            }
                            segments_to_add
                        })
                        .collect();

                    DocSegV2 {
                        text: document_segment.text,
                        start_char: document_segment.start_char,
                        end_char: document_segment.end_char,
                        inner: DocSegVariants::Sentence { segments: phrase_non_phrase_sentence },
                    }
                }
            }
        })
        .collect();

    AnnotatedDocV2 {
        text: document.text,
        segments: fitted_doc_seg,
        orthography_set: document.orthography_set,
        lemma_set: document.lemma_set,
        token_dict: document.token_dict,
        phrase_dict: Some(phrase_dict),
    }
}

#[cfg(test)]
mod tests {
    use expect_test::{expect, Expect};
    use super::*;

    #[tokio::test]
    async fn test_tokenise_pipeline_small1() {
        const TEXT: &str = "Hello world! Hi!";

        let res = tokenise_pipeline(TEXT, "en".to_string()).await;
        assert!(res.is_ok());
        let res = res.unwrap();
        let expected = expect![[r#"
            AnnotatedDocV2 {
                text: "Hello world! Hi!",
                segments: [
                    DocSegV2 {
                        text: "Hello world!",
                        start_char: 0,
                        end_char: 12,
                        inner: Sentence {
                            segments: [
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: "Hello",
                                    start_char: 0,
                                    end_char: 5,
                                    inner: TokenSeg {
                                        idx: 0,
                                        orthography: "hello",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "hello",
                                        ),
                                        is_punctuation: Some(
                                            false,
                                        ),
                                        upos: Some(
                                            "INTJ",
                                        ),
                                        xpos: Some(
                                            "UH",
                                        ),
                                        dependency: Some(
                                            (
                                                0,
                                                "ROOT",
                                            ),
                                        ),
                                        misc: {},
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: " ",
                                    start_char: 5,
                                    end_char: 6,
                                    inner: WhitespaceSeg,
                                    attributes: SegAttribute {
                                        lemma: None,
                                        is_punctuation: None,
                                        upos: None,
                                        xpos: None,
                                        dependency: None,
                                        misc: {},
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: "world",
                                    start_char: 6,
                                    end_char: 11,
                                    inner: TokenSeg {
                                        idx: 1,
                                        orthography: "world",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "world",
                                        ),
                                        is_punctuation: Some(
                                            false,
                                        ),
                                        upos: Some(
                                            "NOUN",
                                        ),
                                        xpos: Some(
                                            "NN",
                                        ),
                                        dependency: Some(
                                            (
                                                0,
                                                "npadvmod",
                                            ),
                                        ),
                                        misc: {
                                            "Number": "Sing",
                                        },
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: "!",
                                    start_char: 11,
                                    end_char: 12,
                                    inner: TokenSeg {
                                        idx: 2,
                                        orthography: "!",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "!",
                                        ),
                                        is_punctuation: Some(
                                            true,
                                        ),
                                        upos: Some(
                                            "PUNCT",
                                        ),
                                        xpos: Some(
                                            ".",
                                        ),
                                        dependency: Some(
                                            (
                                                0,
                                                "punct",
                                            ),
                                        ),
                                        misc: {
                                            "PunctType": "Peri",
                                        },
                                    },
                                },
                            ],
                        },
                    },
                    DocSegV2 {
                        text: " ",
                        start_char: 12,
                        end_char: 13,
                        inner: DocumentWhitespace,
                    },
                    DocSegV2 {
                        text: "Hi!",
                        start_char: 13,
                        end_char: 16,
                        inner: Sentence {
                            segments: [
                                SentSegV2 {
                                    sentence_idx: 1,
                                    text: "Hi",
                                    start_char: 13,
                                    end_char: 15,
                                    inner: TokenSeg {
                                        idx: 3,
                                        orthography: "hi",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "hi",
                                        ),
                                        is_punctuation: Some(
                                            false,
                                        ),
                                        upos: Some(
                                            "INTJ",
                                        ),
                                        xpos: Some(
                                            "UH",
                                        ),
                                        dependency: Some(
                                            (
                                                3,
                                                "ROOT",
                                            ),
                                        ),
                                        misc: {},
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 1,
                                    text: "!",
                                    start_char: 15,
                                    end_char: 16,
                                    inner: TokenSeg {
                                        idx: 4,
                                        orthography: "!",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "!",
                                        ),
                                        is_punctuation: Some(
                                            true,
                                        ),
                                        upos: Some(
                                            "PUNCT",
                                        ),
                                        xpos: Some(
                                            ".",
                                        ),
                                        dependency: Some(
                                            (
                                                3,
                                                "punct",
                                            ),
                                        ),
                                        misc: {
                                            "PunctType": "Peri",
                                        },
                                    },
                                },
                            ],
                        },
                    },
                ],
                orthography_set: {
                    "hello",
                    "hi",
                    "world",
                    "!",
                },
                lemma_set: {
                    "hello",
                    "world",
                    "hi",
                    "!",
                },
                token_dict: None,
                phrase_dict: None,
            }
        "#]];
        expected.assert_debug_eq(&res);
    }

    #[tokio::test]
    async fn test_tokenise_pipeline_small2() {
        const TEXT: &str = "Let's  go.";

        let res = tokenise_pipeline(TEXT, "en".to_string()).await;
        assert!(res.is_ok());
        let res = res.unwrap();
        let expected = expect![[r#"
            AnnotatedDocV2 {
                text: "Let's  go.",
                segments: [
                    DocSegV2 {
                        text: "Let's  go.",
                        start_char: 0,
                        end_char: 10,
                        inner: Sentence {
                            segments: [
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: "Let",
                                    start_char: 0,
                                    end_char: 3,
                                    inner: TokenSeg {
                                        idx: 0,
                                        orthography: "let",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "let",
                                        ),
                                        is_punctuation: Some(
                                            false,
                                        ),
                                        upos: Some(
                                            "VERB",
                                        ),
                                        xpos: Some(
                                            "VB",
                                        ),
                                        dependency: Some(
                                            (
                                                0,
                                                "ROOT",
                                            ),
                                        ),
                                        misc: {
                                            "VerbForm": "Inf",
                                        },
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: "'s",
                                    start_char: 3,
                                    end_char: 5,
                                    inner: TokenSeg {
                                        idx: 1,
                                        orthography: "'s",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "us",
                                        ),
                                        is_punctuation: Some(
                                            false,
                                        ),
                                        upos: Some(
                                            "PRON",
                                        ),
                                        xpos: Some(
                                            "PRP",
                                        ),
                                        dependency: Some(
                                            (
                                                3,
                                                "nsubj",
                                            ),
                                        ),
                                        misc: {
                                            "PronType": "Prs",
                                        },
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: " ",
                                    start_char: 5,
                                    end_char: 6,
                                    inner: WhitespaceSeg,
                                    attributes: SegAttribute {
                                        lemma: None,
                                        is_punctuation: None,
                                        upos: None,
                                        xpos: None,
                                        dependency: None,
                                        misc: {},
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: " ",
                                    start_char: 6,
                                    end_char: 7,
                                    inner: TokenSeg {
                                        idx: 2,
                                        orthography: " ",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            " ",
                                        ),
                                        is_punctuation: Some(
                                            false,
                                        ),
                                        upos: Some(
                                            "SPACE",
                                        ),
                                        xpos: Some(
                                            "_SP",
                                        ),
                                        dependency: Some(
                                            (
                                                1,
                                                "dep",
                                            ),
                                        ),
                                        misc: {},
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: "go",
                                    start_char: 7,
                                    end_char: 9,
                                    inner: TokenSeg {
                                        idx: 3,
                                        orthography: "go",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "go",
                                        ),
                                        is_punctuation: Some(
                                            false,
                                        ),
                                        upos: Some(
                                            "VERB",
                                        ),
                                        xpos: Some(
                                            "VB",
                                        ),
                                        dependency: Some(
                                            (
                                                0,
                                                "ccomp",
                                            ),
                                        ),
                                        misc: {
                                            "VerbForm": "Inf",
                                        },
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: ".",
                                    start_char: 9,
                                    end_char: 10,
                                    inner: TokenSeg {
                                        idx: 4,
                                        orthography: ".",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            ".",
                                        ),
                                        is_punctuation: Some(
                                            true,
                                        ),
                                        upos: Some(
                                            "PUNCT",
                                        ),
                                        xpos: Some(
                                            ".",
                                        ),
                                        dependency: Some(
                                            (
                                                0,
                                                "punct",
                                            ),
                                        ),
                                        misc: {
                                            "PunctType": "Peri",
                                        },
                                    },
                                },
                            ],
                        },
                    },
                ],
                orthography_set: {
                    "let",
                    " ",
                    ".",
                    "'s",
                    "go",
                },
                lemma_set: {
                    "go",
                    "let",
                    " ",
                    ".",
                    "us",
                },
                token_dict: None,
                phrase_dict: None,
            }
        "#]];
        expected.assert_debug_eq(&res);
    }

    // TODO phrase fitting tests

}

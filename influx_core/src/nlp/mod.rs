#![allow(unused_imports, unused_must_use)]
use core::panic;
use elm_rs::{Elm, ElmDecode, ElmEncode, ElmQuery, ElmQueryField};
use maplit::{btreemap, hashmap};
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};

use anyhow::{self, Context};
use indoc::indoc;
use serde::{Deserialize, Serialize};
use std::collections::VecDeque;
use std::env;
use std::path::PathBuf;
use tracing::{debug, error, info, warn};

use crate::db::models::phrase::Phrase;
use crate::db::models::vocab::Token;
use crate::db::InfluxResourceId;
use crate::utils::trie::Trie;
pub mod phrase_fitting;
use reqwest::Client;
use serde_json::json;
use serde_json::value::Value;

/// Conjugation chain step
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub struct ConjugationStep {
    step: u32,
    form: String,
    result: String,
}

/// Segment attribute
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub struct SegAttribute {
    lemma: Option<String>,

    upos: Option<String>,
    xpos: Option<String>,
    dependency: Option<(usize, String)>, // (parent idx, relation)
    misc: BTreeMap<String, String>,
    conjugation_chain: Option<Vec<ConjugationStep>>,
}

/// Document segment variants.
#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub enum DocSegVariants {
    Sentence { segments: Vec<SentSegV2> },
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
        idx: usize,
        orthography: String,
    },
    PhraseSeg {
        /// lowercase, with each token orthography separated by a space, to make JavaScript type work out.
        normalised_orthography: String,
        components: Vec<SentSegV2>,
    },
    WhitespaceSeg,
    PunctuationSeg,
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

    pub orthography_set: BTreeSet<String>,
    pub lemma_set: BTreeSet<String>,
    pub parser_config: crate::db::models::lang::ParserConfig,
}

#[derive(Debug, Deserialize, Serialize, PartialEq, Clone, Elm, ElmEncode, ElmDecode)]
pub struct TermDictionary {
    pub token_dict: BTreeMap<String, Token>,
    // JavaScript doesn't support HashMaps with non-string keys, sad. We'll concat the keys into a string for now.
    pub phrase_dict: BTreeMap<String, Phrase>,
}

/// given text and language, return a tokenised document before phrase fitting
pub async fn tokenise_pipeline(
    text: &str,
    language_code: String,
    parser_config: crate::db::models::lang::ParserConfig,
) -> anyhow::Result<AnnotatedDocV2> {
    let client = Client::new();
    let url = "http://127.0.0.1:3001/tokeniser".to_string();
    let payload = json!({
        "text": text,
        "parser_config": parser_config
    });
    let response = client.post(&url).json(&payload).send().await?;

    info!(
        status = %response.status(),
        url = %response.url(),
        "NLP server response received"
    );

    if response.status().is_success() {
        debug!("Request to NLP server succeeded");
        let response_text = response.text().await?;
        let res_json: AnnotatedDocV2 = serde_json::from_str(&response_text)
            .with_context(|| format!("failed to decode NLP server response:\n{}", response_text))?;
        debug!("NLP server response decode succeeded");
        debug!(
            segments_count = res_json.segments.len(),
            orthography_count = res_json.orthography_set.len(),
            lemma_count = res_json.lemma_set.len(),
            "Parsed NLP response"
        );

        let mut annotated_document: AnnotatedDocV2 = res_json;
        annotated_document.parser_config = parser_config;
        Ok(annotated_document)
    } else {
        Err(anyhow::anyhow!("Request to NLP server failed"))
    }
}

pub fn phrase_fit_pipeline(
    document: AnnotatedDocV2,
    potential_phrases: Trie<String, Phrase>,
) -> AnnotatedDocV2 {
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
                            SentSegVariants::PunctuationSeg => Some((i, x.text.clone())),
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
                            inner: DocSegVariants::Sentence {
                                segments: original_segments,
                            },
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
                                segments_to_add.extend_from_slice(
                                    &original_segments[phrase_slices[i - 1].0 .1..*start],
                                );
                            }

                            // Add the phrase token
                            let phrase = match potential_phrases
                                .search_for_payload(
                                    lex_segment_orthographies[*lex_start..*lex_end].to_vec(),
                                )
                                .1
                            {
                                Some(p) => p,
                                None => {
                                    error!(
                                        "Failed to find phrase in trie for orthographies: {:?}",
                                        &lex_segment_orthographies[*lex_start..*lex_end]
                                    );
                                    return vec![]; // Return empty vec to continue processing
                                }
                            };
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
                                    upos: None,
                                    xpos: None,
                                    dependency: None,
                                    misc: btreemap! {},
                                    conjugation_chain: None,
                                },
                            });

                            // Add non-phrase tokens after the last phrase
                            if i == phrase_slices.len() - 1 && *end < original_segments.len() {
                                segments_to_add.extend_from_slice(
                                    &original_segments[*end..original_segments.len()],
                                );
                            }
                            segments_to_add
                        })
                        .collect();

                    DocSegV2 {
                        text: document_segment.text,
                        start_char: document_segment.start_char,
                        end_char: document_segment.end_char,
                        inner: DocSegVariants::Sentence {
                            segments: phrase_non_phrase_sentence,
                        },
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
        parser_config: document.parser_config,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use expect_test::{expect, Expect};

    #[tokio::test]
    async fn test_tokenise_pipeline_small1() {
        const TEXT: &str = "Hello world! Hi!";

        let res = tokenise_pipeline(
            TEXT,
            "en".to_string(),
            crate::db::models::lang::ParserConfig {
                which_parser: "base_spacy".to_string(),
                parser_args: hashmap! {
                    "spacy_model".to_string() => "en_core_web_sm".to_string()
                },
            },
        )
        .await;
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
                                        conjugation_chain: None,
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
                                        upos: None,
                                        xpos: None,
                                        dependency: None,
                                        misc: {},
                                        conjugation_chain: None,
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
                                        conjugation_chain: None,
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: "!",
                                    start_char: 11,
                                    end_char: 12,
                                    inner: PunctuationSeg,
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "!",
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
                                        conjugation_chain: None,
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
                                        conjugation_chain: None,
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 1,
                                    text: "!",
                                    start_char: 15,
                                    end_char: 16,
                                    inner: PunctuationSeg,
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "!",
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
                                        conjugation_chain: None,
                                    },
                                },
                            ],
                        },
                    },
                ],
                orthography_set: {
                    "!",
                    "hello",
                    "hi",
                    "world",
                },
                lemma_set: {
                    "!",
                    "hello",
                    "hi",
                    "world",
                },
                parser_config: ParserConfig {
                    which_parser: "base_spacy",
                    parser_args: {
                        "spacy_model": "en_core_web_sm",
                    },
                },
            }
        "#]];
        expected.assert_debug_eq(&res);
    }

    #[tokio::test]
    async fn test_tokenise_pipeline_small2() {
        const TEXT: &str = "Let's  go.";

        let res = tokenise_pipeline(
            TEXT,
            "en".to_string(),
            crate::db::models::lang::ParserConfig {
                which_parser: "base_spacy".to_string(),
                parser_args: hashmap! {
                    "spacy_model".to_string() => "en_core_web_sm".to_string()
                },
            },
        )
        .await;
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
                                        conjugation_chain: None,
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
                                        conjugation_chain: None,
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: "  ",
                                    start_char: 5,
                                    end_char: 7,
                                    inner: WhitespaceSeg,
                                    attributes: SegAttribute {
                                        lemma: None,
                                        upos: None,
                                        xpos: None,
                                        dependency: None,
                                        misc: {},
                                        conjugation_chain: None,
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
                                        conjugation_chain: None,
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: ".",
                                    start_char: 9,
                                    end_char: 10,
                                    inner: PunctuationSeg,
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            ".",
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
                                        conjugation_chain: None,
                                    },
                                },
                            ],
                        },
                    },
                ],
                orthography_set: {
                    "'s",
                    ".",
                    "go",
                    "let",
                },
                lemma_set: {
                    ".",
                    "go",
                    "let",
                    "us",
                },
                parser_config: ParserConfig {
                    which_parser: "base_spacy",
                    parser_args: {
                        "spacy_model": "en_core_web_sm",
                    },
                },
            }
        "#]];
        expected.assert_debug_eq(&res);
    }

    #[tokio::test]
    async fn test_tokenise_pipeline_small3() {
        const TEXT: &str = "行った。";

        let res = tokenise_pipeline(
            TEXT,
            "ja".to_string(),
            crate::db::models::lang::ParserConfig {
                which_parser: "enhanced_japanese".to_string(),
                parser_args: hashmap! {
                    "enable_conjugation_analysis".to_string() => "true".to_string()
                },
            },
        )
        .await;
        assert!(res.is_ok());
        let res = res.unwrap();
        let expected = expect![[r#"
            AnnotatedDocV2 {
                text: "行った。",
                segments: [
                    DocSegV2 {
                        text: "行った。",
                        start_char: 0,
                        end_char: 4,
                        inner: Sentence {
                            segments: [
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: "行った",
                                    start_char: 0,
                                    end_char: 3,
                                    inner: TokenSeg {
                                        idx: 0,
                                        orthography: "行った",
                                    },
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "行う",
                                        ),
                                        upos: Some(
                                            "VERB",
                                        ),
                                        xpos: Some(
                                            "動詞-非自立可能",
                                        ),
                                        dependency: Some(
                                            (
                                                0,
                                                "ROOT",
                                            ),
                                        ),
                                        misc: {
                                            "Inflection": "助動詞-タ;終止形-一般",
                                            "Reading": "イッタ",
                                            "conjugation_base": "行う",
                                            "conjugation_combined_text": "行った",
                                            "furigana_bracket": "行[い]った",
                                            "furigana_parentheses": "行(い)った",
                                            "furigana_ruby": "<ruby>行<rt>い</rt></ruby>った",
                                            "hiragana_reading": "いった",
                                        },
                                        conjugation_chain: Some(
                                            [
                                                ConjugationStep {
                                                    step: 0,
                                                    form: "base",
                                                    result: "行う",
                                                },
                                                ConjugationStep {
                                                    step: 1,
                                                    form: "Plain Past",
                                                    result: "行った",
                                                },
                                            ],
                                        ),
                                    },
                                },
                                SentSegV2 {
                                    sentence_idx: 0,
                                    text: "。",
                                    start_char: 3,
                                    end_char: 4,
                                    inner: PunctuationSeg,
                                    attributes: SegAttribute {
                                        lemma: Some(
                                            "。",
                                        ),
                                        upos: Some(
                                            "PUNCT",
                                        ),
                                        xpos: Some(
                                            "補助記号-句点",
                                        ),
                                        dependency: Some(
                                            (
                                                0,
                                                "punct",
                                            ),
                                        ),
                                        misc: {
                                            "Reading": "。",
                                            "furigana_bracket": "。",
                                            "furigana_parentheses": "。",
                                            "furigana_ruby": "。",
                                            "hiragana_reading": "。",
                                        },
                                        conjugation_chain: None,
                                    },
                                },
                            ],
                        },
                    },
                ],
                orthography_set: {
                    "。",
                    "た",
                    "行う",
                    "行っ",
                    "行った",
                },
                lemma_set: {
                    "。",
                    "た",
                    "行く",
                },
                parser_config: ParserConfig {
                    which_parser: "enhanced_japanese",
                    parser_args: {
                        "enable_conjugation_analysis": "true",
                    },
                },
            }
        "#]];
        expected.assert_debug_eq(&res);
    }

    #[test]
    fn test_deserialize_japanese_conjugation_json() {
        let json_str = r#"{
  "text": "行った。",
  "segments": [
    {
      "text": "行った。",
      "start_char": 0,
      "end_char": 4,
      "inner": {
        "Sentence": {
          "segments": [
            {
              "sentence_idx": 0,
              "text": "行った",
              "start_char": 0,
              "end_char": 3,
              "inner": {
                "TokenSeg": {
                  "idx": 0,
                  "orthography": "行った"
                }
              },
              "attributes": {
                "lemma": "行う",
                "upos": "VERB",
                "xpos": "動詞-非自立可能",
                "dependency": [0, "ROOT"],
                "misc": {
                  "Inflection": "五段-カ行;連用形-促音便",
                  "Reading": "イッ"
                },
                "conjugation_chain": [
                  {
                    "step": 1,
                    "form": "Plain Past",
                    "result": "行った"
                  }
                ]
              }
            },
            {
              "sentence_idx": 0,
              "text": "。",
              "start_char": 3,
              "end_char": 4,
              "inner": "PunctuationSeg",
              "attributes": {
                "lemma": "。",
                "upos": "PUNCT",
                "xpos": "補助記号-句点",
                "dependency": [0, "punct"],
                "misc": {
                  "Reading": "。"
                },
                "conjugation_chain": null
              }
            }
          ]
        }
      }
    }
  ],
  "orthography_set": ["行っ", "。", "た"],
  "lemma_set": ["行く", "。", "た"],
  "parser_config": {
    "which_parser": "enhanced_japanese",
    "parser_args": {
      "enable_conjugation_analysis": "true"
    }
  }
}"#;

        let result: Result<AnnotatedDocV2, _> = serde_json::from_str(json_str);
        assert!(
            result.is_ok(),
            "Failed to deserialize Japanese conjugation JSON: {:?}",
            result.err()
        );

        let doc = result.unwrap();
        assert_eq!(doc.text, "行った。");

        // Check conjugation chain is properly deserialized
        if let DocSegVariants::Sentence { segments } = &doc.segments[0].inner {
            let token_seg = &segments[0];
            assert!(token_seg.attributes.conjugation_chain.is_some());
            let chain = token_seg.attributes.conjugation_chain.as_ref().unwrap();
            assert_eq!(chain.len(), 1);
            assert_eq!(chain[0].step, 1);
            assert_eq!(chain[0].form, "Plain Past");
            assert_eq!(chain[0].result, "行った");

            // Check punctuation segment has no conjugation chain
            let punct_seg = &segments[1];
            assert!(punct_seg.attributes.conjugation_chain.is_none());
        }
    }

    // TODO phrase fitting tests
}

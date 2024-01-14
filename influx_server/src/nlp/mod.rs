#![allow(unused_imports, unused_must_use)]
use core::panic;
use std::collections::{BTreeMap, HashSet, HashMap};

// use anyhow::Ok;
use anyhow;
// use pyo3::prelude::*;
// use pyo3::types::{IntoPyDict, PyTuple};
use ts_rs::TS;
use std::env;
use std::path::PathBuf;
use indoc::indoc;
use serde::{Deserialize, Serialize};
use std::collections::VecDeque;

use crate::db::models::phrase::Phrase;
use crate::db::models::vocab::Token;
use crate::utils::trie::Trie;
pub mod phrase_fitting;
use serde_json::json;
use reqwest::Client;
use serde_json::value::Value;

// from https://pyo3.rs/v0.20.0/
// #[deprecated]
// pub fn run_some_python() -> PyResult<()> {
//     Python::with_gil(|py| {
//         let sys = py.import("sys")?;
//         let version: String = sys.getattr("version")?.extract()?;
        
//         let code = "os.getenv('USER') or os.getenv('USERNAME') or 'Unknown'";
//         let locals = [("os", py.import("os")?)].into_py_dict(py);
//         let user: String = py.eval(code, None, Some(&locals))?.extract()?;
//         println!("Hello {}, I'm Python {}", user, version);

//         // println!("listing available python modules...");
//         // py.eval("help('modules')", None, None)?;
        
//         println!("python's sys.path...");
//         let pythonsyspath: Vec<String> = sys.getattr("path")?.extract()?;
//         println!("{:?}", pythonsyspath);

//         println!("trying to import stanza");
//         let stanza = PyModule::import(py, "stanza")?;

//         Ok(())
//     })
// }



type StanzaResult = (String, usize, usize, Vec<Vec<Vec<BTreeMap<String, RustyEnum>>>>);

#[derive(Debug, Deserialize, Serialize, TS, PartialEq, Clone, Default)]
#[ts(export, export_to = "../influx_ui/src/lib/types/")]
#[serde(tag = "type")]
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

#[derive(Debug, Deserialize, Serialize, TS, PartialEq, Clone)]
#[ts(export, export_to = "../influx_ui/src/lib/types/")]
#[serde(tag = "type")]
pub enum DocumentConstituent {
    Sentence {
        id: usize, // 0-indexed
        text: String,
        start_char: usize,
        end_char: usize,
        constituents: Vec<SentenceConstituent>,
    },
    Whitespace {
        text: String,
        start_char: usize,
        end_char: usize,
    },
}

#[derive(Debug, Deserialize, Serialize, TS, PartialEq, Clone)]
#[ts(export, export_to = "../influx_ui/src/lib/types/")]
#[serde(tag = "type")]
pub enum SentenceConstituent {
    CompositToken {
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
    Whitespace {
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

impl SentenceConstituent {
    fn mark_shadowed(&mut self) {
        match self {
            SentenceConstituent::CompositToken { shadowed, .. } => *shadowed = true,
            SentenceConstituent::SubwordToken { shadowed, .. } => *shadowed = true,
            SentenceConstituent::SingleToken { shadowed, .. } => *shadowed = true,
            SentenceConstituent::Whitespace { shadowed, .. } => *shadowed = true,
            SentenceConstituent::PhraseToken { shadowed, .. } => *shadowed = true,
        }
    }

    fn push_shadow(&mut self, shadow: SentenceConstituent) {
        match self {
            SentenceConstituent::CompositToken { shadows, .. } => shadows.push(shadow),
            SentenceConstituent::SubwordToken { shadows, .. } => shadows.push(shadow),
            SentenceConstituent::SingleToken { shadows, .. } => shadows.push(shadow),
            SentenceConstituent::Whitespace { shadows, .. } => shadows.push(shadow),
            SentenceConstituent::PhraseToken { shadows, .. } => shadows.push(shadow),
        }
    }

    fn get_text(&self) -> String {
        match self {
            SentenceConstituent::CompositToken { text, .. } => text.clone(),
            SentenceConstituent::SubwordToken { text, .. } => text.clone(),
            SentenceConstituent::SingleToken { text, .. } => text.clone(),
            SentenceConstituent::Whitespace { text, .. } => text.clone(),
            SentenceConstituent::PhraseToken { text, .. } => text.clone(),
        }
    }
    fn has_start_and_end(&self) -> bool {
        match self {
            SentenceConstituent::CompositToken { .. } => true,
            SentenceConstituent::SubwordToken { .. } => false,
            SentenceConstituent::SingleToken { .. } => true,
            SentenceConstituent::Whitespace { .. } => true,
            SentenceConstituent::PhraseToken { .. } => true,
        }
    }
    fn get_start_char(&self) -> usize {
        match self {
            SentenceConstituent::CompositToken { start_char, .. } => *start_char,
            SentenceConstituent::SubwordToken { .. } => panic!("SubwordToken has no start_char"),
            SentenceConstituent::SingleToken { start_char, .. } => *start_char,
            SentenceConstituent::Whitespace { start_char, .. } => *start_char,
            SentenceConstituent::PhraseToken { start_char, .. } => *start_char,
        }
    }
    fn get_end_char(&self) -> usize {
        match self {
            SentenceConstituent::CompositToken { end_char, .. } => *end_char,
            SentenceConstituent::SubwordToken { .. } => panic!("SubwordToken has no end_char"),
            SentenceConstituent::SingleToken { end_char, .. } => *end_char,
            SentenceConstituent::Whitespace { end_char, .. } => *end_char,
            SentenceConstituent::PhraseToken { end_char, .. } => *end_char,
        }
    }
}

fn stanzatoken_get_text(stanzatoken: &BTreeMap<String, Value>) -> String {
    match stanzatoken.get("text") {
        Some(Value::String(text)) => text.clone(),
        _ => {panic!("ouch")}
    }
}

fn stanzatoken_get_start_char(stanzatoken: &BTreeMap<String, Value>) -> usize {
    match stanzatoken.get("start_char") {
        Some(Value::Number(start_char)) => start_char.as_u64().unwrap() as usize,
        _ => {panic!("ouch")}
    }
}

fn stanzatoken_get_end_char(stanzatoken: &BTreeMap<String, Value>) -> usize {
    match stanzatoken.get("end_char") {
        Some(Value::Number(end_char)) => end_char.as_u64().unwrap() as usize,
        _ => {panic!("ouch")}
    }
}

fn stanzatoken_get_lemma(stanzatoken: &BTreeMap<String, Value>) -> String {
    match stanzatoken.get("lemma") {
        Some(Value::String(lemma)) => lemma.clone(),
        _ => {panic!("ouch")}
    }
}

fn char_slice(text_chars: &Vec<char>, start_char: usize, end_char: usize) -> String {
    text_chars[start_char..end_char].iter().collect()
}

fn stanza2document(stanzares: NLPServerReturn) -> anyhow::Result<AnnotatedDocument> {
    let text = stanzares.text;
    let text_chars: Vec<char> = text.chars().collect();
    let mut orthography_set: HashSet<String> = HashSet::new();
    let mut lemma_set: HashSet<String> = HashSet::new();

    let mut intermediate_sentences: VecDeque<DocumentConstituent> = VecDeque::new();

    for (sentence_id, sentence) in (stanzares.constituents).iter().enumerate() {
        let mut intermediate_tokens: VecDeque<SentenceConstituent> = VecDeque::new();

        for token_group in sentence.iter() {
                
            let mut children2parent: HashMap<usize, usize> = HashMap::new();

            // first pass, collect `CompositToken`s with their shadows temporiarily blank
            // point childrens to their parents via `children2parent` map
            for stanzatoken in token_group {
                match stanzatoken.get("id") {
                    Some(Value::Array(subtokenids_arr)) => {
                        let subtokenids = subtokenids_arr.iter().map(|x| x.as_u64().unwrap() as usize).collect::<Vec<usize>>();
                        intermediate_tokens.push_back(SentenceConstituent::CompositToken {
                            sentence_id: sentence_id,
                            ids: subtokenids.clone(),
                            text: stanzatoken_get_text(stanzatoken),
                            orthography: stanzatoken_get_text(stanzatoken).to_lowercase(),
                            start_char: stanzatoken_get_start_char(stanzatoken),
                            end_char: stanzatoken_get_end_char(stanzatoken),
                            shadowed: false,
                            shadows: vec![],
                        });
                        let parent_idx = intermediate_tokens.len() - 1;
                        children2parent.extend(subtokenids.iter().map(|stanza_token_id| (*stanza_token_id, parent_idx)));
                        orthography_set.insert(stanzatoken_get_text(stanzatoken).to_lowercase());
                    },
                    _ => ()
                }
            }

            // second pass, collect non composit tokens, fill in `CompositToken` shadows or add to `intermediate_tokens` depending on whether they are shadowed
            for stanzatoken in token_group {
                match stanzatoken.get("id") {
                    Some(Value::Array(subtokenids)) => (),
                    Some(Value::Number(stanza_token_id_num)) => {
                        let stanza_token_id = stanza_token_id_num.as_u64().unwrap() as usize;
                        match children2parent.get(&stanza_token_id) {
                            Some(parent_idx) => { // shadowed, add to parent's shadows
                                intermediate_tokens[*parent_idx].push_shadow(SentenceConstituent::SubwordToken {
                                    sentence_id: sentence_id,
                                    id: stanza_token_id,
                                    text: stanzatoken_get_text(stanzatoken),
                                    orthography: stanzatoken_get_text(stanzatoken).to_lowercase(),
                                    lemma: stanzatoken_get_lemma(stanzatoken).to_lowercase(),
                                    shadowed: true,
                                    shadows: vec![],
                                });
                                orthography_set.insert(stanzatoken_get_text(stanzatoken).to_lowercase());
                                lemma_set.insert(stanzatoken_get_lemma(stanzatoken).to_lowercase());
                            },
                            None => { // not shadowed, add to intermediate_tokens
                                intermediate_tokens.push_back(SentenceConstituent::SingleToken {
                                    sentence_id: sentence_id,
                                    id: stanza_token_id,
                                    text: stanzatoken_get_text(stanzatoken),
                                    orthography: stanzatoken_get_text(stanzatoken).to_lowercase(),
                                    lemma: stanzatoken_get_lemma(stanzatoken).to_lowercase(),
                                    start_char: stanzatoken_get_start_char(stanzatoken),
                                    end_char: stanzatoken_get_end_char(stanzatoken),
                                    shadowed: false,
                                    shadows: vec![],
                                });
                                orthography_set.insert(stanzatoken_get_text(stanzatoken).to_lowercase());
                                lemma_set.insert(stanzatoken_get_lemma(stanzatoken).to_lowercase());
                            }
                        }
                    },
                    _ => ()
                }
            }
        }

        let sentence_start = intermediate_tokens
            .iter()
            .filter(|token| token.has_start_and_end())
            .min_by(|a, b| a.get_start_char().cmp(&b.get_start_char()))
            .unwrap()
            .get_start_char();
        let sentence_end = intermediate_tokens
            .iter()
            .filter(|token| token.has_start_and_end())
            .max_by(|a, b| a.get_end_char().cmp(&b.get_end_char()))
            .unwrap()
            .get_end_char();

        let mut tokens = vec![];
        let mut fill_line = sentence_start;
        while intermediate_tokens.len() > 0 {
            let token = intermediate_tokens.pop_front().unwrap();

            match token {
                SentenceConstituent::SubwordToken { .. } => {
                    tokens.push(token)
                },
                SentenceConstituent::CompositToken { start_char, end_char, .. } => {
                    if start_char > fill_line {
                        tokens.push(SentenceConstituent::Whitespace {
                            text: char_slice(&text_chars, fill_line, start_char).to_string(),
                            orthography: char_slice(&text_chars, fill_line, start_char).to_string(),
                            start_char: fill_line,
                            end_char: start_char,
                            shadowed: false,
                            shadows: vec![],
                        })
                    }
                    fill_line = end_char;
                    tokens.push(token)
                },
                SentenceConstituent::SingleToken { start_char, end_char, .. } => {
                    if start_char > fill_line {
                        tokens.push(SentenceConstituent::Whitespace {
                            text: char_slice(&text_chars, fill_line, start_char).to_string(),
                            orthography: char_slice(&text_chars, fill_line, start_char).to_string(),
                            start_char: fill_line,
                            end_char: start_char,
                            shadowed: false,
                            shadows: vec![],
                        })
                    }
                    fill_line = end_char;
                    tokens.push(token)
                },
                _ => (),
            }
        }

        // dbg!(&tokens);

        intermediate_sentences.push_back(DocumentConstituent::Sentence {
            id: sentence_id,
            text: char_slice(&text_chars, sentence_start, sentence_end).to_string(),
            start_char: sentence_start,
            end_char: sentence_end,
            constituents: tokens,
        })

        
    };
    
    let mut sentences = vec![];
    let mut fill_line = 0;
    while intermediate_sentences.len() > 0 {
        let sentence = intermediate_sentences.pop_front().unwrap();

        match sentence {
            DocumentConstituent::Whitespace { .. } => {
                sentences.push(sentence)
            },
            DocumentConstituent::Sentence { start_char, end_char, .. } => {
                if start_char > fill_line {
                    sentences.push(DocumentConstituent::Whitespace {
                        text: char_slice(&text_chars, fill_line, start_char).to_string(),
                        start_char: fill_line,
                        end_char: start_char,
                    })
                }
                fill_line = end_char;
                sentences.push(sentence)
            },
        }

    }

    // dbg!(&sentences);
    
    anyhow::Ok(AnnotatedDocument {
        text: text, 
        constituents: sentences, 
        num_sentences: stanzares.num_sentences, 
        num_tokens: stanzares.num_tokens, 
        orthography_set: orthography_set,
        lemma_set: lemma_set,
        token_dict: None,
        phrase_dict: None,
    })
}

#[derive(Debug, Deserialize, Serialize)]
struct NLPServerReturn {
    text: String,
    num_tokens: usize, 
    num_sentences: usize, 
    constituents: Vec<Vec<Vec<BTreeMap<String, Value>>>>,
}

#[derive(Debug, Deserialize, Serialize)]
// #[derive(FromPyObject, Debug)]
enum RustyEnum {
    // #[pyo3(transparent, annotation = "str")]
    String(String),
    // #[pyo3(transparent, annotation = "int")]
    Int(usize),
    // #[pyo3(transparent, annotation = "tuple")]
    List(Vec<usize>),
}

/// given text and language, return a tokenised document before phrase fitting
pub async fn tokenise_pipeline(text: &str, language: String) -> anyhow::Result<AnnotatedDocument> {

    // let current_dir = env::current_dir()?;
    // let pylib_path = current_dir.join("./src/nlp/pylib").canonicalize()?; 

    // Python::with_gil(|py| {
    //     let stanza = PyModule::import(py, "stanza")?;

    //     let pylib_path_str = pylib_path.to_str().unwrap();
    //     let code = indoc!(
    //         r#"
    //         import sys, os
    //         sys.path.insert(0, os.path.abspath("{path}"))
    //         from stanza_integration import fun
    //         "#
    //     );
    //     let code = code.replace("{path}", pylib_path_str);

    //     let fun: Py<PyAny> = PyModule::from_code(
    //         py, &code, "", "",
    //     )?.getattr("fun")?.into();

    //     let callret = fun
    //         .call1(py, (text, language))?
    //         .extract::<StanzaResult>(py);

    //     // dbg!(&callret);

    //     let converteddoc = stanza2document(callret?)?;

    //     Ok(converteddoc)
    // })


    let client = Client::new();
    let url = format!("http://127.0.0.1:3001/tokeniser/{}", language);
    let payload = json!({
        "text": text
    });
    let response = client.post(&url)
        .json(&payload)
        .send()
        .await?;

    dbg!(&response);
    if response.status().is_success() {
        println!("Request to NLP server succeeded");
        let res_json: NLPServerReturn = response
            .json::<NLPServerReturn>()
            .await?;
        dbg!(&res_json);

        let converteddoc = stanza2document(res_json)?;

        // let annotated_document: AnnotatedDocument = res_json;
        Ok(converteddoc)
    } else {
        Err(anyhow::anyhow!("Request to NLP server failed"))
    }


}

pub fn phrase_fit_pipeline(document: AnnotatedDocument, potential_phrases: Trie<String, Phrase>) -> AnnotatedDocument {
    dbg!(&potential_phrases);

    let mut phrase_dict: HashMap<String, Phrase> = HashMap::new();
    let fitted_doc_cst: Vec<DocumentConstituent> = document.constituents
        .into_iter()
        .map(|document_constituent| {
            match document_constituent {
                DocumentConstituent::Whitespace { text, start_char, end_char } => {
                    DocumentConstituent::Whitespace { text, start_char, end_char }
                },
                DocumentConstituent::Sentence { id, text, start_char, end_char, constituents } => {
                    let original_constituents = constituents.clone();

                    let lex_constituents = constituents
                        .iter()
                        .enumerate()
                        .filter_map(|(i, x)| {
                            match x {
                                SentenceConstituent::SingleToken { orthography, .. } => Some((i, orthography.clone())),
                                SentenceConstituent::CompositToken { orthography, .. } => Some((i, orthography.clone())),
                                _ => None,
                            }
                        })
                        .collect::<Vec<(usize, String)>>();
                    let lex_constituents_orthographies = lex_constituents.iter().map(|(_, orthography)| orthography.clone()).collect::<Vec<String>>();
                    let lex_phrase_slices_indices = phrase_fitting::dp_best_fit(lex_constituents_orthographies.clone(), &potential_phrases);
                    let lex_phrase_slices_indices = lex_phrase_slices_indices
                        .iter()
                        .filter(|(start, end)| { // remove trivial phrases
                            match end - start {
                                1 => false,
                                _ => true,
                            }
                        })
                        .collect::<Vec<&(usize, usize)>>();
                    if lex_phrase_slices_indices.len() == 0 { // no phrase
                        return DocumentConstituent::Sentence { id, text, start_char, end_char, constituents: original_constituents };
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
                            if i == 0 && phrase_slices.len() > 1 { // first
                                vec![((0, *start), None, false), ((*start, *end), Some((*lex_start, *lex_end)), true), ((*end, phrase_slices[i+1].0.0), None, false)]
                            } else if i == 0 && phrase_slices.len() <= 1 { // first and last
                                vec![((0, *start), None, false), ((*start, *end), Some((*lex_start, *lex_end)), true), ((*end, original_constituents.len()), None, false)]
                            } else if i == phrase_slices.len() - 1 { // last
                                vec![((*start, *end), Some((*lex_start, *lex_end)), true), ((*end, original_constituents.len()), None, false)]
                            } else {
                                vec![((*start, *end), Some((*lex_start, *lex_end)), true), ((*end, phrase_slices[i+1].0.0), None, false)]
                            }
                        })
                        .flatten()
                        .map(|((start, end), lex_loc, is_phrase)| {
                            match (is_phrase, lex_loc) {
                                (false, None) => {
                                    let non_phrase_tokens = original_constituents[start..end].to_vec();
                                    non_phrase_tokens
                                },
                                (true, Some((lex_start, lex_end))) => {
                                    let phrase = potential_phrases.search_for_payload(lex_constituents_orthographies[lex_start..lex_end].to_vec()).1.unwrap();
                                    phrase_dict.insert(lex_constituents_orthographies[lex_start..lex_end].join(" "), phrase.clone());
                                    let phrase_start_char = original_constituents[start].get_start_char();
                                    let phrase_end_char = original_constituents[end-1].get_end_char();
                                    let phrase_text = original_constituents[start..end].iter().map(|x| x.get_text()).collect::<Vec<String>>().join("");

                                    let mut shadowned_tokens = original_constituents[start..end].to_vec();
                                    shadowned_tokens.iter_mut().for_each(|x| {
                                        x.mark_shadowed();
                                    });
                                    vec![SentenceConstituent::PhraseToken { 
                                        sentence_id: id, 
                                        text: phrase_text, 
                                        normalised_orthography: lex_constituents_orthographies[lex_start..lex_end].join(" "),
                                        start_char: phrase_start_char, 
                                        end_char: phrase_end_char,
                                        shadowed: false,
                                        shadows: shadowned_tokens,
                                    }]
                                },
                                _ => panic!("unreachable"),
                            }
                        })
                        .flatten()
                        .collect::<Vec<SentenceConstituent>>();

                    DocumentConstituent::Sentence { id, text, start_char, end_char, constituents: phrase_non_phrase_sentence }
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
        assert_eq!(res, AnnotatedDocument {
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
                        SentenceConstituent::Whitespace {
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
                DocumentConstituent::Whitespace {
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
            lemma_set: ["hello".to_string(), "world".to_string(), "hi".to_string(), "!".to_string()].iter().cloned().collect::<HashSet<String>>(),
            orthography_set: ["hello".to_string(), "world".to_string(), "hi".to_string(), "!".to_string()].iter().cloned().collect::<HashSet<String>>(),
            token_dict: None,
            phrase_dict: None,
        });
    }

    #[tokio::test]
    async fn test_tokenise_pipeline_small2() {
        const TEXT: &str = "Let's  go.";
        
        let res = tokenise_pipeline(TEXT, "en".to_string()).await;
        assert!(res.is_ok());
        let res = res.unwrap();
        assert_eq!(res, AnnotatedDocument {
            text: "Let's  go.".to_string(),
            constituents: vec![
                DocumentConstituent::Sentence {
                    id: 0,
                    text: "Let's  go.".to_string(),
                    start_char: 0,
                    end_char: 10,
                    constituents: vec![
                        SentenceConstituent::CompositToken {
                            sentence_id: 0,
                            ids: vec![
                                1,
                                2,
                            ],
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
                        SentenceConstituent::Whitespace {
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
                },
            ],
            num_sentences: 1,
            num_tokens: 3,
            orthography_set: ["go".to_string(), ".".to_string(), "let's".to_string(), "let".to_string(), "'s".to_string()].iter().cloned().collect::<HashSet<String>>(),
            lemma_set: ["go".to_string(), ".".to_string(), "'s".to_string(), "let".to_string()].iter().cloned().collect::<HashSet<String>>(),
            token_dict: None,
            phrase_dict: None,
        });
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

    // #[test]
    // fn test_run_some_python() {
    //     assert!(run_some_python().is_ok());
    // }

    #[test]
    fn test_bytes() {
        let text = "🚀, 🚀, 🚀".to_string();
        let text2 = "a".to_string();

        println!("{:?}", text.as_bytes());
        println!("{:?}", text.chars());
        println!("{:?}", text2.as_bytes());
        // println!("{}", text[0..1].to_string());
        // println!("{}", text[1..2].to_string());
    }

}

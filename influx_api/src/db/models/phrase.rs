///! a phrase is a user-defined multi-word token. phrases shall be added during a second pass tokenization process

use super::{models_prelude::*, vocab};
use std::collections::{HashMap, BTreeMap, HashSet};
use crate::{prelude::*, utils::trie::Trie};
use vocab::{TokenStatus, SRSInfo};

const TABLE: &str = "phrase";
pub fn mk_phrase_thing(id: String) -> Thing {
    Thing::from((TABLE.to_string(), id))
}

#[derive(Debug, Serialize, Deserialize, TS, Clone, PartialEq, Eq, Hash)]
#[ts(export, export_to = "../influx_ui/src/lib/types/")]
pub struct Phrase {
    #[serde(skip_serializing_if = "Option::is_none")]
    #[ts(type = "{ tb: string, id: {String: string} }")]
    pub id: Option<Thing>,
    pub lang_id: String,
    
    pub orthography_seq: Vec<String>,
    pub definition: String,
    pub notes: String,
    pub original_context: String,
    
    pub status: TokenStatus,
    pub tags: Vec<String>, 
    pub srs: SRSInfo,
}

impl Phrase {
    pub fn essential_phrase(lang_id: &str, orthography_seq: Vec<String>) -> Self {
        Phrase {
            id: None,
            lang_id: lang_id.to_string(),
            orthography_seq,
            definition: "placeholder".to_string(),
            notes: "some essential phrase".to_string(),
            original_context: "".to_string(),
            status: TokenStatus::L1,
            tags: vec![],
            srs: SRSInfo::default(),
        }
    }
}

impl DB {

    pub async fn seed_phrase_table(&self) -> Result<()> {
        let phrases = vec![
            Phrase {
                id: None,
                lang_id: "en_demo".to_string(),
                orthography_seq: vec!["hello".to_string(), "world".to_string()],
                definition: "placeholder".to_string(),
                notes: "a very familiar phrase! (for programmers)".to_string(),
                original_context: "".to_string(),
                status: TokenStatus::L5,
                tags: vec![],
                srs: SRSInfo::default(),
            },
            Phrase {
                id: None,
                lang_id: "en_demo".to_string(),
                orthography_seq: vec!["world".to_string(), "wide".to_string(), "web".to_string()],
                definition: "placeholder".to_string(),
                notes: "I wonder what this is".to_string(),
                original_context: "".to_string(),
                status: TokenStatus::L3,
                tags: vec![],
                srs: SRSInfo::default(),
            },
        ];

        for phrase in phrases {
            self.create_phrase(phrase).await?;
        }

        Ok(())
    }

    /// requires that all orthography in orthography_seq is lowercase
    /// requires that all orthography in orthography_seq is not already in database
    pub async fn create_phrase(&self, phrase: Phrase) -> Result<Phrase> {
        assert!(phrase.orthography_seq.iter().all(|s| s.to_lowercase() == *s));
        // TODO assert it does not exist

        let sql = format!("CREATE {TABLE} CONTENT $phrase");
        let mut res: Response = self.db
            .query(sql)
            .bind(("phrase", phrase))
            .await?;

        match res.take(0) {
            Ok(Some::<Phrase>(v)) => Ok(v),
            Ok(None) => Err(anyhow::anyhow!("sql didn't fail but no phrase was returned")),
            Err(e) => Err(anyhow::anyhow!("Error creating phrase: {:?}", e)),
        }
    }

    /// requires that all orthography in orthography_seq is lowercase
    pub async fn query_phrase_by_onset_orthographies(&self, onset_orthography_set: HashSet<String>, lang_id: String) -> Result<Vec<Phrase>> {
        let sql = format!("SELECT * FROM phrase WHERE array::first(orthography_seq) INSIDE $onsets AND lang_id = $lang_id;");
        let mut res: Response = self.db
            .query(sql)
            .bind(("onsets", onset_orthography_set.iter().cloned().collect::<Vec<String>>()))
            .bind(("lang_id", lang_id))
            .await?;

        match res.take(0) {
            Ok::<Vec<Phrase>, _>(v) => Ok(v),
            _ => Err(anyhow::anyhow!("Error querying phrase"))
        }
    }

    /// does not require that orthographies are lowercase. they will be converted to lowercase
    pub async fn get_phrases_from_text_set(&self, text_set: HashSet<String>, lang_id: String) -> Result<Vec<Phrase>> {
        let onset_orthography_set: HashSet<String> = text_set.iter().cloned().map(|x| x.to_lowercase()).collect::<HashSet<String>>();
        self.query_phrase_by_onset_orthographies(onset_orthography_set, lang_id).await
    }
    
    /// does not require that orthographies are lowercase. they will be converted to lowercase
    pub async fn get_phrases_from_text_seq(&self, text_seq: Vec<String>, lang_id: String) -> Result<Vec<Phrase>> {
        let onset_orthography_set: HashSet<String> = text_seq.iter().cloned().map(|x| x.to_lowercase()).collect::<HashSet<String>>();
        self.query_phrase_by_onset_orthographies(onset_orthography_set, lang_id).await
    }
}

pub fn mk_phrase_trie(phrases: Vec<Phrase>) -> Trie<String, Phrase> {
    Trie::new_with_entries_and_payloads(
        phrases
            .into_iter()
            .map(|phrase| {
                (
                    phrase.orthography_seq.clone(),
                    phrase,
                )
            })
            .collect::<Vec<(Vec<String>, Phrase)>>(),
    )
}

mod tests {
    use crate::db::DBLocation;
    use super::*;

    #[tokio::test]
    async fn test_create_phrase() {
        let db = DB::create_db(DBLocation::Mem).await;
        let phrase = Phrase::essential_phrase("en_demo", vec!["hello".to_string(), "world".to_string()]);
        let created = db.create_phrase(phrase).await.unwrap();
        // dbg!("created: {:?}", created);
        assert_eq!(created.orthography_seq, vec!["hello".to_string(), "world".to_string()]);
    }

    #[tokio::test]
    async fn test_query_phrase() {
        let db = DB::create_db(DBLocation::Mem).await;
        let phrase = Phrase::essential_phrase("en_demo", vec!["hello".to_string(), "world".to_string()]);
        let created = db.create_phrase(phrase).await.unwrap();
        let phrase = Phrase::essential_phrase("en_demo", vec!["world".to_string(), "record".to_string()]);
        let created = db.create_phrase(phrase).await.unwrap();
        let phrase = Phrase::essential_phrase("en_demo", vec!["world".to_string(), "wide".to_string(), "web".to_string()]);
        let created = db.create_phrase(phrase).await.unwrap();
        let phrase = Phrase::essential_phrase("en_demo", vec!["hello".to_string(), "moon".to_string()]);
        let created = db.create_phrase(phrase).await.unwrap();
        
        let queried = db.query_phrase_by_onset_orthographies(vec!["hello".to_string()].into_iter().collect(), "en_demo".to_string()).await.unwrap();
        // dbg!("queried: {:?}", &queried);
        assert_eq!(queried.len(), 2);
        assert!(queried.iter().any(|phrase| phrase.orthography_seq == vec!["hello".to_string(), "world".to_string()]));
        assert!(queried.iter().any(|phrase| phrase.orthography_seq == vec!["hello".to_string(), "moon".to_string()]));

        let queried = db.query_phrase_by_onset_orthographies(vec!["world".to_string(), "earth".to_string()].into_iter().collect(), "en_demo".to_string()).await.unwrap();
        // dbg!("queried: {:?}", &queried);
        assert_eq!(queried.len(), 2);
        assert!(queried.iter().any(|phrase| phrase.orthography_seq == vec!["world".to_string(), "record".to_string()]));
        assert!(queried.iter().any(|phrase| phrase.orthography_seq == vec!["world".to_string(), "wide".to_string(), "web".to_string()]));

        let from_text_seq = db.get_phrases_from_text_seq(vec!["Hello".to_string(), "world".to_string(), "record".to_string()], "en_demo".to_string()).await.unwrap();   
        // dbg!("from_text_seq: {:?}", &from_text_seq);
        assert_eq!(from_text_seq.len(), 4);
        assert!(from_text_seq.iter().any(|phrase| phrase.orthography_seq == vec!["hello".to_string(), "world".to_string()]));
        assert!(from_text_seq.iter().any(|phrase| phrase.orthography_seq == vec!["hello".to_string(), "moon".to_string()]));
        assert!(from_text_seq.iter().any(|phrase| phrase.orthography_seq == vec!["world".to_string(), "record".to_string()]));
        assert!(from_text_seq.iter().any(|phrase| phrase.orthography_seq == vec!["world".to_string(), "wide".to_string(), "web".to_string()]));
    }
}
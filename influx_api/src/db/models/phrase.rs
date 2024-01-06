///! a phrase is a user-defined multi-word token. phrases shall be added during a second pass tokenization process

use super::{models_prelude::*, vocab};
use std::collections::{HashMap, BTreeMap, HashSet};
use crate::prelude::*;
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
            Phrase::essential_phrase("en_demo", vec!["hello".to_string(), "world".to_string()]),
            Phrase::essential_phrase("en_demo", vec!["world".to_string(), "wide".to_string(), "web".to_string()]),
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
            Ok(None) => Err(anyhow::anyhow!("sql didn't fail but no token was returned")),
            Err(e) => Err(anyhow::anyhow!("Error creating token: {:?}", e)),
        }
    }
}

mod tests {
    use crate::db::DBLocation;
    use super::*;

    #[tokio::test]
    async fn test_create_token() {
        let db = DB::create_db(DBLocation::Mem).await;
        let phrase = Phrase::essential_phrase("en_demo", vec!["hello".to_string(), "world".to_string()]);
        let created = db.create_phrase(phrase).await.unwrap();
        println!("created: {:?}", created);
        assert_eq!(created.orthography_seq, vec!["hello".to_string(), "world".to_string()]);
    }
}
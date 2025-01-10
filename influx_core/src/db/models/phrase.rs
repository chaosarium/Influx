///! a phrase is a user-defined multi-word token. phrases shall be added during a second pass tokenization process
use super::*;
use crate::db::{deserialize_surreal_thing, deserialize_surreal_thing_opt};
use crate::{db::InfluxResourceId, prelude::*, utils::trie::Trie};
use std::collections::{BTreeMap, HashMap, HashSet};
use vocab::TokenStatus;
use DB::*;

const TABLE: &str = "phrase";
pub fn mk_phrase_thing(id: String) -> Thing {
    Thing::from((TABLE.to_string(), id))
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash)]
pub struct Phrase {
    #[serde(deserialize_with = "deserialize_surreal_thing_opt")]
    pub id: Option<InfluxResourceId>,
    #[serde(deserialize_with = "deserialize_surreal_thing")]
    pub lang_id: InfluxResourceId,

    pub orthography_seq: Vec<String>,
    pub definition: String,
    pub notes: String,
    pub original_context: String,

    pub status: TokenStatus,
}

impl Phrase {
    pub fn essential_phrase(lang_id: InfluxResourceId, orthography_seq: Vec<String>) -> Self {
        Phrase {
            id: None,
            lang_id: lang_id,
            orthography_seq,
            definition: "placeholder".to_string(),
            notes: "some essential phrase".to_string(),
            original_context: "".to_string(),
            status: TokenStatus::L1,
        }
    }
}

impl DB {
    pub async fn phrase_exists(
        &self,
        lang_id: InfluxResourceId,
        orthography_seq: Vec<String>,
    ) -> Result<bool> {
        assert!(orthography_seq.iter().all(|s| s.to_lowercase() == *s));

        match self {
            Surreal { engine } => {
                let sql = format!("SELECT * FROM phrase WHERE orthography_seq = $orthography_seq AND lang_id = $lang_id;");
                let mut res: Response = engine
                    .query(sql)
                    .bind(("orthography_seq", orthography_seq))
                    .bind(("lang_id", lang_id))
                    .await?;

                match res.take(0) {
                    Ok::<Vec<Phrase>, _>(v) => Ok(v.len() > 0),
                    _ => Err(anyhow::anyhow!("Error querying phrase")),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Phrase,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", lang_id as "lang_id: InfluxResourceId", orthography_seq, definition, notes, original_context, status as "status: TokenStatus"
                        FROM phrase
                        WHERE orthography_seq = $1 AND lang_id = $2
                    "#,
                    &orthography_seq,
                    lang_id.as_i64()?,
                )
                .fetch_all(pool.as_ref())
                .await?;

                Ok(record.len() > 0)
            }
        }
    }

    /// - requires that all orthography in orthography_seq is lowercase
    /// - orthography_seq is not already in database
    pub async fn create_phrase(&self, phrase: Phrase) -> Result<Phrase> {
        assert!(phrase
            .orthography_seq
            .iter()
            .all(|s| s.to_lowercase() == *s));
        assert!(phrase.id.is_none());
        assert!(
            !self
                .phrase_exists(phrase.lang_id.clone(), phrase.orthography_seq.clone())
                .await?
        );

        match self {
            Surreal { engine } => {
                let sql = format!("CREATE {TABLE} CONTENT $phrase");
                let mut res: Response = engine.query(sql).bind(("phrase", phrase)).await?;

                match res.take(0) {
                    Ok(Some::<Phrase>(v)) => Ok(v),
                    Ok(None) => Err(anyhow::anyhow!(
                        "sql didn't fail but no phrase was returned"
                    )),
                    Err(e) => Err(anyhow::anyhow!("Error creating phrase: {:?}", e)),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Phrase,
                    r#"
                        INSERT INTO phrase (lang_id, orthography_seq, definition, notes, original_context, status)
                        VALUES ($1, $2, $3, $4, $5, $6)
                        RETURNING id as "id: Option<InfluxResourceId>", lang_id as "lang_id: InfluxResourceId", orthography_seq, definition, notes, original_context, status as "status: TokenStatus"
                    "#,
                    phrase.lang_id.as_i64()?,
                    &phrase.orthography_seq,
                    phrase.definition,
                    phrase.notes,
                    phrase.original_context,
                    phrase.status as TokenStatus,
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }

    pub async fn query_phrase_by_id(&self, id: InfluxResourceId) -> Result<Option<Phrase>> {
        match self {
            Surreal { engine } => {
                let res = engine.select((TABLE, id)).await;
                match res {
                    Ok(Some::<Phrase>(v)) => Ok(Some(v)),
                    Ok(None) => Ok(None),
                    Err(e) => Err(anyhow::anyhow!("Error querying phrase: {:?}", e)),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Phrase,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", lang_id as "lang_id: InfluxResourceId", orthography_seq, definition, notes, original_context, status as "status: TokenStatus"
                        FROM phrase
                        WHERE id = $1
                    "#,
                    id.as_i64()?
                )
                .fetch_optional(pool.as_ref())
                .await?;
                Ok(record)
            }
        }
    }

    /// - requires that all orthography in orthography_seq is lowercase
    pub async fn query_phrase_by_onset_orthographies(
        &self,
        lang_id: InfluxResourceId,
        onset_orthography_set: HashSet<String>,
    ) -> Result<Vec<Phrase>> {
        match self {
            Surreal { engine } => {
                let sql = format!("SELECT * FROM phrase WHERE array::first(orthography_seq) INSIDE $onsets AND lang_id = $lang_id;");
                let mut res: Response = engine
                    .query(sql)
                    .bind((
                        "onsets",
                        onset_orthography_set
                            .iter()
                            .cloned()
                            .collect::<Vec<String>>(),
                    ))
                    .bind(("lang_id", lang_id))
                    .await?;
                match res.take(0) {
                    Ok::<Vec<Phrase>, _>(v) => Ok(v),
                    _ => Err(anyhow::anyhow!("Error querying phrase")),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Phrase,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", lang_id as "lang_id: InfluxResourceId", orthography_seq, definition, notes, original_context, status as "status: TokenStatus"
                        FROM phrase
                        WHERE orthography_seq[1] = ANY($1) AND lang_id = $2
                    "#,
                    &onset_orthography_set.iter().cloned().collect::<Vec<String>>(),
                    lang_id.as_i64()?,
                )
                .fetch_all(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }

    /// - requires that all orthography in orthography_seq is lowercase
    pub async fn query_phrase_by_orthography_seq(
        &self,
        lang_id: InfluxResourceId,
        orthography_seq: Vec<String>,
    ) -> Result<Vec<Phrase>> {
        match self {
            Surreal { engine } => {
                let sql = format!("SELECT * FROM phrase WHERE orthography_seq = $orthography_seq AND lang_id = $lang_id;");
                let mut res: Response = engine
                    .query(sql)
                    .bind(("orthography_seq", orthography_seq))
                    .bind(("lang_id", lang_id))
                    .await?;

                match res.take(0) {
                    Ok::<Vec<Phrase>, _>(v) => Ok(v),
                    _ => Err(anyhow::anyhow!("Error querying phrase")),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Phrase,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", lang_id as "lang_id: InfluxResourceId", orthography_seq, definition, notes, original_context, status as "status: TokenStatus"
                        FROM phrase
                        WHERE orthography_seq = $1 AND lang_id = $2
                    "#,
                    &orthography_seq,
                    lang_id.as_i64()?,
                )
                .fetch_all(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }

    /// - does not require that orthographies are lowercase. they will be converted to lowercase
    pub async fn get_phrases_from_text_set(
        &self,
        lang_id: InfluxResourceId,
        text_set: HashSet<String>,
    ) -> Result<Vec<Phrase>> {
        let onset_orthography_set: HashSet<String> = text_set
            .iter()
            .cloned()
            .map(|x| x.to_lowercase())
            .collect::<HashSet<String>>();
        self.query_phrase_by_onset_orthographies(lang_id, onset_orthography_set)
            .await
    }

    /// - does not require that orthographies are lowercase. they will be converted to lowercase
    pub async fn get_phrases_from_text_seq(
        &self,
        lang_id: InfluxResourceId,
        text_seq: Vec<String>,
    ) -> Result<Vec<Phrase>> {
        let onset_orthography_set: HashSet<String> = text_seq
            .iter()
            .cloned()
            .map(|x| x.to_lowercase())
            .collect::<HashSet<String>>();
        self.query_phrase_by_onset_orthographies(lang_id, onset_orthography_set)
            .await
    }

    /// - requires that all orthography in orthography_seq is lowercase
    /// - orthography_seq is already in database
    pub async fn update_phrase(&self, phrase: Phrase) -> Result<Phrase> {
        assert!(phrase
            .orthography_seq
            .iter()
            .all(|s| s.to_lowercase() == *s));
        assert!(phrase.id.is_some());
        let id = phrase.id.clone().unwrap();

        let existing_phrase = self.query_phrase_by_id(id.clone()).await?;
        assert!(existing_phrase.is_some());
        let existing_phrase = existing_phrase.unwrap();
        if phrase.orthography_seq != existing_phrase.orthography_seq {
            assert!(
                !self
                    .phrase_exists(phrase.lang_id.clone(), phrase.orthography_seq.clone())
                    .await?
            );
        }

        match self {
            Surreal { engine } => {
                let updated: Option<Phrase> = engine.update(("phrase", id)).content(phrase).await?;
                match updated {
                    Some(v) => Ok(v),
                    None => Err(anyhow::anyhow!("Error updating phrase")),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Phrase,
                    r#"
                        UPDATE phrase
                        SET lang_id = $1, orthography_seq = $2, definition = $3, notes = $4, original_context = $5, status = $6
                        WHERE id = $7
                        RETURNING id as "id: Option<InfluxResourceId>", lang_id as "lang_id: InfluxResourceId", orthography_seq, definition, notes, original_context, status as "status: TokenStatus"
                    "#,
                    phrase.lang_id.as_i64()?,
                    &phrase.orthography_seq,
                    phrase.definition,
                    phrase.notes,
                    phrase.original_context,
                    phrase.status as TokenStatus,
                    id.as_i64()?,
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }

    pub async fn delete_phrase(&self, id: InfluxResourceId) -> Result<Phrase> {
        match self {
            Surreal { engine } => {
                match engine.delete((TABLE, id)).await? {
                    Some::<Phrase>(v) => Ok(v),
                    None => Err(anyhow::anyhow!(
                        "Error deleting phrase, was it even in the database?"
                    )),
                }
            },
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Phrase,
                    r#"
                        DELETE FROM phrase
                        WHERE id = $1
                        RETURNING id as "id: Option<InfluxResourceId>", lang_id as "lang_id: InfluxResourceId", orthography_seq, definition, notes, original_context, status as "status: TokenStatus"
                    "#,
                    id.as_i64()?
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }
}

pub fn mk_phrase_trie(phrases: Vec<Phrase>) -> Trie<String, Phrase> {
    Trie::new_with_entries_and_payloads(
        phrases
            .into_iter()
            .map(|phrase| (phrase.orthography_seq.clone(), phrase))
            .collect::<Vec<(Vec<String>, Phrase)>>(),
    )
}

// mod tests {
//     use crate::db::DBLocation;
//     use super::*;

//     #[tokio::test]
//     async fn test_create_phrase() {
//         let db = DB::create_db(DBLocation::Mem).await;
//         let phrase = Phrase::essential_phrase("en_demo", vec!["hello".to_string(), "world".to_string()]);
//         let created = db.create_phrase(phrase).await.unwrap();
//         // dbg!("created: {:?}", created);
//         assert_eq!(created.orthography_seq, vec!["hello".to_string(), "world".to_string()]);
//     }

//     #[tokio::test]
//     async fn test_query_phrase() {
//         let db = DB::create_db(DBLocation::Mem).await;
//         let phrase = Phrase::essential_phrase("en_demo", vec!["hello".to_string(), "world".to_string()]);
//         let created = db.create_phrase(phrase).await.unwrap();
//         let phrase = Phrase::essential_phrase("en_demo", vec!["world".to_string(), "record".to_string()]);
//         let created = db.create_phrase(phrase).await.unwrap();
//         let phrase = Phrase::essential_phrase("en_demo", vec!["world".to_string(), "wide".to_string(), "web".to_string()]);
//         let created = db.create_phrase(phrase).await.unwrap();
//         let phrase = Phrase::essential_phrase("en_demo", vec!["hello".to_string(), "moon".to_string()]);
//         let created = db.create_phrase(phrase).await.unwrap();

//         let queried = db.query_phrase_by_onset_orthographies(vec!["hello".to_string()].into_iter().collect(), "en_demo".to_string()).await.unwrap();
//         // dbg!("queried: {:?}", &queried);
//         assert_eq!(queried.len(), 2);
//         assert!(queried.iter().any(|phrase| phrase.orthography_seq == vec!["hello".to_string(), "world".to_string()]));
//         assert!(queried.iter().any(|phrase| phrase.orthography_seq == vec!["hello".to_string(), "moon".to_string()]));

//         let queried = db.query_phrase_by_onset_orthographies(vec!["world".to_string(), "earth".to_string()].into_iter().collect(), "en_demo".to_string()).await.unwrap();
//         // dbg!("queried: {:?}", &queried);
//         assert_eq!(queried.len(), 2);
//         assert!(queried.iter().any(|phrase| phrase.orthography_seq == vec!["world".to_string(), "record".to_string()]));
//         assert!(queried.iter().any(|phrase| phrase.orthography_seq == vec!["world".to_string(), "wide".to_string(), "web".to_string()]));

//         let from_text_seq = db.get_phrases_from_text_seq(vec!["Hello".to_string(), "world".to_string(), "record".to_string()], "en_demo".to_string()).await.unwrap();
//         // dbg!("from_text_seq: {:?}", &from_text_seq);
//         assert_eq!(from_text_seq.len(), 4);
//         assert!(from_text_seq.iter().any(|phrase| phrase.orthography_seq == vec!["hello".to_string(), "world".to_string()]));
//         assert!(from_text_seq.iter().any(|phrase| phrase.orthography_seq == vec!["hello".to_string(), "moon".to_string()]));
//         assert!(from_text_seq.iter().any(|phrase| phrase.orthography_seq == vec!["world".to_string(), "record".to_string()]));
//         assert!(from_text_seq.iter().any(|phrase| phrase.orthography_seq == vec!["world".to_string(), "wide".to_string(), "web".to_string()]));
//     }

//     #[tokio::test]
//     async fn test_query_phrase_by_orthography_seq() {
//         let db = DB::create_db(DBLocation::Mem).await;
//         let phrase = Phrase::essential_phrase("en_demo", vec!["hello".to_string(), "moon".to_string()]);
//         let created = db.create_phrase(phrase).await.unwrap();

//         let updated = db.update_phrase_by_id(Phrase {
//             id: created.id.clone(),
//             lang_id: "en_demo".to_string(),
//             orthography_seq: vec!["hello".to_string(), "moon".to_string()],
//             definition: "placeholder".to_string(),
//             notes: "updated notes".to_string(),
//             original_context: "".to_string(),
//             status: TokenStatus::L5,
//             tags: vec![],
//             srs: SRSInfo::default(),
//         }).await.unwrap();

//         let queried = db.query_phrase_by_orthography_seq(vec!["hello".to_string(), "moon".to_string()], "en_demo".to_string()).await.unwrap();
//         assert_eq!(queried.len(), 1);
//         assert_eq!(queried[0].notes, "updated notes".to_string());
//     }
// }

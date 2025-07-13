///! a phrase is a user-defined multi-word token. phrases shall be added during a second pass tokenization process
use super::*;
use crate::db::{deserialize_surreal_thing, deserialize_surreal_thing_opt};
use crate::{db::InfluxResourceId, prelude::*, utils::trie::Trie};
use elm_rs::{Elm, ElmDecode, ElmEncode, ElmQuery, ElmQueryField};
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};
use vocab::TokenStatus;
use DB::*;

const TABLE: &str = "phrase";
pub fn mk_phrase_thing(id: String) -> Thing {
    Thing::from((TABLE.to_string(), id))
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash, Elm, ElmEncode, ElmDecode)]
pub struct Phrase {
    // #[serde(deserialize_with = "deserialize_surreal_thing_opt")]
    pub id: Option<InfluxResourceId>,
    // #[serde(deserialize_with = "deserialize_surreal_thing")]
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

    pub fn unmarked_phrase(lang_id: InfluxResourceId, orthography_seq: Vec<String>) -> Self {
        Phrase {
            id: None,
            lang_id: lang_id,
            orthography_seq: orthography_seq,
            definition: "".to_string(),
            notes: "".to_string(),
            original_context: "".to_string(),
            status: TokenStatus::UNMARKED,
        };
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
        onset_orthography_set: BTreeSet<String>,
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
        text_set: BTreeSet<String>,
    ) -> Result<Vec<Phrase>> {
        let onset_orthography_set: BTreeSet<String> = text_set
            .iter()
            .cloned()
            .map(|x| x.to_lowercase())
            .collect::<BTreeSet<String>>();
        self.query_phrase_by_onset_orthographies(lang_id, onset_orthography_set)
            .await
    }

    /// - does not require that orthographies are lowercase. they will be converted to lowercase
    pub async fn get_phrases_from_text_seq(
        &self,
        lang_id: InfluxResourceId,
        text_seq: Vec<String>,
    ) -> Result<Vec<Phrase>> {
        let onset_orthography_set: BTreeSet<String> = text_seq
            .iter()
            .cloned()
            .map(|x| x.to_lowercase())
            .collect::<BTreeSet<String>>();
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

    pub async fn delete_phrase_and_return_deleted(&self, phrase: Phrase) -> Result<Phrase> {
        let id = phrase.id.ok_or(anyhow::anyhow!("cannot delete if no id"))?;

        match self {
            Surreal { engine } => match engine.delete((TABLE, id)).await? {
                Some::<Phrase>(v) => Ok(v),
                None => Err(anyhow::anyhow!(
                    "Error deleting phrase, was it even in the database?"
                )),
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

    pub async fn delete_phrase_and_return_unmarked(&self, phrase: Phrase) -> Result<Phrase> {
        let unmarked_phrase = Phrase::unmarked_phrase(phrase.lang_id.clone(), phrase.orthography_seq.clone());
        let _ = self.delete_phrase_and_return_deleted(phrase).await?;
        Ok(unmarked_phrase)
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

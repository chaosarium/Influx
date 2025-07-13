use super::*;
use crate::db::{deserialize_surreal_thing, deserialize_surreal_thing_opt};

use crate::{db::InfluxResourceId, prelude::*};
use anyhow::Result;
use elm_rs::{Elm, ElmDecode, ElmEncode, ElmQuery, ElmQueryField};
use log::warn;
use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};
use DB::*;

#[derive(
    Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash, Elm, ElmEncode, ElmDecode, sqlx::Type,
)]
#[sqlx(type_name = "token_status")]
pub enum TokenStatus {
    UNMARKED,
    L1,
    L2,
    L3,
    L4,
    L5,
    KNOWN,
    IGNORED,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash, Elm, ElmEncode, ElmDecode)]
pub struct Token {
    // #[serde(deserialize_with = "deserialize_surreal_thing_opt")]
    pub id: Option<InfluxResourceId>,
    // #[serde(deserialize_with = "deserialize_surreal_thing")]
    pub lang_id: InfluxResourceId,

    pub orthography: String,
    pub phonetic: String,
    pub definition: String,
    pub notes: String,
    pub original_context: String,

    pub status: TokenStatus,
}

impl Token {
    pub fn unmarked_token(lang_id: InfluxResourceId, orthography: &str) -> Self {
        Token {
            id: None,
            orthography: orthography.to_string(),
            lang_id: lang_id,
            phonetic: "".to_string(),
            status: TokenStatus::UNMARKED,
            definition: "".to_string(),
            notes: "".to_string(),
            original_context: "".to_string(),
        }
    }

    pub fn essential_token(lang_id: InfluxResourceId, orthography: &str) -> Self {
        Token {
            id: None,
            orthography: orthography.to_string(),
            lang_id: lang_id,
            phonetic: "".to_string(),
            status: TokenStatus::L1,
            definition: "".to_string(),
            notes: "".to_string(),
            original_context: "".to_string(),
        }
    }

    pub fn fancier_token(
        lang_id: InfluxResourceId,
        orthography: &str,
        definition: &str,
        phonetic: &str,
        status: TokenStatus,
    ) -> Self {
        Token {
            id: None,
            orthography: orthography.to_string(),
            lang_id: lang_id,
            phonetic: phonetic.to_string(),
            status: status,
            definition: definition.to_string(),
            notes: "".to_string(),
            original_context: "".to_string(),
        }
    }
}

impl DB {
    /// - requires that orthography is lowercase
    pub async fn token_exists(
        &self,
        lang_id: InfluxResourceId,
        orthography: String,
    ) -> Result<bool> {
        debug_assert!(orthography.to_lowercase() == orthography);
        match self {
            Surreal { engine } => {
                let sql = format!(
                    "SELECT * FROM token WHERE orthography = $orthography AND lang_id = $lang_id"
                );
                let mut res: Response = engine
                    .query(sql)
                    .bind(("orthography", orthography))
                    .bind(("lang_id", lang_id))
                    .await?;

                match res.take(0) {
                    Ok(v) => Ok({
                        let tkns: Vec<Token> = v;
                        tkns.len() != 0
                    }),
                    Err(e) => Err(anyhow::anyhow!("Error querying token: {:?}", e)),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query!(
                    r#"
                        SELECT id FROM token WHERE orthography = LOWER($1) AND lang_id = $2;
                    "#,
                    orthography,
                    lang_id.as_i64()?
                )
                .fetch_all(pool.as_ref())
                .await?;

                Ok(record.len() > 0)
            }
        }
    }

    /// - requires that orthography is lowercase
    /// - requires that orthography is not already in database
    pub async fn create_token(&self, token: Token) -> Result<Token> {
        debug_assert!(token.orthography.to_lowercase() == token.orthography);
        assert!(token.id.is_none());
        assert!(
            self.token_exists(token.lang_id.clone(), token.orthography.clone())
                .await?
                == false
        );

        if token.status == TokenStatus::UNMARKED {
            return Err(anyhow::anyhow!("cannot create token with status UNMARKED"));
        };

        match self {
            Surreal { engine } => {
                let sql = format!("CREATE vocab CONTENT $tkn");
                let mut res: Response = engine.query(sql).bind(("tkn", token)).await?;

                // dbg!(&res);
                match res.take(0) {
                    Ok(Some::<Token>(v)) => Ok(v),
                    Ok(None) => Err(anyhow::anyhow!("sql didn't fail but no token was returned")),
                    Err(e) => Err(anyhow::anyhow!("Error creating token: {:?}", e)),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Token,
                    r#"
                        INSERT INTO token (orthography, phonetic, definition, notes, original_context, status, lang_id)
                        VALUES ($1, $2, $3, $4, $5, $6, $7)
                        RETURNING id as "id: Option<InfluxResourceId>", orthography, phonetic, definition, notes, original_context, status as "status: TokenStatus", lang_id
                    "#,
                    token.orthography,
                    token.phonetic,
                    token.definition,
                    token.notes,
                    token.original_context,
                    token.status as TokenStatus,
                    token.lang_id.as_i64()?
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }

    /// - requires that orthography is lowercase
    pub async fn query_token_by_orthography(
        &self,
        lang_id: InfluxResourceId,
        orthography: String,
    ) -> Result<Option<Token>> {
        debug_assert!(orthography.to_lowercase() == orthography);

        match self {
            Surreal { engine } => {
                let sql = format!(
                    "SELECT * FROM vocab WHERE orthography = $orthography AND lang_id = $lang_id"
                );
                let mut res: Response = engine
                    .query(sql)
                    .bind(("orthography", orthography))
                    .bind(("lang_id", lang_id))
                    .await?;

                dbg!(&res);
                match res.take(0) {
                    // Ok(Some::<Token>(v)) => Ok(Some(v)),
                    // Ok(None) => Ok(None),
                    Ok(v) => Ok({
                        let tkns: Vec<Token> = v;
                        if tkns.len() == 0 {
                            None
                        } else if tkns.len() == 1 {
                            Some(tkns[0].clone())
                        } else {
                            warn!("More than one token returned for query_token_by_orthography, returning first token");
                            Some(tkns[0].clone())
                        }
                    }),
                    Err(e) => Err(anyhow::anyhow!("Error querying token: {:?}", e)),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Token,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", orthography, phonetic, definition, notes, original_context, status as "status: TokenStatus", lang_id
                        FROM token
                        WHERE orthography = LOWER($1) AND lang_id = $2;
                    "#,
                    orthography,
                    lang_id.as_i64()?
                )
                .fetch_optional(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }

    pub async fn query_token_by_lang_identifier_and_orthography(
        &self,
        lang_identifier: String,
        orthography: String,
    ) -> Result<Option<Token>> {
        let lang_id = self.get_language_by_identifier(lang_identifier).await?;
        match lang_id {
            Some(lang_id) => {
                self.query_token_by_orthography(lang_id.id.unwrap(), orthography)
                    .await
            }
            None => Ok(None),
        }
    }

    pub async fn query_token_by_id(&self, id: InfluxResourceId) -> Result<Option<Token>> {
        match self {
            Surreal { engine } => {
                let res = engine.select(("token", id)).await;
                match res {
                    Ok(Some::<Token>(v)) => Ok(Some(v)),
                    Ok(None) => Ok(None),
                    Err(e) => Err(anyhow::anyhow!("Error querying token: {:?}", e)),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Token,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", orthography, phonetic, definition, notes, original_context, status as "status: TokenStatus", lang_id
                        FROM token
                        WHERE id = $1;
                    "#,
                    id.as_i64()?
                )
                .fetch_optional(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }

    /// - requires that orthographies are lowercase
    pub async fn query_tokens_by_orthographies(
        &self,
        lang_id: InfluxResourceId,
        orthography_set: &BTreeSet<String>,
    ) -> Result<Vec<Token>> {
        orthography_set
            .iter()
            .for_each(|orthography| debug_assert!(orthography.to_lowercase() == *orthography));

        match self {
            Surreal { engine } => {
                let sql = format!("SELECT * FROM vocab WHERE orthography INSIDE $orthography AND lang_id = $lang_id");
                let mut res: Response = engine
                    .query(sql)
                    .bind(("lang_id", lang_id))
                    .bind((
                        "orthography",
                        orthography_set.iter().cloned().collect::<Vec<String>>(),
                    ))
                    .await?;
                match res.take(0) {
                    Ok::<Vec<Token>, _>(v) => Ok(v),
                    _ => Err(anyhow::anyhow!("Error querying token")),
                }
            }
            Postgres { pool } => {
                let orthography_vec: Vec<String> = orthography_set.iter().cloned().collect();
                let records = sqlx::query_as!(
                    Token,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", orthography, phonetic, definition, notes, original_context, status as "status: TokenStatus", lang_id
                        FROM token
                        WHERE lang_id = $1 AND orthography = ANY($2);
                    "#,
                    lang_id.as_i64()?,
                    &orthography_vec
                )
                .fetch_all(pool.as_ref())
                .await?;
                Ok(records)
            }
        }
    }

    pub async fn delete_token_and_return_deleted(&self, token: Token) -> Result<Token> {
        let id = token.id.ok_or(anyhow::anyhow!("cannot delete if no id"))?;

        match self {
            Surreal { engine } => {
                let res = engine.delete(("token", id)).await;
                match res {
                    Ok(Some::<Token>(v)) => Ok(v),
                    Ok(None) => Err(anyhow::anyhow!(
                        "Error deleting token, was it even in the database?"
                    )),
                    Err(e) => Err(anyhow::anyhow!("Error deleting token: {:?}", e)),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Token,
                    r#"
                        DELETE FROM token
                        WHERE id = $1
                        RETURNING id as "id: Option<InfluxResourceId>", orthography, phonetic, definition, notes, original_context, status as "status: TokenStatus", lang_id
                    "#,
                    id.as_i64()?
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }

    pub async fn delete_token_and_return_unmarked(&self, token: Token) -> Result<Token> {
        let unmarked_token = Token::unmarked_token(token.lang_id.clone(), &token.orthography);
        let _ = Self::delete_token_and_return_deleted(self, token).await?;
        Ok(unmarked_token)
    }

    /// - query tokens, return set with unmarked tokens for missing orthographies
    /// - requires that orthographies are lowercase
    pub async fn get_dict_from_orthography_set(
        &self,
        lang_id: InfluxResourceId,
        orthography_set: BTreeSet<String>,
    ) -> Result<BTreeMap<String, Token>> {
        let query_result = self
            .query_tokens_by_orthographies(lang_id.clone(), &orthography_set)
            .await?;

        // loop through sequence, apply token if found, otherwise apply UNMARKED token
        let populated_seq: BTreeMap<String, Token> = orthography_set
            .iter()
            .map(|orthography| {
                (
                    orthography.to_string(),
                    query_result
                        .iter()
                        .find(|token| token.orthography == *orthography) // BUG many case sensitivity issues
                        .map(|token| Token::clone(token))
                        .unwrap_or(Token::unmarked_token(lang_id.clone(), orthography)),
                )
            })
            .collect::<BTreeMap<String, Token>>()
            .into();

        Ok(populated_seq)
    }

    /// - requires that orthographies are lowercase
    pub async fn get_dict_from_orthography_seq(
        &self,
        lang_id: InfluxResourceId,
        orthography_seq: Vec<String>,
    ) -> Result<BTreeMap<String, Token>> {
        let orthography_set: BTreeSet<String> = orthography_seq
            .iter()
            .cloned()
            .collect::<BTreeSet<String>>();
        self.get_dict_from_orthography_set(lang_id, orthography_set)
            .await
    }

    /// - does not require that orthographies are lowercase. they will be converted to lowercase
    pub async fn get_dict_from_text_set(
        &self,
        lang_id: InfluxResourceId,
        text_set: BTreeSet<String>,
    ) -> Result<BTreeMap<String, Token>> {
        let orthography_set: BTreeSet<String> = text_set
            .iter()
            .cloned()
            .map(|x| x.to_lowercase())
            .collect::<BTreeSet<String>>();
        self.get_dict_from_orthography_set(lang_id, orthography_set)
            .await
    }

    /// - does not require that orthographies are lowercase. they will be converted to lowercase
    pub async fn get_dict_from_text_seq(
        &self,
        lang_id: InfluxResourceId,
        text_seq: Vec<String>,
    ) -> Result<BTreeMap<String, Token>> {
        let orthography_set: BTreeSet<String> = text_seq
            .iter()
            .cloned()
            .map(|x| x.to_lowercase())
            .collect::<BTreeSet<String>>();
        self.get_dict_from_orthography_set(lang_id, orthography_set)
            .await
    }

    /// - requires the token to have an id and previously exist in the database
    /// - requires that orthography is lowercase
    /// - fails if changing orthography while the new orthography is already in database
    pub async fn update_token(&self, token: Token) -> Result<Token> {
        assert!(token.id.is_some());
        assert!(token.orthography.to_lowercase() == token.orthography);
        let id = token.id.clone().unwrap();
        let existing_token = self.query_token_by_id(id.clone()).await?;
        assert!(existing_token.is_some());
        let existing_token = existing_token.unwrap();
        if token.orthography != existing_token.orthography {
            if self
                .token_exists(token.lang_id.clone(), token.orthography.clone())
                .await?
            {
                return Err(anyhow::anyhow!(
                    "Error updating token: changing orthography to one that already exists"
                ));
            }
        }

        match self {
            Surreal { engine } => {
                let updated: Option<Token> = engine.update(("token", id)).content(token).await?;

                match updated {
                    Some(v) => Ok(v),
                    None => Err(anyhow::anyhow!("Error updating token")),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    Token,
                    r#"
                        UPDATE token
                        SET orthography = $1, phonetic = $2, definition = $3, notes = $4, original_context = $5, status = $6
                        WHERE id = $7
                        RETURNING id as "id: Option<InfluxResourceId>", orthography, phonetic, definition, notes, original_context, status as "status: TokenStatus", lang_id
                    "#,
                    token.orthography,
                    token.phonetic,
                    token.definition,
                    token.notes,
                    token.original_context,
                    token.status as TokenStatus,
                    id.as_i64()?
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }
}

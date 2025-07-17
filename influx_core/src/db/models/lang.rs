use crate::db::InfluxResourceId;

use super::*;
use crate::db::deserialize_surreal_thing_opt;
use std::collections::HashMap;
use surrealdb::RecordId;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash, Elm, ElmEncode, ElmDecode)]
pub struct LanguageEntry {
    #[serde(deserialize_with = "deserialize_surreal_thing_opt")]
    pub id: Option<InfluxResourceId>,
    // for now, code is used to tell tokenizers what model to use
    pub code: String,
    pub name: String,
    pub dicts: Vec<String>,
}

use DB::*;

impl DB {
    // Method removed - no longer using identifiers

    pub async fn create_language(&self, language: LanguageEntry) -> Result<LanguageEntry> {
        assert!(language.id.is_none());
        match self {
            Surreal { engine } => {
                let created: Result<Option<LanguageEntry>, surrealdb::Error> =
                    engine.create("language").content(language).await;

                match created {
                    Ok(Some(entry)) => Ok(entry),
                    Ok(None) => Err(anyhow::anyhow!("somehow got none")),
                    Err(e) => Err(anyhow::anyhow!("Error creating language: {}", e)),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    LanguageEntry,
                    r#"
                        INSERT INTO language (code, name, dicts)
                        VALUES ($1, $2, $3)
                        RETURNING id as "id: Option<InfluxResourceId>", code, name, dicts
                    "#,
                    language.code,
                    language.name,
                    &language.dicts
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }

    pub async fn get_languages_vec(&self) -> Result<Vec<LanguageEntry>> {
        match self {
            Surreal { engine } => {
                let languages: Result<Vec<LanguageEntry>, surrealdb::Error> =
                    engine.select("language").await;

                match languages {
                    Ok(v) => Ok(v),
                    Err(e) => Err(anyhow::anyhow!("Error getting languages: {}", e)),
                }
            }
            Postgres { pool } => {
                let records = sqlx::query_as!(
                    LanguageEntry,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", code, name, dicts
                        FROM language
                    "#
                )
                .fetch_all(pool.as_ref())
                .await?;

                Ok(records)
            }
        }
    }

    pub async fn get_language(&self, id: InfluxResourceId) -> Result<Option<LanguageEntry>> {
        match self {
            Surreal { engine } => {
                let language: Result<Option<LanguageEntry>, surrealdb::Error> =
                    engine.select(("language", id)).await;

                match language {
                    Ok(v) => Ok(v),
                    Err(e) => Err(anyhow::anyhow!("Error getting language: {}", e)),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    LanguageEntry,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", code, name, dicts
                        FROM language
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
}

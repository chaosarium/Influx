use crate::db::InfluxResourceId;

use super::*;
use crate::db::deserialize_surreal_thing_opt;
use std::collections::HashMap;
use surrealdb::RecordId;

#[derive(
    Debug, Serialize, Deserialize, Clone, PartialEq, Elm, ElmEncode, ElmDecode, sqlx::FromRow,
)]
pub struct ParserConfig {
    pub parser_type: String,         // "base_spacy" or "enhanced_japanese"
    pub spacy_model: Option<String>, // for base_spacy parser
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Elm, ElmEncode, ElmDecode)]
pub struct LanguageEntry {
    pub id: Option<InfluxResourceId>,
    pub code: String,
    pub name: String,
    pub dicts: Vec<String>,
    pub tts_rate: Option<f64>,
    pub tts_pitch: Option<f64>,
    pub tts_voice: Option<String>,
    pub deepl_source_lang: Option<String>,
    pub deepl_target_lang: Option<String>,
    pub parser_config: ParserConfig,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, PartialEq)]
pub struct LanguageEntryDB {
    pub id: InfluxResourceId,
    pub code: String,
    pub name: String,
    pub dicts: Vec<String>,
    pub tts_rate: Option<f64>,
    pub tts_pitch: Option<f64>,
    pub tts_voice: Option<String>,
    pub deepl_source_lang: Option<String>,
    pub deepl_target_lang: Option<String>,
    pub parser_config: sqlx::types::Json<ParserConfig>,
}

impl From<LanguageEntryDB> for LanguageEntry {
    fn from(db_entry: LanguageEntryDB) -> Self {
        LanguageEntry {
            id: Some(db_entry.id),
            code: db_entry.code,
            name: db_entry.name,
            dicts: db_entry.dicts,
            tts_rate: db_entry.tts_rate,
            tts_pitch: db_entry.tts_pitch,
            tts_voice: db_entry.tts_voice,
            deepl_source_lang: db_entry.deepl_source_lang,
            deepl_target_lang: db_entry.deepl_target_lang,
            parser_config: db_entry.parser_config.0,
        }
    }
}

use DB::*;

impl DB {
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
                    LanguageEntryDB,
                    r#"
                        INSERT INTO language (code, name, dicts, tts_rate, tts_pitch, tts_voice, deepl_source_lang, deepl_target_lang, parser_config )
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                        RETURNING id, code, name, dicts, tts_rate, tts_pitch, tts_voice, deepl_source_lang, deepl_target_lang, parser_config as "parser_config: sqlx::types::Json<ParserConfig>"
                    "#,
                    language.code,
                    language.name,
                    &language.dicts,
                    language.tts_rate,
                    language.tts_pitch,
                    language.tts_voice,
                    language.deepl_source_lang,
                    language.deepl_target_lang,
                    serde_json::to_value(&language.parser_config)?
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record.into())
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
                let records: Vec<LanguageEntry> = sqlx::query_as!( 
                    LanguageEntryDB,
                    r#"
                        SELECT id, code, name, dicts, tts_rate, tts_pitch, tts_voice, deepl_source_lang, deepl_target_lang, parser_config as "parser_config: sqlx::types::Json<ParserConfig>"
                        FROM language
                    "#
                )
                .fetch_all(pool.as_ref())
                .await?.into_iter().map(Into::into).collect();

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
                    LanguageEntryDB,
                    r#"
                        SELECT id, code, name, dicts, tts_rate, tts_pitch, tts_voice, deepl_source_lang, deepl_target_lang, parser_config as "parser_config: sqlx::types::Json<ParserConfig>"
                        FROM language
                        WHERE id = $1;
                    "#,
                    id.as_i64()?
                )
                .fetch_optional(pool.as_ref())
                .await?.map(Into::into);

                Ok(record)
            }
        }
    }

    pub async fn update_language(&self, language: LanguageEntry) -> Result<LanguageEntry> {
        let id = language
            .id
            .as_ref()
            .ok_or_else(|| anyhow::anyhow!("Language ID is required for update"))?;

        match self {
            Surreal { engine } => {
                let updated: Result<Option<LanguageEntry>, surrealdb::Error> =
                    engine.update(("language", id)).content(language).await;

                match updated {
                    Ok(Some(entry)) => Ok(entry),
                    Ok(None) => Err(anyhow::anyhow!("Language not found for update")),
                    Err(e) => Err(anyhow::anyhow!("Error updating language: {}", e)),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    LanguageEntryDB,
                    r#"
                        UPDATE language 
                        SET code = $2, name = $3, dicts = $4, tts_rate = $5, tts_pitch = $6, tts_voice = $7, deepl_source_lang = $8, deepl_target_lang = $9, parser_config = $10
                        WHERE id = $1
                        RETURNING id, code, name, dicts, tts_rate, tts_pitch, tts_voice, deepl_source_lang, deepl_target_lang, parser_config as "parser_config: sqlx::types::Json<ParserConfig>"
                    "#,
                    id.as_i64()?,
                    language.code,
                    language.name,
                    &language.dicts,
                    language.tts_rate,
                    language.tts_pitch,
                    language.tts_voice,
                    language.deepl_source_lang,
                    language.deepl_target_lang,
                    serde_json::to_value(&language.parser_config)?
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record.into())
            }
        }
    }
}

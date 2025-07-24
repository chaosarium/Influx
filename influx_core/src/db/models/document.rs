use super::*;
use crate::db::deserialize_surreal_thing_opt;
use crate::db::InfluxResourceId;
use chrono::{DateTime, Utc};
use std::collections::HashMap;
use time::OffsetDateTime;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Elm, ElmEncode, ElmDecode)]
pub struct Document {
    pub id: Option<InfluxResourceId>,
    pub lang_id: InfluxResourceId,
    pub title: String,
    pub content: String,
    pub doc_type: String,
    pub tags: Vec<String>,
    pub created_ts: DateTime<Utc>,
    pub updated_ts: DateTime<Utc>,
}

#[derive(Debug, Clone, Deserialize, Serialize, Elm, ElmEncode, ElmDecode)]
pub struct DocPackage {
    pub document_id: InfluxResourceId,
    pub language_id: InfluxResourceId,
    pub document: Document,
    pub language: crate::db::models::lang::LanguageEntry,
}

use DB::*;

impl DB {
    pub async fn create_document(&self, document: Document) -> Result<Document> {
        assert!(document.id.is_none());
        match self {
            Surreal { engine: _ } => {
                // SurrealDB is deprecated, skip implementation
                Err(anyhow::anyhow!("SurrealDB is deprecated"))
            }
            Postgres { pool } => {
                let record = sqlx::query!(
                    r#"
                        INSERT INTO document (lang_id, title, content, doc_type, tags)
                        VALUES ($1, $2, $3, $4, $5)
                        RETURNING id, lang_id, title, content, doc_type, tags, created_ts, updated_ts
                    "#,
                    document.lang_id.as_i64()?,
                    document.title,
                    document.content,
                    document.doc_type,
                    &document.tags
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(Document {
                    id: Some(InfluxResourceId::SerialId(record.id)),
                    lang_id: InfluxResourceId::SerialId(record.lang_id),
                    title: record.title,
                    content: record.content,
                    doc_type: record.doc_type,
                    tags: record.tags,
                    created_ts: DateTime::<Utc>::from_timestamp(
                        record.created_ts.unix_timestamp(),
                        0,
                    )
                    .unwrap(),
                    updated_ts: DateTime::<Utc>::from_timestamp(
                        record.updated_ts.unix_timestamp(),
                        0,
                    )
                    .unwrap(),
                })
            }
        }
    }

    pub async fn get_documents(
        &self,
        lang_id: Option<InfluxResourceId>,
    ) -> Result<Vec<DocPackage>> {
        match self {
            Surreal { engine: _ } => {
                // SurrealDB is deprecated, skip implementation
                Err(anyhow::anyhow!("SurrealDB is deprecated"))
            }
            Postgres { pool } => {
                let lang_id_i64 = match &lang_id {
                    Some(id) => Some(id.as_i64()?),
                    None => None,
                };

                let records = sqlx::query!(
                    r#"
                        SELECT 
                            d.id, d.lang_id, d.title, d.content, d.doc_type, d.tags, d.created_ts, d.updated_ts,
                            l.code as lang_code, l.name as lang_name, l.dicts as lang_dicts,
                            l.tts_rate as lang_tts_rate, l.tts_pitch as lang_tts_pitch, l.tts_voice as lang_tts_voice
                        FROM document d
                        JOIN language l ON d.lang_id = l.id
                        WHERE ($1::bigint IS NULL OR d.lang_id = $1)
                        ORDER BY d.created_ts ASC
                    "#,
                    lang_id_i64
                )
                .fetch_all(pool.as_ref())
                .await?;

                let doc_packages = records
                    .into_iter()
                    .map(|record| DocPackage {
                        document_id: InfluxResourceId::SerialId(record.id),
                        language_id: InfluxResourceId::SerialId(record.lang_id),
                        document: Document {
                            id: Some(InfluxResourceId::SerialId(record.id)),
                            lang_id: InfluxResourceId::SerialId(record.lang_id),
                            title: record.title,
                            content: record.content,
                            doc_type: record.doc_type,
                            tags: record.tags,
                            created_ts: DateTime::<Utc>::from_timestamp(
                                record.created_ts.unix_timestamp(),
                                0,
                            )
                            .unwrap(),
                            updated_ts: DateTime::<Utc>::from_timestamp(
                                record.updated_ts.unix_timestamp(),
                                0,
                            )
                            .unwrap(),
                        },
                        language: crate::db::models::lang::LanguageEntry {
                            id: Some(InfluxResourceId::SerialId(record.lang_id)),
                            code: record.lang_code,
                            name: record.lang_name,
                            dicts: record.lang_dicts,
                            tts_rate: record.lang_tts_rate,
                            tts_pitch: record.lang_tts_pitch,
                            tts_voice: record.lang_tts_voice,
                            deepl_source_lang: None, // TODO questionable
                            deepl_target_lang: None,
                            parser_config: crate::db::models::lang::ParserConfig {
                                which_parser: "base_spacy".to_string(),
                                parser_args: {
                                    let mut args = HashMap::new();
                                    args.insert(
                                        "spacy_model".to_string(),
                                        "en_core_web_sm".to_string(),
                                    );
                                    args
                                },
                            },
                        },
                    })
                    .collect();

                Ok(doc_packages)
            }
        }
    }

    pub async fn get_document_by_id(&self, id: InfluxResourceId) -> Result<Option<Document>> {
        match self {
            Surreal { engine: _ } => {
                // SurrealDB is deprecated, skip implementation
                Err(anyhow::anyhow!("SurrealDB is deprecated"))
            }
            Postgres { pool } => {
                let record = sqlx::query!(
                    r#"
                        SELECT id, lang_id, title, content, doc_type, tags, created_ts, updated_ts
                        FROM document
                        WHERE id = $1
                    "#,
                    id.as_i64()?
                )
                .fetch_optional(pool.as_ref())
                .await?;

                Ok(record.map(|r| Document {
                    id: Some(InfluxResourceId::SerialId(r.id)),
                    lang_id: InfluxResourceId::SerialId(r.lang_id),
                    title: r.title,
                    content: r.content,
                    doc_type: r.doc_type,
                    tags: r.tags,
                    created_ts: DateTime::<Utc>::from_timestamp(r.created_ts.unix_timestamp(), 0)
                        .unwrap(),
                    updated_ts: DateTime::<Utc>::from_timestamp(r.updated_ts.unix_timestamp(), 0)
                        .unwrap(),
                }))
            }
        }
    }

    pub async fn update_document(&self, document: Document) -> Result<Document> {
        assert!(document.id.is_some());
        match self {
            Surreal { engine: _ } => {
                // SurrealDB is deprecated, skip implementation
                Err(anyhow::anyhow!("SurrealDB is deprecated"))
            }
            Postgres { pool } => {
                let record = sqlx::query!(
                    r#"
                        UPDATE document 
                        SET title = $2, content = $3, doc_type = $4, tags = $5, lang_id = $6
                        WHERE id = $1
                        RETURNING id, lang_id, title, content, doc_type, tags, created_ts, updated_ts
                    "#,
                    document.id.unwrap().as_i64()?,
                    document.title,
                    document.content,
                    document.doc_type,
                    &document.tags,
                    document.lang_id.as_i64()?
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(Document {
                    id: Some(InfluxResourceId::SerialId(record.id)),
                    lang_id: InfluxResourceId::SerialId(record.lang_id),
                    title: record.title,
                    content: record.content,
                    doc_type: record.doc_type,
                    tags: record.tags,
                    created_ts: DateTime::<Utc>::from_timestamp(
                        record.created_ts.unix_timestamp(),
                        0,
                    )
                    .unwrap(),
                    updated_ts: DateTime::<Utc>::from_timestamp(
                        record.updated_ts.unix_timestamp(),
                        0,
                    )
                    .unwrap(),
                })
            }
        }
    }

    pub async fn delete_document(&self, id: InfluxResourceId) -> Result<()> {
        match self {
            Surreal { engine: _ } => {
                // SurrealDB is deprecated, skip implementation
                Err(anyhow::anyhow!("SurrealDB is deprecated"))
            }
            Postgres { pool } => {
                sqlx::query!(
                    r#"
                        DELETE FROM document WHERE id = $1
                    "#,
                    id.as_i64()?
                )
                .execute(pool.as_ref())
                .await?;

                Ok(())
            }
        }
    }

    pub async fn get_annotated_document_cache(
        &self,
        document_id: InfluxResourceId,
        text_checksum: &str,
    ) -> Result<Option<serde_json::Value>> {
        match self {
            Surreal { engine: _ } => {
                // SurrealDB is deprecated, skip implementation
                Err(anyhow::anyhow!("SurrealDB is deprecated"))
            }
            Postgres { pool } => {
                let record = sqlx::query!(
                    r#"
                        SELECT cached_data
                        FROM annotated_document_cache
                        WHERE document_id = $1 AND text_checksum = $2
                    "#,
                    document_id.as_i64()?,
                    text_checksum
                )
                .fetch_optional(pool.as_ref())
                .await?;

                Ok(record.map(|r| r.cached_data))
            }
        }
    }

    pub async fn set_annotated_document_cache(
        &self,
        document_id: InfluxResourceId,
        text_checksum: &str,
        cached_data: &serde_json::Value,
    ) -> Result<()> {
        match self {
            Surreal { engine: _ } => {
                // SurrealDB is deprecated, skip implementation
                Err(anyhow::anyhow!("SurrealDB is deprecated"))
            }
            Postgres { pool } => {
                sqlx::query!(
                    r#"
                        INSERT INTO annotated_document_cache (document_id, text_checksum, cached_data)
                        VALUES ($1, $2, $3)
                        ON CONFLICT (document_id, text_checksum)
                        DO UPDATE SET cached_data = EXCLUDED.cached_data, updated_ts = CURRENT_TIMESTAMP
                    "#,
                    document_id.as_i64()?,
                    text_checksum,
                    cached_data
                )
                .execute(pool.as_ref())
                .await?;

                Ok(())
            }
        }
    }
}

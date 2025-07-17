use super::*;
use crate::db::deserialize_surreal_thing_opt;
use crate::db::InfluxResourceId;
use chrono::{DateTime, Utc};
use time::OffsetDateTime;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Elm, ElmEncode, ElmDecode)]
pub struct Document {
    #[serde(deserialize_with = "deserialize_surreal_thing_opt")]
    pub id: Option<InfluxResourceId>,
    pub lang_id: InfluxResourceId,
    pub title: String,
    pub content: String,
    pub doc_type: String,
    pub tags: Vec<String>,
    pub created_ts: DateTime<Utc>,
    pub updated_ts: DateTime<Utc>,
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

    pub async fn get_all_documents(&self) -> Result<Vec<crate::doc_store::DocEntry>> {
        match self {
            Surreal { engine: _ } => {
                // SurrealDB is deprecated, skip implementation
                Err(anyhow::anyhow!("SurrealDB is deprecated"))
            }
            Postgres { pool } => {
                let records = sqlx::query!(
                    r#"
                        SELECT 
                            d.id, d.lang_id, d.title, d.content, d.doc_type, d.tags, d.created_ts, d.updated_ts,
                            l.code as lang_code, l.name as lang_name, l.dicts as lang_dicts
                        FROM document d
                        JOIN language l ON d.lang_id = l.id
                        ORDER BY d.created_ts ASC
                    "#
                )
                .fetch_all(pool.as_ref())
                .await?;

                let doc_entries = records
                    .into_iter()
                    .map(|record| {
                        let doc_type = match record.doc_type.as_str() {
                            "Video" => crate::doc_store::DocType::Video,
                            "Audio" => crate::doc_store::DocType::Audio,
                            _ => crate::doc_store::DocType::Text,
                        };

                        crate::doc_store::DocEntry {
                            id: InfluxResourceId::SerialId(record.id),
                            language: crate::db::models::lang::LanguageEntry {
                                id: Some(InfluxResourceId::SerialId(record.lang_id)),
                                code: record.lang_code,
                                name: record.lang_name,
                                dicts: record.lang_dicts,
                            },
                            title: record.title,
                            doc_type,
                            tags: record.tags,
                            date_created: DateTime::<Utc>::from_timestamp(
                                record.created_ts.unix_timestamp(),
                                0,
                            )
                            .unwrap(),
                            date_modified: DateTime::<Utc>::from_timestamp(
                                record.updated_ts.unix_timestamp(),
                                0,
                            )
                            .unwrap(),
                        }
                    })
                    .collect();

                Ok(doc_entries)
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
                        SET title = $2, content = $3, doc_type = $4, tags = $5
                        WHERE id = $1
                        RETURNING id, lang_id, title, content, doc_type, tags, created_ts, updated_ts
                    "#,
                    document.id.unwrap().as_i64()?,
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
}

use crate::db::InfluxResourceId;

use super::*;
use crate::db::deserialize_surreal_thing_opt;
use std::collections::HashMap;
use surrealdb::RecordId;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash, Elm, ElmEncode, ElmDecode)]
pub struct LanguageEntry {
    #[serde(deserialize_with = "deserialize_surreal_thing_opt")]
    pub id: Option<InfluxResourceId>,
    pub identifier: String,
    // see https://github.com/stanfordnlp/stanza/blob/af3d42b70ef2d82d96f410214f98dd17dd983f51/stanza/models/common/constant.py#L479
    // lang code mostly gets used for that
    pub code: String,
    pub name: String,
    pub dicts: Vec<String>,
}

use DB::*;

impl DB {
    pub async fn language_identifier_exists(&self, identifier: String) -> Result<bool> {
        match self {
            Surreal { engine } => {
                let sql = format!("SELECT * FROM language WHERE identifier = $identifier");
                let mut res: Response = engine.query(sql).bind(("identifier", identifier)).await?;

                match res.take(0) {
                    Ok::<Vec<LanguageEntry>, _>(v) => Ok(v.len() > 0),
                    _ => Err(anyhow::anyhow!("Error querying phrase")),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query!(
                    r#"
                        SELECT * FROM language WHERE identifier = $1;
                    "#,
                    identifier
                )
                .fetch_all(pool.as_ref())
                .await?;

                Ok(record.len() > 0)
            }
        }
    }

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
                        INSERT INTO language (identifier, code, name, dicts)
                        VALUES ($1, $2, $3, $4)
                        RETURNING id as "id: Option<InfluxResourceId>", identifier, code, name, dicts
                    "#,
                    language.identifier,
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
                        SELECT id as "id: Option<InfluxResourceId>", identifier, code, name, dicts
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
                        SELECT id as "id: Option<InfluxResourceId>", identifier, code, name, dicts
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

    pub async fn get_language_by_identifier(
        &self,
        identifier: String,
    ) -> Result<Option<LanguageEntry>> {
        match self {
            Surreal { engine } => {
                let mut res: Response = engine
                    .query("SELECT * FROM language WHERE identifier = $identifier")
                    .bind(("identifier", identifier))
                    .await?;

                match res.take(0) {
                    Ok::<Vec<LanguageEntry>, _>(v) => Ok(v.into_iter().next()),
                    _ => Err(anyhow::anyhow!("Error getting todos")),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    LanguageEntry,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", identifier, code, name, dicts
                        FROM language
                        WHERE identifier = $1;
                    "#,
                    identifier
                )
                .fetch_optional(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }
}

mod tests {
    use crate::db::DBLocation;
    use super::*;

    fn simple_language(identifier: &str, code: &str, name: &str) -> LanguageEntry {
        LanguageEntry {
            id: None,
            identifier: identifier.to_string(),
            code: code.to_string(),
            name: name.to_string(),
            dicts: vec![],
        }
    }

    #[tokio::test]
    #[allow(unused_must_use)]
    async fn test_create_language() {
        for db_choice in [
            crate::DBChoice::SurrealMemory,
            crate::DBChoice::PostgresServer,
        ] {
            let db = DB::create_db(db_choice).await.unwrap();
            assert!(!db.language_identifier_exists("en_demo".to_string()).await.unwrap());

            let language = simple_language("en_demo", "en", "English");

            let created = db.create_language(language.clone()).await.unwrap();
            assert_eq!(created, language);
            assert!(db.language_identifier_exists("en_demo".to_string()).await.unwrap());
        }
    }

    #[tokio::test]
    #[allow(unused_must_use)]
    async fn test_get_language_info() {
        for db_choice in [
            crate::DBChoice::SurrealMemory,
            crate::DBChoice::PostgresServer,
        ] {
            let db = DB::create_db(db_choice).await.unwrap();
            let created = db
                .create_language(simple_language("en_1", "en", "English 1"))
                .await
                .unwrap();
            let created = db
                .create_language(simple_language("en_2", "en", "English 2"))
                .await
                .unwrap();
            let created = db
                .create_language(simple_language("en_3", "en", "French ?"))
                .await
                .unwrap();

            let languages = db.get_languages_vec().await.unwrap();
            assert_eq!(languages.len(), 3);
            dbg!(languages);

            let language = db.get_language_by_identifier("en_1".to_string()).await.unwrap().unwrap();
            assert_eq!(language, simple_language("en_1", "en", "English 1"));

            let code = db
                .get_language_by_identifier("en_1".to_string())
                .await
                .unwrap()
                .unwrap().code;
            assert_eq!(code, "en");
        }
    }
}

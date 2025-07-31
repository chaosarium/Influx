use crate::db::InfluxResourceId;

use super::*;
// use crate::db::deserialize_surreal_thing_opt;
// use surrealdb::RecordId;
use std::collections::HashMap;

#[derive(
    Debug, Serialize, Deserialize, Clone, PartialEq, Elm, ElmEncode, ElmDecode, sqlx::FromRow,
)]
pub struct ParserConfig {
    pub which_parser: String,
    pub parser_args: HashMap<String, String>,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Elm, ElmEncode, ElmDecode)]
pub struct Language {
    pub id: Option<InfluxResourceId>,
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
pub struct LanguageInDB {
    pub id: InfluxResourceId,
    pub name: String,
    pub dicts: Vec<String>,
    pub tts_rate: Option<f64>,
    pub tts_pitch: Option<f64>,
    pub tts_voice: Option<String>,
    pub deepl_source_lang: Option<String>,
    pub deepl_target_lang: Option<String>,
    pub parser_config: sqlx::types::Json<ParserConfig>,
}

impl From<LanguageInDB> for Language {
    fn from(db_entry: LanguageInDB) -> Self {
        Language {
            id: Some(db_entry.id),
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
    pub async fn create_language(&self, language: Language) -> Result<Language> {
        assert!(language.id.is_none());
        match self {
            // Surreal { engine } => {
            //     let created: Result<Option<Language>, surrealdb::Error> =
            //         engine.create("language").content(language).await;

            //     match created {
            //         Ok(Some(entry)) => Ok(entry),
            //         Ok(None) => Err(anyhow::anyhow!("somehow got none")),
            //         Err(e) => Err(anyhow::anyhow!("Error creating language: {}", e)),
            //     }
            // }
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let record = sqlx::query_as!(
                    LanguageInDB,
                    r#"
                        INSERT INTO language (name, dicts, tts_rate, tts_pitch, tts_voice, deepl_source_lang, deepl_target_lang, parser_config )
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                        RETURNING id, name, dicts, tts_rate, tts_pitch, tts_voice, deepl_source_lang, deepl_target_lang, parser_config as "parser_config: sqlx::types::Json<ParserConfig>"
                    "#,
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

    pub async fn get_languages_vec(&self) -> Result<Vec<Language>> {
        match self {
            // Surreal { engine } => {
            //     let languages: Result<Vec<Language>, surrealdb::Error> =
            //         engine.select("language").await;

            //     match languages {
            //         Ok(v) => Ok(v),
            //         Err(e) => Err(anyhow::anyhow!("Error getting languages: {}", e)),
            //     }
            // }
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let records: Vec<Language> = sqlx::query_as!(
                    LanguageInDB,
                    r#"
                        SELECT id, name, dicts, tts_rate, tts_pitch, tts_voice, deepl_source_lang, deepl_target_lang, parser_config as "parser_config: sqlx::types::Json<ParserConfig>"
                        FROM language
                    "#
                )
                .fetch_all(pool.as_ref())
                .await?.into_iter().map(Into::into).collect();

                Ok(records)
            }
        }
    }

    pub async fn get_language(&self, id: InfluxResourceId) -> Result<Option<Language>> {
        match self {
            // Surreal { engine } => {
            //     let language: Result<Option<Language>, surrealdb::Error> =
            //         engine.select(("language", id)).await;

            //     match language {
            //         Ok(v) => Ok(v),
            //         Err(e) => Err(anyhow::anyhow!("Error getting language: {}", e)),
            //     }
            // }
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let record = sqlx::query_as!(
                    LanguageInDB,
                    r#"
                        SELECT id, name, dicts, tts_rate, tts_pitch, tts_voice, deepl_source_lang, deepl_target_lang, parser_config as "parser_config: sqlx::types::Json<ParserConfig>"
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

    pub async fn update_language(&self, language: Language) -> Result<Language> {
        let id = language
            .id
            .as_ref()
            .ok_or_else(|| anyhow::anyhow!("Language ID is required for update"))?;

        match self {
            // Surreal { engine } => {
            //     let updated: Result<Option<Language>, surrealdb::Error> =
            //         engine.update(("language", id)).content(language).await;

            //     match updated {
            //         Ok(Some(entry)) => Ok(entry),
            //         Ok(None) => Err(anyhow::anyhow!("Language not found for update")),
            //         Err(e) => Err(anyhow::anyhow!("Error updating language: {}", e)),
            //     }
            // }
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let record = sqlx::query_as!(
                    LanguageInDB,
                    r#"
                        UPDATE language 
                        SET name = $2, dicts = $3, tts_rate = $4, tts_pitch = $5, tts_voice = $6, deepl_source_lang = $7, deepl_target_lang = $8, parser_config = $9
                        WHERE id = $1
                        RETURNING id, name, dicts, tts_rate, tts_pitch, tts_voice, deepl_source_lang, deepl_target_lang, parser_config as "parser_config: sqlx::types::Json<ParserConfig>"
                    "#,
                    id.as_i64()?,
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::TestDb;
    use expect_test::expect;
    use std::collections::HashMap;
    use tabled::{settings::Style, Table, Tabled};

    #[derive(Tabled)]
    struct LanguageTableRow {
        id: String,
        name: String,
        dicts: String,
        tts_rate: String,
        parser: String,
    }

    impl From<&Language> for LanguageTableRow {
        fn from(lang: &Language) -> Self {
            Self {
                id: lang
                    .id
                    .as_ref()
                    .map(|id| format!("{}", id))
                    .unwrap_or_else(|| "None".to_string()),
                name: lang.name.clone(),
                dicts: format!("{:?}", lang.dicts),
                tts_rate: lang
                    .tts_rate
                    .map(|r| r.to_string())
                    .unwrap_or_else(|| "None".to_string()),
                parser: lang.parser_config.which_parser.clone(),
            }
        }
    }

    fn create_test_language(name: &str) -> Language {
        let mut parser_args = HashMap::new();
        parser_args.insert("spacy_model".to_string(), "en_core_web_sm".to_string());

        Language {
            id: None,
            name: name.to_string(),
            dicts: vec!["dict1".to_string(), "dict2".to_string()],
            tts_rate: Some(1.0),
            tts_pitch: Some(0.5),
            tts_voice: Some("en-US".to_string()),
            deepl_source_lang: Some("EN".to_string()),
            deepl_target_lang: Some("ES".to_string()),
            parser_config: ParserConfig {
                which_parser: "base_spacy".to_string(),
                parser_args,
            },
        }
    }

    #[tokio::test]
    #[tracing_test::traced_test]
    async fn test_language_crud_operations() {
        let test_db = TestDb::new().await.unwrap();

        // Check initial empty state
        let languages = test_db.db.get_languages_vec().await.unwrap();
        let table_rows: Vec<LanguageTableRow> = languages.iter().map(Into::into).collect();
        let table = Table::new(table_rows).with(Style::rounded()).to_string();

        expect![[r#"
            ╭────┬──────┬───────┬──────────┬────────╮
            │ id │ name │ dicts │ tts_rate │ parser │
            ├────┼──────┼───────┼──────────┼────────┤"#]]
        .assert_eq(&table);

        // Create first language
        let lang1 = create_test_language("Japanese");
        let created1 = test_db.db.create_language(lang1.clone()).await.unwrap();

        let languages = test_db.db.get_languages_vec().await.unwrap();
        let table_rows: Vec<LanguageTableRow> = languages.iter().map(Into::into).collect();
        let table = Table::new(table_rows).with(Style::rounded()).to_string();

        expect![[r#"
            ╭─────────────────────┬──────────┬────────────────────┬──────────┬────────────╮
            │ id                  │ name     │ dicts              │ tts_rate │ parser     │
            ├─────────────────────┼──────────┼────────────────────┼──────────┼────────────┤
            │ InfluxResourceId(1) │ Japanese │ ["dict1", "dict2"] │ 1        │ base_spacy │
            ╰─────────────────────┴──────────┴────────────────────┴──────────┴────────────╯"#]]
        .assert_eq(&table);

        // Create second language
        let lang2 = create_test_language("Chinese");
        let created2 = test_db.db.create_language(lang2.clone()).await.unwrap();

        let languages = test_db.db.get_languages_vec().await.unwrap();
        let table_rows: Vec<LanguageTableRow> = languages.iter().map(Into::into).collect();
        let table = Table::new(table_rows).with(Style::rounded()).to_string();

        expect![[r#"
            ╭─────────────────────┬──────────┬────────────────────┬──────────┬────────────╮
            │ id                  │ name     │ dicts              │ tts_rate │ parser     │
            ├─────────────────────┼──────────┼────────────────────┼──────────┼────────────┤
            │ InfluxResourceId(1) │ Japanese │ ["dict1", "dict2"] │ 1        │ base_spacy │
            │ InfluxResourceId(2) │ Chinese  │ ["dict1", "dict2"] │ 1        │ base_spacy │
            ╰─────────────────────┴──────────┴────────────────────┴──────────┴────────────╯"#]]
        .assert_eq(&table);

        // Test getting language by ID
        let retrieved = test_db
            .db
            .get_language(created1.id.as_ref().unwrap().clone())
            .await
            .unwrap();
        assert!(retrieved.is_some());
        let retrieved_lang = retrieved.unwrap();
        assert_eq!(retrieved_lang.name, "Japanese");

        // Test getting nonexistent language
        let result = test_db
            .db
            .get_language(InfluxResourceId::SerialId(999))
            .await
            .unwrap();
        assert!(result.is_none());

        // Test updating language
        let mut updated_language = created1.clone();
        updated_language.name = "日本語".to_string();
        updated_language.tts_rate = Some(1.5);

        let result = test_db
            .db
            .update_language(updated_language.clone())
            .await
            .unwrap();

        assert_eq!(result.name, "日本語");
        assert_eq!(result.tts_rate, Some(1.5));

        // Check final state after update
        let languages = test_db.db.get_languages_vec().await.unwrap();
        let table_rows: Vec<LanguageTableRow> = languages.iter().map(Into::into).collect();
        let table = Table::new(table_rows).with(Style::rounded()).to_string();

        expect![[r#"
            ╭─────────────────────┬─────────┬────────────────────┬──────────┬────────────╮
            │ id                  │ name    │ dicts              │ tts_rate │ parser     │
            ├─────────────────────┼─────────┼────────────────────┼──────────┼────────────┤
            │ InfluxResourceId(2) │ Chinese │ ["dict1", "dict2"] │ 1        │ base_spacy │
            │ InfluxResourceId(1) │ 日本語  │ ["dict1", "dict2"] │ 1.5      │ base_spacy │
            ╰─────────────────────┴─────────┴────────────────────┴──────────┴────────────╯"#]]
        .assert_eq(&table);
    }
}

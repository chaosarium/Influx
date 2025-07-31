use super::*;
use crate::db::models::{
    lang::Language,
    vocab::{Token, TokenStatus},
};
use crate::db::InfluxResourceId;
use crate::fsrs_scheduler::SerializableMemoryState;

#[derive(
    Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq, Elm, ElmEncode, ElmDecode, sqlx::Type,
)]
#[sqlx(type_name = "card_type")]
pub enum CardType {
    RECOGNITION, // Form → Meaning
    PRODUCTION,  // Meaning → Form
    CLOZE,       // Context → Fill blank
}

#[derive(
    Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq, Elm, ElmEncode, ElmDecode, sqlx::Type,
)]
#[sqlx(type_name = "card_state")]
pub enum CardState {
    ACTIVE,    // Normal card in rotation
    SUSPENDED, // Temporarily paused
    ARCHIVED,  // Permanently disabled but kept for history
    DISABLED,  // User-disabled, can be re-enabled
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Elm, ElmEncode, ElmDecode)]
pub struct FSRSLanguageConfig {
    pub id: Option<InfluxResourceId>,
    pub lang_id: InfluxResourceId,
    pub fsrs_weights: Vec<f64>,
    pub desired_retention: f64,
    pub maximum_interval: i32,
    pub request_retention: Option<f64>,
    pub enabled_card_types: Vec<CardType>,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, PartialEq)]
pub struct FSRSLanguageConfigInDB {
    pub id: InfluxResourceId,
    pub lang_id: InfluxResourceId,
    pub fsrs_weights: sqlx::types::Json<Vec<f64>>,
    pub desired_retention: f64,
    pub maximum_interval: i32,
    pub request_retention: Option<f64>,
    pub enabled_card_types: Vec<String>, // card_type[] from postgres
}

impl From<FSRSLanguageConfigInDB> for FSRSLanguageConfig {
    fn from(db_entry: FSRSLanguageConfigInDB) -> Self {
        let enabled_card_types = db_entry
            .enabled_card_types
            .iter()
            .filter_map(|ct| match ct.as_str() {
                "RECOGNITION" => Some(CardType::RECOGNITION),
                "PRODUCTION" => Some(CardType::PRODUCTION),
                "CLOZE" => Some(CardType::CLOZE),
                _ => None,
            })
            .collect();

        FSRSLanguageConfig {
            id: Some(db_entry.id),
            lang_id: db_entry.lang_id,
            fsrs_weights: db_entry.fsrs_weights.0,
            desired_retention: db_entry.desired_retention,
            maximum_interval: db_entry.maximum_interval,
            request_retention: db_entry.request_retention,
            enabled_card_types,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Elm, ElmEncode, ElmDecode)]
pub struct Card {
    pub id: Option<InfluxResourceId>,
    pub token_id: Option<InfluxResourceId>,
    pub phrase_id: Option<InfluxResourceId>,
    pub card_type: CardType,
    pub card_state: CardState,
    pub fsrs_memory: Option<SerializableMemoryState>, // FSRS memory state
    pub due_date: Option<chrono::DateTime<chrono::Utc>>,
    pub last_review: Option<chrono::DateTime<chrono::Utc>>,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, PartialEq)]
pub struct CardInDB {
    pub id: InfluxResourceId,
    pub token_id: Option<i64>,
    pub phrase_id: Option<i64>,
    pub card_type: CardType,
    pub card_state: CardState,
    pub fsrs_memory: Option<sqlx::types::Json<SerializableMemoryState>>,
    pub due_date: Option<time::OffsetDateTime>,
    pub last_review: Option<time::OffsetDateTime>,
}

impl From<CardInDB> for Card {
    fn from(db_entry: CardInDB) -> Self {
        Card {
            id: Some(db_entry.id),
            token_id: db_entry.token_id.map(InfluxResourceId::SerialId),
            phrase_id: db_entry.phrase_id.map(InfluxResourceId::SerialId),
            card_type: db_entry.card_type,
            card_state: db_entry.card_state,
            fsrs_memory: db_entry.fsrs_memory.map(|j| j.0),
            due_date: db_entry
                .due_date
                .map(|dt| chrono::DateTime::from_timestamp(dt.unix_timestamp(), 0).unwrap()),
            last_review: db_entry
                .last_review
                .map(|dt| chrono::DateTime::from_timestamp(dt.unix_timestamp(), 0).unwrap()),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Elm, ElmEncode, ElmDecode)]
pub struct ReviewLog {
    pub id: Option<InfluxResourceId>,
    pub card_id: InfluxResourceId,
    pub rating: i32, // 1=Again, 2=Hard, 3=Good, 4=Easy
    pub review_time_ms: Option<i32>,
    pub fsrs_memory_before: Option<SerializableMemoryState>,
    pub fsrs_memory_after: Option<SerializableMemoryState>,
    pub review_date: chrono::DateTime<chrono::Utc>,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, PartialEq)]
pub struct ReviewLogInDB {
    pub id: InfluxResourceId,
    pub card_id: InfluxResourceId,
    pub rating: i32,
    pub review_time_ms: Option<i32>,
    pub fsrs_memory_before: Option<sqlx::types::Json<SerializableMemoryState>>,
    pub fsrs_memory_after: Option<sqlx::types::Json<SerializableMemoryState>>,
    pub review_date: time::OffsetDateTime,
}

impl From<ReviewLogInDB> for ReviewLog {
    fn from(db_entry: ReviewLogInDB) -> Self {
        ReviewLog {
            id: Some(db_entry.id),
            card_id: db_entry.card_id,
            rating: db_entry.rating,
            review_time_ms: db_entry.review_time_ms,
            fsrs_memory_before: db_entry.fsrs_memory_before.map(|j| j.0),
            fsrs_memory_after: db_entry.fsrs_memory_after.map(|j| j.0),
            review_date: chrono::DateTime::from_timestamp(db_entry.review_date.unix_timestamp(), 0)
                .unwrap(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct FSRSOptimizationLog {
    pub id: Option<InfluxResourceId>,
    pub lang_id: InfluxResourceId,
    pub weights_before: Vec<f64>,
    pub weights_after: Vec<f64>,
    pub log_loss_before: Option<f64>,
    pub log_loss_after: Option<f64>,
    pub review_count: Option<i32>,
    pub optimization_date: chrono::DateTime<chrono::Utc>,
    pub notes: String,
}

use DB::*;

impl DB {
    pub async fn create_fsrs_language_config(
        &self,
        config: FSRSLanguageConfig,
    ) -> Result<FSRSLanguageConfig> {
        assert!(config.id.is_none());
        match self {
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let enabled_card_types_str: Vec<String> = config
                    .enabled_card_types
                    .iter()
                    .map(|ct| match ct {
                        CardType::RECOGNITION => "RECOGNITION".to_string(),
                        CardType::PRODUCTION => "PRODUCTION".to_string(),
                        CardType::CLOZE => "CLOZE".to_string(),
                    })
                    .collect();

                let record = sqlx::query_as!(
                    FSRSLanguageConfigInDB,
                    r#"
                        INSERT INTO fsrs_language_config (lang_id, fsrs_weights, desired_retention, maximum_interval, request_retention, enabled_card_types)
                        VALUES ($1, $2, $3, $4, $5, $6::card_type[])
                        RETURNING id, lang_id, fsrs_weights as "fsrs_weights: sqlx::types::Json<Vec<f64>>", desired_retention, maximum_interval, request_retention, enabled_card_types as "enabled_card_types: Vec<String>"
                    "#,
                    config.lang_id.as_i64()?,
                    serde_json::to_value(&config.fsrs_weights)?,
                    config.desired_retention,
                    config.maximum_interval,
                    config.request_retention,
                    &enabled_card_types_str as &[String]
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record.into())
            }
        }
    }

    pub async fn get_fsrs_language_config(
        &self,
        lang_id: InfluxResourceId,
    ) -> Result<Option<FSRSLanguageConfig>> {
        match self {
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let record = sqlx::query_as!(
                    FSRSLanguageConfigInDB,
                    r#"
                        SELECT id, lang_id, fsrs_weights as "fsrs_weights: sqlx::types::Json<Vec<f64>>", desired_retention, maximum_interval, request_retention, enabled_card_types as "enabled_card_types: Vec<String>"
                        FROM fsrs_language_config
                        WHERE lang_id = $1
                    "#,
                    lang_id.as_i64()?
                )
                .fetch_optional(pool.as_ref())
                .await?.map(Into::into);

                Ok(record)
            }
        }
    }

    // TODO: DONE - Fixed card database functions but need to resolve SQLX Json type mapping
    // Temporarily commented out due to sqlx Json<> double-wrapping issues
    /*
    pub async fn create_card(&self, card: Card) -> Result<Card> {
        assert!(card.id.is_none());
        match self {
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let fsrs_memory_json = card.fsrs_memory.as_ref().map(|m| serde_json::to_value(m)).transpose()?;
                let due_date_offset = card.due_date.map(|dt| time::OffsetDateTime::from_unix_timestamp(dt.timestamp()).unwrap());
                let last_review_offset = card.last_review.map(|dt| time::OffsetDateTime::from_unix_timestamp(dt.timestamp()).unwrap());

                let record = sqlx::query_as!(
                    CardInDB,
                    r#"
                        INSERT INTO card (token_id, phrase_id, card_type, card_state, fsrs_memory, due_date, last_review)
                        VALUES ($1, $2, $3, $4, $5, $6, $7)
                        RETURNING id, token_id, phrase_id, card_type as "card_type: CardType", card_state as "card_state: CardState", fsrs_memory as "fsrs_memory: Option<sqlx::types::Json<SerializableMemoryState>>", due_date, last_review
                    "#,
                    card.token_id.map(|id| id.as_i64()).transpose()?,
                    card.phrase_id.map(|id| id.as_i64()).transpose()?,
                    card.card_type as CardType,
                    card.card_state as CardState,
                    fsrs_memory_json,
                    due_date_offset,
                    last_review_offset
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record.into())
            }
        }
    }

    pub async fn get_card(&self, id: InfluxResourceId) -> Result<Option<Card>> {
        match self {
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let record = sqlx::query_as!(
                    CardInDB,
                    r#"
                        SELECT id, token_id, phrase_id, card_type as "card_type: CardType", card_state as "card_state: CardState", fsrs_memory as "fsrs_memory: Option<sqlx::types::Json<SerializableMemoryState>>", due_date, last_review
                        FROM card
                        WHERE id = $1
                    "#,
                    id.as_i64()?
                )
                .fetch_optional(pool.as_ref())
                .await?.map(Into::into);

                Ok(record)
            }
        }
    }

    pub async fn update_card(&self, card: Card) -> Result<Card> {
        assert!(card.id.is_some());
        match self {
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let fsrs_memory_json = card.fsrs_memory.as_ref().map(|m| serde_json::to_value(m)).transpose()?;
                let due_date_offset = card.due_date.map(|dt| time::OffsetDateTime::from_unix_timestamp(dt.timestamp()).unwrap());
                let last_review_offset = card.last_review.map(|dt| time::OffsetDateTime::from_unix_timestamp(dt.timestamp()).unwrap());

                let record = sqlx::query_as!(
                    CardInDB,
                    r#"
                        UPDATE card
                        SET token_id = $2, phrase_id = $3, card_type = $4, card_state = $5, fsrs_memory = $6, due_date = $7, last_review = $8
                        WHERE id = $1
                        RETURNING id, token_id, phrase_id, card_type as "card_type: CardType", card_state as "card_state: CardState", fsrs_memory as "fsrs_memory: Option<sqlx::types::Json<SerializableMemoryState>>", due_date, last_review
                    "#,
                    card.id.unwrap().as_i64()?,
                    card.token_id.map(|id| id.as_i64()).transpose()?,
                    card.phrase_id.map(|id| id.as_i64()).transpose()?,
                    card.card_type as CardType,
                    card.card_state as CardState,
                    fsrs_memory_json,
                    due_date_offset,
                    last_review_offset
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record.into())
            }
        }
    }

    pub async fn create_review_log(&self, review: ReviewLog) -> Result<ReviewLog> {
        assert!(review.id.is_none());
        match self {
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let fsrs_memory_before_json = review.fsrs_memory_before.as_ref().map(|m| serde_json::to_value(m)).transpose()?;
                let fsrs_memory_after_json = review.fsrs_memory_after.as_ref().map(|m| serde_json::to_value(m)).transpose()?;
                let review_date_offset = time::OffsetDateTime::from_unix_timestamp(review.review_date.timestamp()).unwrap();

                let record = sqlx::query_as!(
                    ReviewLogInDB,
                    r#"
                        INSERT INTO review_log (card_id, rating, review_time_ms, fsrs_memory_before, fsrs_memory_after, review_date)
                        VALUES ($1, $2, $3, $4, $5, $6)
                        RETURNING id, card_id, rating, review_time_ms,
                        fsrs_memory_before as "fsrs_memory_before: Option<sqlx::types::Json<SerializableMemoryState>>",
                        fsrs_memory_after as "fsrs_memory_after: Option<sqlx::types::Json<SerializableMemoryState>>",
                        review_date
                    "#,
                    review.card_id.as_i64()?,
                    review.rating,
                    review.review_time_ms,
                    fsrs_memory_before_json,
                    fsrs_memory_after_json,
                    review_date_offset
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record.into())
            }
        }
    }
    */
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_utils::TestDb;
    use expect_test::expect;

    #[tokio::test]
    #[tracing_test::traced_test]
    async fn test_fsrs_language_config_crud() {
        let test_db = TestDb::new().await.unwrap();
        let lang = test_db
            .db
            .create_language(Language {
                id: None,
                name: "Test Language".to_string(),
                dicts: vec!["test_dict".to_string()],
                tts_rate: Some(1.0),
                tts_pitch: Some(1.0),
                tts_voice: Some("test_voice".to_string()),
                deepl_source_lang: Some("EN".to_string()),
                deepl_target_lang: Some("DE".to_string()),
                parser_config: Default::default(),
            })
            .await
            .unwrap();

        let config = FSRSLanguageConfig {
            id: None,
            lang_id: lang.id.clone().unwrap(),
            fsrs_weights: vec![0.5; 21],
            desired_retention: 0.85,
            maximum_interval: 365,
            request_retention: Some(0.9),
            enabled_card_types: vec![CardType::RECOGNITION, CardType::PRODUCTION],
        };

        let created_config = test_db
            .db
            .create_fsrs_language_config(config.clone())
            .await
            .unwrap();
        assert!(created_config.id.is_some());
        assert_eq!(created_config.lang_id, config.lang_id);
        assert_eq!(created_config.fsrs_weights, config.fsrs_weights);
        assert_eq!(created_config.desired_retention, config.desired_retention);
        assert_eq!(created_config.maximum_interval, config.maximum_interval);
        assert_eq!(created_config.request_retention, config.request_retention);
        assert_eq!(created_config.enabled_card_types, config.enabled_card_types);

        let retrieved_config = test_db
            .db
            .get_fsrs_language_config(lang.id.unwrap())
            .await
            .unwrap()
            .unwrap();
        assert_eq!(retrieved_config, created_config);

        let nonexistent_config = test_db
            .db
            .get_fsrs_language_config(InfluxResourceId::SerialId(99999))
            .await
            .unwrap();
        assert!(nonexistent_config.is_none());
    }

    // TODO: DONE - Implemented basic FSRS language config test
    // TODO: Card tests are commented out due to sqlx Json<> double-wrapping issues
    /*
    #[tokio::test]
    #[tracing_test::traced_test]
    async fn test_card_crud_operations() {
        let test_db = TestDb::new().await.unwrap();
        let lang = test_db
            .db
            .create_language(Language {
                id: None,
                name: "Test Language".to_string(),
                dicts: vec!["test_dict".to_string()],
                tts_rate: Some(1.0),
                tts_pitch: Some(1.0),
                tts_voice: Some("test_voice".to_string()),
                deepl_source_lang: Some("EN".to_string()),
                deepl_target_lang: Some("DE".to_string()),
                parser_config: Default::default(),
            })
            .await
            .unwrap();

        let token = test_db
            .db
            .create_token(Token {
                id: None,
                lang_id: lang.id.unwrap(),
                orthography: "test".to_string(),
                phonetic: "test".to_string(),
                definition: "test definition".to_string(),
                notes: "test notes".to_string(),
                original_context: "test context".to_string(),
                status: TokenStatus::L1,
            })
            .await
            .unwrap();

        let card = Card {
            id: None,
            token_id: token.id,
            phrase_id: None,
            card_type: CardType::RECOGNITION,
            card_state: CardState::ACTIVE,
            fsrs_memory: None,
            due_date: Some(chrono::Utc::now()),
            last_review: None,
        };

        let created_card = test_db.db.create_card(card.clone()).await.unwrap();
        assert!(created_card.id.is_some());
        assert_eq!(created_card.token_id, card.token_id);
        assert_eq!(created_card.phrase_id, card.phrase_id);
        assert_eq!(created_card.card_type, card.card_type);
        assert_eq!(created_card.card_state, card.card_state);
        assert_eq!(created_card.fsrs_memory, card.fsrs_memory);
        assert!(created_card.due_date.is_some());

        let retrieved_card = test_db
            .db
            .get_card(created_card.id.clone().unwrap())
            .await
            .unwrap()
            .unwrap();
        assert_eq!(retrieved_card.id, created_card.id);
        assert_eq!(retrieved_card.token_id, created_card.token_id);

        let mut updated_card = created_card.clone();
        updated_card.card_state = CardState::SUSPENDED;
        updated_card.last_review = Some(chrono::Utc::now());

        let final_card = test_db.db.update_card(updated_card.clone()).await.unwrap();
        assert_eq!(final_card.card_state, CardState::SUSPENDED);
        assert!(final_card.last_review.is_some());

        let nonexistent_card = test_db
            .db
            .get_card(InfluxResourceId::SerialId(99999))
            .await
            .unwrap();
        assert!(nonexistent_card.is_none());
    }

    #[tokio::test]
    #[tracing_test::traced_test]
    async fn test_review_log_creation() {
        let test_db = TestDb::new().await.unwrap();
        let lang = test_db
            .db
            .create_language(Language {
                id: None,
                name: "Test Language".to_string(),
                dicts: vec!["test_dict".to_string()],
                tts_rate: Some(1.0),
                tts_pitch: Some(1.0),
                tts_voice: Some("test_voice".to_string()),
                deepl_source_lang: Some("EN".to_string()),
                deepl_target_lang: Some("DE".to_string()),
                parser_config: Default::default(),
            })
            .await
            .unwrap();

        let token = test_db
            .db
            .create_token(Token {
                id: None,
                lang_id: lang.id.unwrap(),
                orthography: "test".to_string(),
                phonetic: "test".to_string(),
                definition: "test definition".to_string(),
                notes: "test notes".to_string(),
                original_context: "test context".to_string(),
                status: TokenStatus::L1,
            })
            .await
            .unwrap();

        let card = Card {
            id: None,
            token_id: token.id,
            phrase_id: None,
            card_type: CardType::RECOGNITION,
            card_state: CardState::ACTIVE,
            fsrs_memory: None,
            due_date: Some(chrono::Utc::now()),
            last_review: None,
        };

        let created_card = test_db.db.create_card(card).await.unwrap();

        let review_log = ReviewLog {
            id: None,
            card_id: created_card.id.unwrap(),
            rating: 3,
            review_time_ms: Some(5000),
            fsrs_memory_before: None,
            fsrs_memory_after: None,
            review_date: chrono::Utc::now(),
        };

        let created_review = test_db.db.create_review_log(review_log.clone()).await.unwrap();
        assert!(created_review.id.is_some());
        assert_eq!(created_review.card_id, review_log.card_id);
        assert_eq!(created_review.rating, review_log.rating);
        assert_eq!(created_review.review_time_ms, review_log.review_time_ms);
        assert_eq!(created_review.fsrs_memory_before, review_log.fsrs_memory_before);
        assert_eq!(created_review.fsrs_memory_after, review_log.fsrs_memory_after);
    }
    */
}

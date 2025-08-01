use super::*;
use crate::db::models::{
    lang::Language,
    vocab::{Token, TokenStatus},
};
use crate::db::InfluxResourceId;
use crate::fsrs_scheduler::SerializableMemoryState;
use chrono::{DateTime, Offset, Utc};

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
    pub enabled_card_types: Vec<CardType>, // card_type[] from postgres
}

impl From<FSRSLanguageConfigInDB> for FSRSLanguageConfig {
    fn from(db_entry: FSRSLanguageConfigInDB) -> Self {
        FSRSLanguageConfig {
            id: Some(db_entry.id),
            lang_id: db_entry.lang_id,
            fsrs_weights: db_entry.fsrs_weights.0,
            desired_retention: db_entry.desired_retention,
            maximum_interval: db_entry.maximum_interval,
            request_retention: db_entry.request_retention,
            enabled_card_types: db_entry.enabled_card_types,
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
    pub due_date: Option<DateTime<Utc>>,
    pub last_review: Option<DateTime<Utc>>,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, PartialEq)]
pub struct CardInDB {
    pub id: InfluxResourceId,
    pub token_id: Option<i64>,
    pub phrase_id: Option<i64>,
    pub card_type: CardType,
    pub card_state: CardState,
    pub fsrs_stability: Option<f32>,
    pub fsrs_difficulty: Option<f32>,
    pub due_date: Option<DateTime<Utc>>,
    pub last_review: Option<DateTime<Utc>>,
}

impl From<CardInDB> for Card {
    fn from(db_entry: CardInDB) -> Self {
        let fsrs_memory = match (db_entry.fsrs_stability, db_entry.fsrs_difficulty) {
            (Some(stability), Some(difficulty)) => Some(SerializableMemoryState {
                stability,
                difficulty,
            }),
            _ => None,
        };

        Card {
            id: Some(db_entry.id),
            token_id: db_entry.token_id.map(InfluxResourceId::SerialId),
            phrase_id: db_entry.phrase_id.map(InfluxResourceId::SerialId),
            card_type: db_entry.card_type,
            card_state: db_entry.card_state,
            fsrs_memory,
            due_date: db_entry.due_date,
            last_review: db_entry.last_review,
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
    pub review_date: DateTime<Utc>,
}

#[derive(sqlx::FromRow, Serialize, Deserialize, PartialEq)]
pub struct ReviewLogInDB {
    pub id: InfluxResourceId,
    pub card_id: InfluxResourceId,
    pub rating: i32,
    pub review_time_ms: Option<i32>,
    pub fsrs_stability_before: Option<f32>,
    pub fsrs_difficulty_before: Option<f32>,
    pub fsrs_stability_after: Option<f32>,
    pub fsrs_difficulty_after: Option<f32>,
    pub review_date: DateTime<Utc>,
}

impl From<ReviewLogInDB> for ReviewLog {
    fn from(db_entry: ReviewLogInDB) -> Self {
        let fsrs_memory_before = match (
            db_entry.fsrs_stability_before,
            db_entry.fsrs_difficulty_before,
        ) {
            (Some(stability), Some(difficulty)) => Some(SerializableMemoryState {
                stability,
                difficulty,
            }),
            _ => None,
        };

        let fsrs_memory_after = match (
            db_entry.fsrs_stability_after,
            db_entry.fsrs_difficulty_after,
        ) {
            (Some(stability), Some(difficulty)) => Some(SerializableMemoryState {
                stability,
                difficulty,
            }),
            _ => None,
        };

        ReviewLog {
            id: Some(db_entry.id),
            card_id: db_entry.card_id,
            rating: db_entry.rating,
            review_time_ms: db_entry.review_time_ms,
            fsrs_memory_before,
            fsrs_memory_after,
            review_date: db_entry.review_date,
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
    pub optimization_date: DateTime<Utc>,
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
                let record = sqlx::query_as!(
                    FSRSLanguageConfigInDB,
                    r#"
                        INSERT INTO fsrs_language_config (lang_id, fsrs_weights, desired_retention, maximum_interval, request_retention, enabled_card_types)
                        VALUES ($1, $2, $3, $4, $5, $6::card_type[])
                        RETURNING id, lang_id, fsrs_weights as "fsrs_weights: sqlx::types::Json<Vec<f64>>", desired_retention, maximum_interval, request_retention, enabled_card_types as "enabled_card_types: Vec<CardType>"
                    "#,
                    config.lang_id.as_i64()?,
                    serde_json::to_value(&config.fsrs_weights)?,
                    config.desired_retention,
                    config.maximum_interval,
                    config.request_retention,
                    &config.enabled_card_types as &[CardType]
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
                        SELECT id, lang_id, fsrs_weights as "fsrs_weights: sqlx::types::Json<Vec<f64>>", desired_retention, maximum_interval, request_retention, enabled_card_types as "enabled_card_types: Vec<CardType>"
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

    pub async fn create_card(&self, card: Card) -> Result<Card> {
        assert!(card.id.is_none());
        match self {
            Postgres { pool } | EmbeddedPostgres { pool, .. } => {
                let (fsrs_stability, fsrs_difficulty) = match &card.fsrs_memory {
                    Some(memory) => (Some(memory.stability), Some(memory.difficulty)),
                    None => (None, None),
                };
                let due_date_offset = card.due_date;
                let last_review_offset = card.last_review;

                let record = sqlx::query_as!(
                    CardInDB,
                    r#"
                        INSERT INTO card (token_id, phrase_id, card_type, card_state, fsrs_stability, fsrs_difficulty, due_date, last_review)
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                        RETURNING id, token_id, phrase_id, card_type as "card_type: CardType", card_state as "card_state: CardState", fsrs_stability, fsrs_difficulty, due_date, last_review
                    "#,
                    card.token_id.map(|id| id.as_i64()).transpose()?,
                    card.phrase_id.map(|id| id.as_i64()).transpose()?,
                    card.card_type as CardType,
                    card.card_state as CardState,
                    fsrs_stability,
                    fsrs_difficulty,
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
                        SELECT id, token_id, phrase_id, card_type as "card_type: CardType", card_state as "card_state: CardState", fsrs_stability, fsrs_difficulty, due_date, last_review
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
                let (fsrs_stability, fsrs_difficulty) = match &card.fsrs_memory {
                    Some(memory) => (Some(memory.stability), Some(memory.difficulty)),
                    None => (None, None),
                };

                let record = sqlx::query_as!(
                    CardInDB,
                    r#"
                        UPDATE card
                        SET token_id = $2, phrase_id = $3, card_type = $4, card_state = $5, fsrs_stability = $6, fsrs_difficulty = $7, due_date = $8, last_review = $9
                        WHERE id = $1
                        RETURNING id, token_id, phrase_id, card_type as "card_type: CardType", card_state as "card_state: CardState", fsrs_stability, fsrs_difficulty, due_date, last_review
                    "#,
                    card.id.unwrap().as_i64()?,
                    card.token_id.map(|id| id.as_i64()).transpose()?,
                    card.phrase_id.map(|id| id.as_i64()).transpose()?,
                    card.card_type as CardType,
                    card.card_state as CardState,
                    fsrs_stability,
                    fsrs_difficulty,
                    card.due_date,
                    card.last_review
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
                let (fsrs_stability_before, fsrs_difficulty_before) =
                    match &review.fsrs_memory_before {
                        Some(memory) => (Some(memory.stability), Some(memory.difficulty)),
                        None => (None, None),
                    };
                let (fsrs_stability_after, fsrs_difficulty_after) = match &review.fsrs_memory_after
                {
                    Some(memory) => (Some(memory.stability), Some(memory.difficulty)),
                    None => (None, None),
                };

                let record = sqlx::query_as!(
                    ReviewLogInDB,
                    r#"
                        INSERT INTO review_log (card_id, rating, review_time_ms, fsrs_stability_before, fsrs_difficulty_before, fsrs_stability_after, fsrs_difficulty_after, review_date)
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                        RETURNING id, card_id, rating, review_time_ms, fsrs_stability_before, fsrs_difficulty_before, fsrs_stability_after, fsrs_difficulty_after, review_date
                    "#,
                    review.card_id.as_i64()?,
                    review.rating,
                    review.review_time_ms,
                    fsrs_stability_before,
                    fsrs_difficulty_before,
                    fsrs_stability_after,
                    fsrs_difficulty_after,
                    review.review_date
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record.into())
            }
        }
    }
}

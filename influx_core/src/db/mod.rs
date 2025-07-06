#![allow(unused_imports)]

use anyhow::Result;
use elm_rs::{Elm, ElmDecode, ElmEncode};
use models::phrase::Phrase;
use models::vocab::Token;
use serde::{Deserialize, Serialize};
use sqlx::{PgPool, Pool, Postgres};
use std::env;
use std::{fs, path::PathBuf, sync::Arc};
use surrealdb::{
    engine::{
        local::{Db, Mem},
        remote::ws::Ws,
    },
    sql::{Object, Thing},
    Response, Surreal,
};

use crate::DBChoice;
pub mod models;

#[derive(Clone)]
pub enum DB {
    Surreal {
        engine: Arc<Surreal<surrealdb::engine::any::Any>>,
    },
    Postgres {
        pool: Arc<Pool<Postgres>>,
    },
}

pub enum DBLocation {
    Disk(PathBuf),
    Mem,
    Localhost,
}

impl DB {
    pub async fn create_db(db_choice: DBChoice) -> Result<Self> {
        Ok(match db_choice {
            DBChoice::SurrealMemory => {
                let client = surrealdb::engine::any::connect("memory").await?;
                client.use_ns("influx_ns").use_db("influx_db").await?;
                DB::Surreal {
                    engine: Arc::new(client),
                }
            }
            DBChoice::SurrealDisk => {
                // let db_path_string: &str = abs_path.to_str()?;
                // println!("db_path_string: {}", db_path_string);
                // let client = Surreal::new::<File>(db_path_string).await?;
                // client.use_ns("influx_ns").use_db("influx_db").await?;
                panic!("not yet");
            }
            DBChoice::SurrealServer => {
                let client = surrealdb::engine::any::connect("ws://localhost:8000").await?;
                client
                    .signin(surrealdb::opt::auth::Root {
                        username: "root",
                        password: "root",
                    })
                    .await?;
                client.use_ns("influx_ns").use_db("influx_db").await?;
                DB::Surreal {
                    engine: Arc::new(client),
                }
            }
            DBChoice::PostgresServer => {
                let pool = PgPool::connect(&env::var("DATABASE_URL")?).await?;
                DB::Postgres {
                    pool: Arc::new(pool),
                }
            }
        })
    }

    #[deprecated]
    pub async fn delete_thing<
        T: serde::Serialize
            + for<'a> serde::Deserialize<'a>
            + std::marker::Sync
            + std::marker::Send
            + std::fmt::Debug,
    >(
        &self,
        thing: Thing,
    ) -> Result<T> {
        panic!("deprecated");
        // match self.db.delete((thing.tb, thing.id.to_raw())).await? {
        //     Some::<T>(v) => Ok(v),
        //     _ => Err(anyhow::anyhow!("Error deleting thing"))
        // }
    }

    #[deprecated]
    pub async fn select_thing<
        T: serde::Serialize
            + for<'a> serde::Deserialize<'a>
            + std::marker::Sync
            + std::marker::Send
            + std::fmt::Debug
            + Clone,
    >(
        &self,
        thing: Thing,
    ) -> Result<Option<T>> {
        panic!("deprecated");
        // match self.db.select((thing.tb, thing.id.to_raw())).await? {
        //     Some::<T>(v) => Ok(Some(v)),
        //     _ => Ok(None)
        // }
    }

    #[deprecated]
    pub async fn thing_exists<
        T: serde::Serialize
            + for<'a> serde::Deserialize<'a>
            + std::marker::Sync
            + std::marker::Send
            + std::fmt::Debug
            + Clone,
    >(
        &self,
        thing: Thing,
    ) -> Result<bool> {
        panic!("deprecated");
        // Ok(self.select_thing::<T>(thing).await?.is_some())
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq, Hash, Elm, ElmEncode, ElmDecode)]
pub enum InfluxResourceId {
    SerialId(i64),
    StringId(String),
}

// === surrealdb support ===

impl Into<surrealdb::value::RecordIdKey> for InfluxResourceId {
    fn into(self) -> surrealdb::value::RecordIdKey {
        match self {
            InfluxResourceId::SerialId(n) => n.into(),
            InfluxResourceId::StringId(s) => s.into(),
        }
    }
}

impl Into<surrealdb::value::RecordIdKey> for &InfluxResourceId {
    fn into(self) -> surrealdb::value::RecordIdKey {
        match self {
            InfluxResourceId::SerialId(n) => (*n).into(),
            InfluxResourceId::StringId(s) => s.clone().into(),
        }
    }
}

pub fn deserialize_surreal_thing_opt<'de, D>(
    deserializer: D,
) -> Result<Option<InfluxResourceId>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let record_id = Thing::deserialize(deserializer)?;
    match record_id.id {
        surrealdb::sql::Id::String(s) => Ok(Some(InfluxResourceId::StringId(s))),
        surrealdb::sql::Id::Number(n) => Ok(Some(InfluxResourceId::SerialId(n))),
        _ => Err(serde::de::Error::custom("Unsupported variant of RecordId")),
    }
}

pub fn deserialize_surreal_thing<'de, D>(deserializer: D) -> Result<InfluxResourceId, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let record_id = Thing::deserialize(deserializer)?;
    match record_id.id {
        surrealdb::sql::Id::String(s) => Ok(InfluxResourceId::StringId(s)),
        surrealdb::sql::Id::Number(n) => Ok(InfluxResourceId::SerialId(n)),
        _ => Err(serde::de::Error::custom("Unsupported variant of RecordId")),
    }
}

// === postgres support ===

use sqlx::decode::Decode;
use sqlx::encode::Encode;
use sqlx::postgres::PgTypeInfo;
use sqlx::Type;

impl Type<Postgres> for InfluxResourceId {
    fn type_info() -> PgTypeInfo {
        PgTypeInfo::with_name("BIGSERIAL")
    }
}

impl InfluxResourceId {
    pub fn as_i64(&self) -> Result<i64, anyhow::Error> {
        match self {
            InfluxResourceId::SerialId(id) => Ok(*id),
            InfluxResourceId::StringId(_) => {
                Err(anyhow::anyhow!("Expected SerialId but got StringId"))
            }
        }
    }
}

impl From<i64> for InfluxResourceId {
    fn from(id: i64) -> Self {
        InfluxResourceId::SerialId(id)
    }
}

impl<'r> Decode<'r, Postgres> for InfluxResourceId {
    fn decode(
        value: sqlx::postgres::PgValueRef<'r>,
    ) -> Result<Self, Box<dyn std::error::Error + 'static + Send + Sync>> {
        // Decode as i64 and wrap in SerialId variant
        let id = <i64 as Decode<Postgres>>::decode(value)?;
        Ok(InfluxResourceId::SerialId(id))
    }
}

impl<'q> Encode<'q, Postgres> for InfluxResourceId {
    fn encode_by_ref(
        &self,
        buf: &mut sqlx::postgres::PgArgumentBuffer,
    ) -> Result<sqlx::encode::IsNull, Box<dyn std::error::Error + Send + Sync>> {
        match self {
            InfluxResourceId::SerialId(id) => <i64 as Encode<Postgres>>::encode_by_ref(id, buf),
            InfluxResourceId::StringId(s) => <String as Encode<Postgres>>::encode_by_ref(s, buf),
        }
    }

    fn size_hint(&self) -> usize {
        match self {
            InfluxResourceId::SerialId(id) => <i64 as Encode<Postgres>>::size_hint(id),
            InfluxResourceId::StringId(s) => <String as Encode<Postgres>>::size_hint(s),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::extract::Path;

    // #[tokio::test]
    // async fn db_create_mem() {
    //     let db = DB::create_db(DBLocation::Mem).await;
    //     let todos = db.get_todos_sql().await.unwrap();
    //     assert_eq!(todos.len(), 0);
    // }

    // #[tokio::test]
    // async fn db_create_disk() {
    //     let db = DB::create_db(DBLocation::Disk(PathBuf::from("./").canonicalize().unwrap().join("tmp_database.db"))).await;
    // }
}

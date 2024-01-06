#![allow(unused_imports)]

use std::{sync::Arc, path::PathBuf, fs};
use surrealdb::{
    Response, Surreal,
    sql::{Thing, Object},
    engine::local::{File, Mem, Db},
};
// use surrealdb::{kvs::Datastore, dbs::Session, opt::auth::Root, engine::remote::ws::Ws, };
use anyhow::Result;

pub mod models;
use models::todos::TodoInDB;
use models::vocab::Token;
use models::phrase::Phrase;

#[derive(Clone)]
pub struct DB {
    pub db: Arc<Surreal<Db>>,
}

pub enum DBLocation {
    Disk(PathBuf),
    Mem,
}

impl DB {
    pub async fn create_db(location: DBLocation) -> Self {
        let client: Surreal<Db> = match location {
            DBLocation::Disk(abs_path) => {
                let db_path_string: &str = abs_path.to_str().unwrap();
                println!("db_path_string: {}", db_path_string);
                Surreal::new::<File>(db_path_string).await.unwrap()
            },
            DBLocation::Mem => Surreal::new::<Mem>(()).await.unwrap()
        };

        client.use_ns("influx_ns").use_db("influx_db").await.unwrap();

        DB {
            db: Arc::new(client),
        }
    }

    pub async fn seed_all_tables(&self) -> Result<()> {
        self.seed_todo_table().await?;
        self.seed_vocab_table().await?;
        self.seed_lang_table().await?;
        self.seed_phrase_table().await?;
        Ok(())
    }

    pub async fn delete_thing<T: serde::Serialize + for<'a> serde::Deserialize<'a> + std::marker::Sync + std::marker::Send + std::fmt::Debug>(&self, thing: Thing) -> Result<T> {
        match self.db.delete(thing).await? {
            Some::<T>(v) => Ok(v),
            _ => Err(anyhow::anyhow!("Error deleting thing"))
        }
    }

    pub async fn select_thing<T: serde::Serialize + for<'a> serde::Deserialize<'a> + std::marker::Sync + std::marker::Send + std::fmt::Debug>(&self, thing: Thing) -> Result<Option<T>> {
        match self.db.select(thing).await? {
            Some::<T>(v) => Ok(Some(v)),
            _ => Ok(None)
        }
    }

    pub async fn thing_exists<T: serde::Serialize + for<'a> serde::Deserialize<'a> + std::marker::Sync + std::marker::Send + std::fmt::Debug>(&self, thing: Thing) -> Result<bool> {
        Ok(self.select_thing::<T>(thing).await?.is_some())
    }

}


#[cfg(test)]
mod tests {
    use axum::extract::Path;

    use super::*;

    #[tokio::test]
    async fn db_create_mem() {
        let db = DB::create_db(DBLocation::Mem).await;
        let todos = db.get_todos_sql().await.unwrap();
        assert_eq!(todos.len(), 0);
    }
    
    #[tokio::test]
    async fn db_create_disk() {
        let db = DB::create_db(DBLocation::Disk(PathBuf::from("./").canonicalize().unwrap().join("tmp_database.db"))).await;
    }

}
#![allow(unused_imports)]

use std::sync::Arc;
use surrealdb::{
    Response, Surreal,
    sql::{Thing, Object},
    engine::local::{File, Mem, Db},
};
// use surrealdb::{kvs::Datastore, dbs::Session, opt::auth::Root, engine::remote::ws::Ws, };
use anyhow::Result;

mod models;
use models::todos::TodoInDB;
use models::vocab::Token;

#[derive(Clone)]
pub struct DB {
    pub db: Arc<Surreal<Db>>,
}

impl DB {
    pub async fn create_db(disk: bool) -> Self {
        let client: Surreal<Db> = match disk {
            true => Surreal::new::<File>("./temp.db").await.unwrap(),
            false => Surreal::new::<Mem>(()).await.unwrap()
        };

        client.use_ns("test").use_db("test").await.unwrap();

        DB {
            db: Arc::new(client),
        }
    }

    pub async fn delete_thing<T: serde::Serialize + for<'a> serde::Deserialize<'a> + std::marker::Sync + std::marker::Send + std::fmt::Debug>(&self, thing: Thing) -> Result<T> {
        match self.db.delete(thing).await? {
            Some::<T>(v) => Ok(v),
            _ => Err(anyhow::anyhow!("Error deleting thing"))
        }
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn db_create() {
        let db = DB::create_db(false).await;
        let todos = db.get_todos_sql().await.unwrap();
        assert_eq!(todos.len(), 0);
    }

}
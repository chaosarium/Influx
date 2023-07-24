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
use models::TodoInDB;

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

    pub async fn add_todo_sql(&self, text: String) -> Result<TodoInDB> { 
        let sql = "CREATE todos SET text = $title, completed = false"; 
        let mut res: Response = self.db
            .query(sql)
            .bind(("title", text))
            .await?;

        // dbg!(&res);
        match res.take(0) {
            Ok(Some::<TodoInDB>(v)) => Ok(v),
            _ => Err(anyhow::anyhow!("Error creating todo"))
        }
    }

    pub async fn get_todos_sql(&self) -> Result<Vec<TodoInDB>> {
        let sql = "SELECT * FROM todos";
        let mut res: Response = self.db
            .query(sql)
            .await?;

        // dbg!(res);
        match res.take(0) {
            Ok::<Vec<TodoInDB>, _>(v) => Ok(v),
            _ => Err(anyhow::anyhow!("Error getting todos"))
        }
    }

    pub async fn delete_todo_sql(&self, id: Thing) -> Result<()> {
        let sql = "DELETE todos:$id";
        let mut res: Response = self.db
            .query(sql)
            .bind(("id", id))
            .await?;

        // dbg!(res);
        match res.take(0) {
            Ok::<Vec<TodoInDB>, _>(v) => Ok(()),
            _ => Err(anyhow::anyhow!("Error deleting todo"))
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

    #[tokio::test]
    async fn db_task_add() {
        let db = DB::create_db(false).await;
        let add_todo_res1 = db.add_todo_sql("Hello world 1".into()).await.unwrap();
        assert_eq!(add_todo_res1.completed, false);
        assert_eq!(add_todo_res1.text, "Hello world 1");
        let add_todo_res2 = db.add_todo_sql("Hello world 2".into()).await.unwrap();
        assert_eq!(add_todo_res2.completed, false);
        assert_eq!(add_todo_res2.text, "Hello world 2");
        let add_todo_res3 = db.add_todo_sql("Hello world 3".into()).await.unwrap();
        assert_eq!(add_todo_res3.completed, false);
        assert_eq!(add_todo_res3.text, "Hello world 3");

        assert_ne!(add_todo_res1.id, add_todo_res2.id);
        assert_ne!(add_todo_res1.id, add_todo_res3.id);

        let todos = db.get_todos_sql().await.unwrap();
        assert_eq!(todos.len(), 3);
        for todo in todos {
            println!("{:?}", todo);
        }
    }

}
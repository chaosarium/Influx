use crate::db::{deserialize_surreal_thing_opt, InfluxResourceId};
///! a toy database
use maplit::btreemap;
use surrealdb::RecordIdKey;

use super::*;

#[derive(Debug, Serialize, Deserialize, Elm, ElmEncode, ElmDecode)]
pub struct TodoItem {
    #[serde(deserialize_with = "deserialize_surreal_thing_opt")]
    pub id: Option<InfluxResourceId>,
    pub text: String,
    pub completed: bool,
}

use super::DB::*;
impl DB {
    pub async fn add_todo(&self, text: String) -> Result<TodoItem> {
        match self {
            Surreal { engine } => {
                let sql = "CREATE todos SET text = $title, completed = false;";
                let mut res: Response = engine.query(sql).bind(("title", text)).await?;

                match res.take(0) {
                    Ok(Some::<TodoItem>(v)) => Ok(v),
                    _ => Err(anyhow::anyhow!("Error creating todo")),
                }
            }
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    TodoItem,
                    r#"
                        INSERT INTO todos (text, completed)
                        VALUES ($1, false)
                        RETURNING id as "id: Option<InfluxResourceId>", text, completed
                    "#,
                    text
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }

    pub async fn get_todos(&self) -> Result<Vec<TodoItem>> {
        match self {
            Surreal { engine } => {
                let sql = "SELECT * FROM todos;";
                let mut res: Response = engine.query(sql).await?;

                match res.take(0) {
                    Ok::<Vec<TodoItem>, _>(v) => Ok(v),
                    _ => Err(anyhow::anyhow!("Error getting todos")),
                }
            }
            Postgres { pool } => {
                let records = sqlx::query_as!(
                    TodoItem,
                    r#"
                        SELECT id as "id: Option<InfluxResourceId>", text, completed
                        FROM todos
                    "#
                )
                .fetch_all(pool.as_ref())
                .await?;

                Ok(records)
            }
        }
    }

    pub async fn delete_todo(&self, id: InfluxResourceId) -> Result<TodoItem> {
        match self {
            Surreal { engine } => match engine.delete(("todos", id)).await? {
                Some::<TodoItem>(v) => Ok(v),
                _ => Err(anyhow::anyhow!("Error deleting todo")),
            },
            Postgres { pool } => {
                let record = sqlx::query_as!(
                    TodoItem,
                    r#"
                        DELETE FROM todos
                        WHERE id = $1
                        RETURNING id as "id: Option<InfluxResourceId>", text, completed
                    "#,
                    id.as_i64()?
                )
                .fetch_one(pool.as_ref())
                .await?;

                Ok(record)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::DBLocation;

    #[tokio::test]
    async fn db_todos_operations() {
        for db_choice in [
            crate::DBChoice::SurrealMemory,
            crate::DBChoice::PostgresServer,
        ] {
            let db = DB::create_db(db_choice).await.unwrap();
            let add_todo_res1 = db.add_todo("Hello world 1".into()).await.unwrap();
            assert_eq!(add_todo_res1.completed, false);
            assert_eq!(add_todo_res1.text, "Hello world 1");
            let add_todo_res2 = db.add_todo("Hello world 2".into()).await.unwrap();
            assert_eq!(add_todo_res2.completed, false);
            assert_eq!(add_todo_res2.text, "Hello world 2");
            let add_todo_res3 = db.add_todo("Hello world 3".into()).await.unwrap();
            assert_eq!(add_todo_res3.completed, false);
            assert_eq!(add_todo_res3.text, "Hello world 3");

            assert_ne!(add_todo_res1.id, add_todo_res2.id);
            assert_ne!(add_todo_res1.id, add_todo_res3.id);

            let todos = db.get_todos().await.unwrap();
            assert_eq!(todos.len(), 3);
            for todo in todos {
                println!("{:?}", todo);
            }

            let deleted = db.delete_todo(add_todo_res1.id.unwrap()).await.unwrap();
            let todos = db.get_todos().await.unwrap();
            assert_eq!(todos.len(), 2);

            let deleted = db.delete_todo(add_todo_res2.id.unwrap()).await.unwrap();
            assert_eq!(deleted.text, "Hello world 2");
            let todos = db.get_todos().await.unwrap();
            assert_eq!(todos.len(), 1);

            let deleted = db.delete_todo(add_todo_res3.id.unwrap()).await.unwrap();
            assert_eq!(deleted.text, "Hello world 3");
            let todos = db.get_todos().await.unwrap();
            assert_eq!(todos.len(), 0);
        }
    }
}

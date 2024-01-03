use super::models_prelude::*;

#[derive(Debug, Serialize, Deserialize, TS)]
#[ts(export, export_to = "../bindings/")]
pub struct TodoInDB {
    #[serde(skip_serializing_if = "Option::is_none")]
    #[ts(type = "string")]
    pub id: Option<Thing>,
    pub text: String,
    pub completed: bool,
}

impl From<TodoInDB> for Value {
    fn from(val: TodoInDB) -> Self {
        match val.id {
            Some(v) => map![
                    "id".into() => v.into(),
                    "text".into() => val.text.into(),
                    "completed".into() => val.completed.into(),
            ]
            .into(),
            None => map![
                "text".into() => val.text.into(),
                "completed".into() => val.completed.into()
            ]
            .into(),
        }
    }
}

impl DB {
    pub async fn seed_todo_table(&self) -> Result<()> {
        self.add_todo_sql("todo1".into()).await.unwrap();
        self.add_todo_sql("todo2".into()).await.unwrap();
        
        Ok(())
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

        // dbg!(&res);
        match res.take(0) {
            Ok::<Vec<TodoInDB>, _>(v) => Ok(v),
            _ => Err(anyhow::anyhow!("Error getting todos"))
        }
    }

    pub async fn delete_todo_sql(&self, id: String) -> Result<TodoInDB> {
        // let sql = "DELETE todos WHERE id = $id";
        // let mut res: Response = self.db
        //     .query(sql)
        //     .bind(("id", &id))
        //     .await?;

        // dbg!(&res);
        // match res.take(0) {
        //     Ok::<Vec<TodoInDB>, _>(v) => Ok(v),
        //     _ => Err(anyhow::anyhow!("Error deleting todo"))
        // }

        // let res: Option<TodoInDB> = self.db.delete(("todos", &id)).await?;
        // dbg!(&res);
        // hmmm why does sql version not work?

        match self.db.delete(("todos", &id)).await? {
            Some::<TodoInDB>(v) => Ok(v),
            _ => Err(anyhow::anyhow!("Error deleting todo"))
        }
    }



}

#[cfg(test)]
mod tests {
    use crate::db::DBLocation;

    use super::*;

    #[test]
    fn test_todo_struct() {
        let todo = TodoInDB {
            id: None,
            text: "text".into(),
            completed: false,
        };

        let val: Value = todo.into();

        println!("{:?}", val);
    }

    #[tokio::test]
    async fn db_todos_operations() {
        let db = DB::create_db(DBLocation::Mem).await;
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

        let deleted = db.delete_todo_sql(add_todo_res1.id.unwrap().id.to_raw()).await.unwrap();
        let todos = db.get_todos_sql().await.unwrap();
        assert_eq!(todos.len(), 2);
        
        let deleted = db.delete_thing::<TodoInDB>(add_todo_res2.id.unwrap()).await.unwrap();
        assert_eq!(deleted.text, "Hello world 2");
        let todos = db.get_todos_sql().await.unwrap();
        assert_eq!(todos.len(), 1);
        
        let deleted = db.delete_thing::<TodoInDB>(add_todo_res3.id.unwrap()).await.unwrap();
        assert_eq!(deleted.text, "Hello world 3");
        let todos = db.get_todos_sql().await.unwrap();
        assert_eq!(todos.len(), 0);

    }

}
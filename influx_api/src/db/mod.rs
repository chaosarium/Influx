use std::sync::Arc;
use surrealdb::{
    Response, Surreal,
    sql::Thing,
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
            true => Surreal::new::<File>("/Users/chaosarium/Desktop/temp.db").await.unwrap(),
            false => Surreal::new::<Mem>(()).await.unwrap()
        };

        client.use_ns("test").use_db("test").await.unwrap();

        let db = DB {
            db: Arc::new(client),
        };

        db
    }

    pub async fn add_todo_sql(&self, text: String) -> Result<TodoInDB> { 
        let sql = "CREATE todos SET text = $title, completed = false"; 
        let mut res: Response = self.db
            .query(sql)
            .bind(("title", text))
            .await?;

        println!("{:?}", &res);
    
        let idk: Option<TodoInDB> = res.take(0)?;
        println!("{:?}", &idk);

        Ok(idk.unwrap())
    }

    pub async fn get_todos_sql(&self) -> Result<Vec<TodoInDB>> {
        let sql = "SELECT * FROM todos";

        let mut res: Response = self.db
            .query(sql)
            .await?;

        println!("{:?}", &res);
        
        let idk: Vec<TodoInDB> = res.take(0)?;
        println!("{:?}", &idk);

        Ok(idk)
    }

    pub async fn delete_todo_sql(&self, id: Thing) -> Result<()> {
        let sql = "DELETE todos:$id";

        let mut res: Response = self.db
            .query(sql)
            .bind(("id", id))
            .await?;

        println!("{:?}", &res);
        
        let idk: Vec<TodoInDB> = res.take(0)?;
        println!("{:?}", &idk);

        Ok(())
    }

    // /// add a task to db and return it as object
    // pub async fn add_task(&self, title: String) -> Result<(), crate::error::Error> {
    //     println!("hi");
    //     let created: Result<Task, _> = self.db.create("tasks")
    //         .content(Task {
    //             id: None,
    //             title: title.clone(),
    //             completed: false,
    //             created_at: Some(Utc::now()),
    //         })
    //         .await;
    //     println!("hi, we just created {:?}", created);

    //     dbg!(&created);
    //     Ok(())
    // }
    
}



#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn db_test() {
        let db = DB::create_db(false).await;
        let add_todo_res = db.add_todo_sql("Hello world 1".into()).await.unwrap();
        // let add_task_res = db.add_task_sql("Hello world 2".into()).await.unwrap();
        // let add_task_res = db.add_task_sql("Hello world 3".into()).await.unwrap();

        println!("\n\nget tasks");
        db.get_todos_sql().await.unwrap();

        // let add_task_res = db.add_task("Hello world".into()).await.unwrap();

    }

}
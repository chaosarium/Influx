//! Rebuilds todo list app but using SurrealDB
#![allow(dead_code, unused_imports, unused_variables, unused_macros)]

use axum::{
    Json, Router,
    routing::{get, post, patch, delete},
    extract::{Path, Query, State},
    response::IntoResponse, http::StatusCode,
};
use serde::{Deserialize, Serialize};
use std::{
    collections::HashMap,
    net::SocketAddr,
    sync::{Arc, RwLock},
    time::Duration,
};
use uuid::Uuid;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use surrealdb::{
    sql::{thing, Array, Object, Value},
    Response, Surreal,
};
use surrealdb::{sql::{Thing, Data}, kvs::Datastore, dbs::Session, engine::local::File, engine::local::Mem, engine::local::Db, opt::auth::Root, engine::remote::ws::Ws, };
use anyhow::Result;

macro_rules! map {
    ($($k:expr => $v:expr),* $(,)?) => {{
		let mut m = ::std::collections::BTreeMap::new();
        $(m.insert($k, $v);)+
        m
    }};
}


#[derive(Debug, Serialize, Deserialize)]
pub struct TodoInDB {
    #[serde(skip_serializing_if = "Option::is_none")]
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


async fn hello_world() -> &'static str {
    "Hello, World!"
}

async fn todos_index(State(db): State<DB>) -> impl IntoResponse {
    let todos = db.get_todos_sql().await.unwrap();
    Json(todos)
}

#[derive(Debug, Deserialize)]
struct CreateTodo {
    text: String,
}

async fn todos_create(
    State(db): State<DB>,
    Json(payload): Json<CreateTodo>,
) -> impl IntoResponse {
    let todo = db.add_todo_sql(payload.text).await.unwrap();

    (StatusCode::CREATED, Json(todo))
}

async fn todos_delete(Path(id): Path<String>, State(db): State<DB>) -> impl IntoResponse {
    db.delete_todo_sql(
        surrealdb::sql::thing(&id).unwrap()
    ).await.unwrap();
    (StatusCode::NO_CONTENT, Json(()))
}

pub async fn launch(disk: bool, seed: bool) {
    println!("launching with disk: {}, seed: {}", disk, seed);

    let db = DB::create_db(disk).await;

    if seed {
        db.add_todo_sql("todo1".into()).await.unwrap();
        db.add_todo_sql("todo2".into()).await.unwrap();
    }

    let app = Router::new()
        .route("/", get(hello_world))
        .route("/todos", get(todos_index).post(todos_create))
        // .route("/todos", post(todos_index))
        .route("/todos/:id", delete(todos_delete))
        .with_state(db);

    let addr = SocketAddr::from(([127, 0, 0, 1], 3000));
    println!("listening on http://{}", addr);
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}


#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn db_test() {
        let db = DB::create_db().await;
        let add_todo_res = db.add_todo_sql("Hello world 1".into()).await.unwrap();
        // let add_task_res = db.add_task_sql("Hello world 2".into()).await.unwrap();
        // let add_task_res = db.add_task_sql("Hello world 3".into()).await.unwrap();

        println!("\n\nget tasks");
        db.get_todos_sql().await.unwrap();

        // let add_task_res = db.add_task("Hello world".into()).await.unwrap();

    }

}
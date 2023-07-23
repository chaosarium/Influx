#![allow(unused_imports)]

use serde::{Deserialize, Serialize};
use surrealdb::sql::{Thing, Array, Object, Value};

use crate::map;
// use crate::utils::macros::map;

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
#![allow(unused_imports)]

mod models_prelude {
    pub use serde::{Deserialize, Serialize};
    pub use surrealdb::{sql::{Thing, Array, Object, Value}, sql, Response};
    pub use ts_rs::TS;
    pub use anyhow::Result;
    
    pub(crate) use crate::DB;
}

pub mod todos;
pub mod vocab;
pub mod lang;
pub mod phrase;
pub mod sandbox;
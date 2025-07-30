use crate::embedded_db::EmbeddedDb;
use crate::ServerState;
use anyhow::Result;
use axum::Router;

pub struct TestDb {
    pub db: crate::db::DB,
    _embedded_db: EmbeddedDb,
}

impl TestDb {
    pub async fn new() -> Result<Self> {
        let embedded_db = EmbeddedDb::new().await?;
        let db = embedded_db.db.clone();

        Ok(TestDb {
            db,
            _embedded_db: embedded_db,
        })
    }
}

pub fn create_test_app(state: ServerState) -> Router {
    crate::create_app_router(state)
}

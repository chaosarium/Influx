#[cfg(test)]
use crate::embedded_db::EmbeddedDb;
#[cfg(test)]
use anyhow::Result;

#[cfg(test)]
pub struct TestDb {
    pub db: crate::db::DB,
    _embedded_db: EmbeddedDb,
}

#[cfg(test)]
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

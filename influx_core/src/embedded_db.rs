use anyhow::Result;
use postgresql_embedded::{PostgreSQL, Settings};
use sqlx::PgPool;
use std::path::PathBuf;
use std::sync::Arc;
use tempfile::TempDir;

use crate::db::DB;

pub struct EmbeddedDb {
    pub db: DB,
    _temp_dir: TempDir,
    _postgresql: PostgreSQL,
}

fn get_persistent_installation_dir() -> Result<PathBuf> {
    let cache_dir = if let Some(cache_dir) = dirs::cache_dir() {
        cache_dir.join("influx_core").join("postgresql")
    } else {
        std::env::current_dir()?.join(".cache").join("postgresql")
    };

    tracing::info!(
        "Attempting to create cache directory at: {}",
        cache_dir.display()
    );

    match std::fs::create_dir_all(&cache_dir) {
        Ok(_) => tracing::info!("Successfully created/verified cache directory"),
        Err(e) => {
            tracing::warn!(
                "Failed to create cache directory: {}. Falling back to temp directory.",
                e
            );
            let fallback = std::env::temp_dir().join("influx_core_postgresql");
            std::fs::create_dir_all(&fallback)?;
            return Ok(fallback);
        }
    }

    Ok(cache_dir)
}

impl EmbeddedDb {
    pub async fn new() -> Result<Self> {
        let temp_dir = TempDir::new()?;
        let installation_dir = get_persistent_installation_dir()?;

        tracing::info!(
            "Using PostgreSQL installation cache at: {}",
            installation_dir.display()
        );

        let settings = Settings {
            data_dir: temp_dir.path().join("data"),
            installation_dir,
            timeout: Some(std::time::Duration::from_secs(30)),
            version: postgresql_embedded::VersionReq::parse("^16.0.0")?,
            port: 0, // Use random available port
            ..Default::default()
        };

        let mut postgresql = PostgreSQL::new(settings);
        postgresql.setup().await?;
        postgresql.start().await?;

        let database_url = postgresql.settings().url("postgres");
        let pool = PgPool::connect(&database_url).await?;

        sqlx::migrate!("./migrations").run(&pool).await?;

        Ok(EmbeddedDb {
            db: DB::Postgres {
                pool: Arc::new(pool),
            },
            _temp_dir: temp_dir,
            _postgresql: postgresql,
        })
    }

    pub fn connection_info(&self) -> String {
        self._postgresql.settings().url("postgres")
    }
}

impl Drop for EmbeddedDb {
    fn drop(&mut self) {
        // PostgreSQL will be automatically stopped when dropped
        // Temporary directory will be automatically cleaned up
        // Installation directory persists for next run
    }
}

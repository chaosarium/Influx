#![allow(unused_variables, dead_code)]
use clap::Parser;
use std::env;
use tracing::{error, info};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv()?;

    // Initialize tracing with structured logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "influx_core=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer().with_target(false))
        .init();

    let args = influx_core::InfluxCoreArgs::parse();

    if let Ok(current_dir) = env::current_dir() {
        info!(directory = ?current_dir, "Starting Influx Core");
    }
    info!(content_path = %args.influx_path, db_choice = ?args.db_choice, seed = args.seed, "Configuration loaded");

    if let Err(e) = influx_core::launch(args).await {
        error!(error = %e, "Failed to launch Influx Core");
        return Err(e.into());
    }

    Ok(())
}

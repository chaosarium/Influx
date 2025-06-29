// #![allow(warnings)]
use clap::Parser;
use log::info;
use std::env;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv()?;

    env_logger::Builder::new()
        .filter_level(log::LevelFilter::Info)
        .format_timestamp(None)
        .init();

    let args = influx_core::InfluxCoreArgs::parse();

    if let Ok(current_dir) = env::current_dir() {
        info!("Launching at {:?}", current_dir);
    }
    info!("Content path: {:?}", args.influx_path);

    influx_core::launch(args).await?;
    Ok(())
}

#![allow(unused_imports, unused_must_use)]
use std::env;

// use pyo3::prelude::*;
// use pyo3::types::IntoPyDict;

use clap::Parser;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Whether to run db on disk
    #[arg(short, long, default_value_t = false)]
    disk: bool,

    /// Whether to not seed database
    #[arg(short, long, default_value_t = true)]
    no_seed: bool,

    /// Path to content directory
    #[arg(short, long, default_value = "../toy_content")]
    influx_path: String,
}

#[tokio::main]
async fn main() {
    let args = Args::parse();

    if let Ok(current_dir) = env::current_dir() {
        println!("Launching at {:?}", current_dir);
    } 
    println!("Content path: {:?}", args.influx_path);

    influx_core::launch(
        args.disk, 
        !args.no_seed, 
        args.influx_path.into()
    ).await
}

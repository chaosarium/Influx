// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
#[allow(unused_imports)]

use std::thread;

#[tokio::main]
async fn main() {

  tokio::spawn(async move {
    println!("spawning influx_server");
    let _launched = influx_server::launch(false, true, "/Users/chaosarium/Documents/Dev/Influx/toy_content".into()).await;
  });

  tauri::Builder::default()
    .run(tauri::generate_context!())
    .expect("error while running tauri application");

}

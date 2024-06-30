// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
#[allow(unused_imports, unused_mut)]

use std::thread;
use tauri::{
  api::process::{Command, CommandEvent},
  Manager,
};
use tokio::io::{BufReader, AsyncBufReadExt};

#[tokio::main]
async fn main() {


  tokio::spawn(async move {
    println!("spawning influx_server");
    let _launched = influx_server::launch(false, true, "/Users/chaosarium/Dev/Influx/toy_content".into()).await;
  });


  
  let mut nlp_server_child_cmd = tokio::process::Command::from(
    std::process::Command::from(
      tauri::api::process::Command::new_sidecar("nlp_server")
        .expect("failed to setup `nlp_server` sidecar")
    ));

  dbg!(&nlp_server_child_cmd);
      
  let mut nlp_server_child = nlp_server_child_cmd
    .stdout(std::process::Stdio::piped())
    .stdin(std::process::Stdio::inherit())
    .stderr(std::process::Stdio::inherit())
    .arg("--port")
    .arg("3001")
    .arg("--influx_path")
    .arg("/Users/chaosarium/Dev/Influx/toy_content")
    .spawn()
    .expect("failed to spawn nlp_server");
  
    println!("nlp_server_child pid: {:?}", nlp_server_child.id());

  let stdout = nlp_server_child.stdout.take().expect("Failed to capture stdout");
  let reader = BufReader::new(stdout);

  tokio::spawn(async move {
      let mut lines = reader.lines();

      while let Some(line) = lines.next_line().await.expect("Failed to read line") {
          println!("[nlp_server_child]: {}", line);
      }
  });

  tokio::spawn(async move {
      let status = nlp_server_child.wait().await
        .expect("nlp_server_child process encountered an error");

      println!("nlp_server_child status was: {}", status);
  });
  
  tauri::Builder::default()
    // .setup(|app| {
    //   let window = app.get_window("main").unwrap();
    //   tauri::async_runtime::spawn(async move {
      
    //     let (mut rx, mut child) = Command::new_sidecar("main.bin")
    //       .expect("failed to setup `main.bin` sidecar")
    //       .args(["--port", "3001", "--influx_path", "/Users/chaosarium/Dev/Influx/toy_content"])
    //       .envs(vec![
    //         ("FLASK_ENV".to_string(), "development".to_string()),
    //         ("FLASK_DEBUG".to_string(), "1".to_string())
    //       ].into_iter().collect())
    //       .spawn()
    //       .expect("Failed to spawn packaged node");

    //     println!("child pid: {}", child.pid());

    //     // let mut i = 0;
    //     while let Some(event) = rx.recv().await {
    //       if let CommandEvent::Stdout(line) = event {
    //         println!("Child STDOUT: {}", line);
    //         // i += 1;
    //         // if i == 4 {
    //         //   child.write("message from Rust\n".as_bytes()).unwrap();
    //         //   i = 0;
    //         // }
    //       }
    //     }
    //   });

    //   Ok(())
    // })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");

}

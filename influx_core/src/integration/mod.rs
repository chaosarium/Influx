use anyhow::Result;
use async_trait::async_trait;
use reqwest::Client;
use serde_json::{json, Value};
use std::process::Command;

#[async_trait]
pub trait ExternalDict {
    async fn open_dictionary(&self, query: String);
}
pub struct MacOSDict;
#[async_trait]
pub trait ExternalTranslator {
    async fn translate_sequence(
        &self,
        input: String,
        from_lang_id: String,
        to_lang_id: String,
    ) -> Result<String>;
}
pub struct GoogleTranslate;

#[async_trait]
impl ExternalDict for MacOSDict {
    async fn open_dictionary(&self, query: String) {
        let url = format!("dict:///{}", query);
        // if let Err(err) = open::that(url) {
        //     eprintln!("Failed to open MacOS dictionary: {}", err);
        // }
        Command::new("open")
            // .arg("-g")
            .arg(url)
            .spawn()
            .expect("failed to open");
    }
}

#[async_trait]
impl ExternalTranslator for GoogleTranslate {
    async fn translate_sequence(
        &self,
        input: String,
        from_lang_id: String,
        to_lang_id: String,
    ) -> Result<String> {
        let client = Client::new();
        let url = format!("http://127.0.0.1:3001/extern_translate");
        let payload = json!({
            "text": input,
            "from_lang_id": from_lang_id,
            "to_lang_id": to_lang_id,
            "provider": "google",
        });
        let response = client.post(url).json(&payload).send().await?;
        let response_body: Value = response.json().await?;
        let translated_text = response_body["translated_text"].as_str().unwrap();
        Ok(translated_text.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn open_macos_dict() {
        let dict = MacOSDict;
        dict.open_dictionary("hello".to_string()).await;
    }

    #[tokio::test]
    async fn translate_sequence() {
        let translator = GoogleTranslate;
        let translated = translator
            .translate_sequence("It is nice".to_string(), "en".to_string(), "fr".to_string())
            .await;
        dbg!(translated.unwrap());
    }
}

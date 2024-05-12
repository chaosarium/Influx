use reqwest::Client;
use open::that;
use async_trait::async_trait;

#[async_trait]
trait ExternalDict {
    async fn open_dictionary(&self, query: String);
}

struct MacOSDict;

#[async_trait]
impl ExternalDict for MacOSDict {
    async fn open_dictionary(&self, query: String) {
        let url = format!("dict:///{}", query);
        if let Err(err) = open::that(url) {
            eprintln!("Failed to open MacOS dictionary: {}", err);
        }
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
}

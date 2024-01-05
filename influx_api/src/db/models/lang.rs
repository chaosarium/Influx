use super::models_prelude::*;
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize, TS, Clone, PartialEq, Eq, Hash)]
#[ts(export, export_to = "../bindings/")]
pub struct LanguageEntry {
    // #[serde(skip_serializing_if = "Option::is_none")]
    #[ts(type = "string")]
    pub id: Thing,
    pub code: String,
    pub name: String,
    pub dicts: Vec<String>,
}

impl LanguageEntry {
    pub fn simple_language(id_str: &str, code: &str, name: &str) -> Self {
        LanguageEntry {
            id: mk_lang_thing(id_str.to_string()),
            code: code.to_string(),
            name: name.to_string(),
            dicts: vec![],
        }
    }
}

const TABLE: &str = "lang";

pub fn mk_lang_thing(id: String) -> Thing {
    Thing::from((TABLE.to_string(), id))
}

impl DB {

    pub async fn language_exists(&self, id: String) -> Result<bool> {
        self.thing_exists::<LanguageEntry>(mk_lang_thing(id)).await
    }

    pub async fn create_language(&self, language: LanguageEntry) -> Result<LanguageEntry> {
        let created: Result<Vec<LanguageEntry>, surrealdb::Error> = self.db
            .create(TABLE)
            .content(language)
            .await;

        match created {
            Ok(mut v) => {
                if v.len() == 1 {
                    Ok(v.pop().unwrap())
                } else {
                    Err(anyhow::anyhow!("Created {} languages? Doesn't make sense", v.len()))
                }
            },
            Err(e) => Err(anyhow::anyhow!("Error creating language: {}", e))
        }
    }

    pub async fn get_languages_vec(&self) -> Result<Vec<LanguageEntry>> {
        let languages: Result<Vec<LanguageEntry>, surrealdb::Error> = self.db
            .select(TABLE)
            .await;

        match languages {
            Ok(v) => Ok(v),
            Err(e) => Err(anyhow::anyhow!("Error getting languages: {}", e))
        }
    }

    pub async fn get_language(&self, id: String) -> Result<Option<LanguageEntry>> {
        let language: Result<Option<LanguageEntry>, surrealdb::Error> = self.db
            .select(mk_lang_thing(id))
            .await;

        match language {
            Ok(v) => Ok(v),
            Err(e) => Err(anyhow::anyhow!("Error getting language: {}", e))
        }
    }

    pub async fn get_code_for_language(&self, id: String) -> Result<Option<String>> {
        let language: Result<Option<LanguageEntry>, surrealdb::Error> = self.db
            .select(mk_lang_thing(id))
            .await;

        match language {
            Ok(Some(v)) => Ok(Some(v.code)),
            Ok(None) => Ok(None),
            Err(e) => Err(anyhow::anyhow!("Error getting language: {}", e))
        }
    }
}

mod tests {
    use crate::db::DBLocation;

    use super::*;

    #[tokio::test]
    #[allow(unused_must_use)]
    async fn test_create_language() {
        let db = DB::create_db(DBLocation::Mem).await;

        assert!(!db.language_exists("en_demo".to_string()).await.unwrap());

        let language = LanguageEntry::simple_language("en_demo", "en", "English");

        let created = db.create_language(language.clone()).await.unwrap();
        assert_eq!(created, language);
        // dbg!(db.db.query("SELECT * FROM lang;").await);
        assert!(db.language_exists("en_demo".to_string()).await.unwrap());
    }

    #[tokio::test]
    #[allow(unused_must_use)]
    async fn test_get_language_info() {
        let db = DB::create_db(DBLocation::Mem).await;

        let created = db.create_language(LanguageEntry::simple_language("en_1", "en", "English 1")).await.unwrap();
        let created = db.create_language(LanguageEntry::simple_language("en_2", "en", "English 2")).await.unwrap();
        let created = db.create_language(LanguageEntry::simple_language("en_3", "en", "French ?")).await.unwrap();

        let languages = db.get_languages_vec().await.unwrap();
        assert_eq!(languages.len(), 3);
        dbg!(languages);
        // dbg!(db.db.query("SELECT * FROM lang;").await);

        let language = db.get_language("en_1".to_string()).await.unwrap().unwrap();
        assert_eq!(language, LanguageEntry::simple_language("en_1", "en", "English 1"));

        let code = db.get_code_for_language("en_1".to_string()).await.unwrap().unwrap();
        assert_eq!(code, "en");
    }
}
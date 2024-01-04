use super::models_prelude::*;
use std::collections::{HashMap, BTreeMap, HashSet};
use crate::prelude::*;

#[derive(Debug, Serialize, Deserialize, TS, Clone, PartialEq, Eq, Hash)]
#[ts(export, export_to = "../bindings/")]
pub enum TokenStatus {
    UNMARKED,
    L1,
    L2,
    L3,
    L4,
    L5,
    KNOWN,
    IGNORED,
}

#[derive(Debug, Serialize, Deserialize, TS, Clone, PartialEq, Eq, Hash)]
#[ts(export, export_to = "../bindings/")]
pub struct SRSInfo {
    dummy: String,
}

impl Default for SRSInfo {
    fn default() -> Self {
        SRSInfo {
            dummy: "dummy".to_string(),
        }
    }
}


#[derive(Debug, Serialize, Deserialize, TS, Clone, PartialEq, Eq, Hash)]
#[ts(export, export_to = "../bindings/")]
pub struct Token {
    #[serde(skip_serializing_if = "Option::is_none")]
    #[ts(type = "string")]
    pub id: Option<Thing>,
    pub orthography: String,
    pub lang_id: String,

    pub phonetic: String,
    
    pub status: TokenStatus,
    pub definition: String,
    pub notes: String,
    pub original_context: String,

    pub tags: Vec<String>, 
    pub srs: SRSInfo,
}

impl Token {
    pub fn unmarked_token(lang_id: &str, orthography: &str) -> Self {
        Token {
            id: None,
            orthography: orthography.to_string(),
            lang_id: lang_id.to_string(),
            phonetic: "".to_string(),
            status: TokenStatus::UNMARKED,
            definition: "".to_string(),
            notes: "".to_string(),
            original_context: "".to_string(),
            tags: vec![],
            srs: SRSInfo::default(),
        }
    }

    pub fn essential_token(lang_id: &str, orthography: &str) -> Self {
        Token {
            id: None,
            orthography: orthography.to_string(),
            lang_id: lang_id.to_string(),
            phonetic: "".to_string(),
            status: TokenStatus::L1,
            definition: "".to_string(),
            notes: "".to_string(),
            original_context: "".to_string(),
            tags: vec![],
            srs: SRSInfo::default(),
        }
    }

    pub fn fancier_token(lang_id: &str, orthography: &str, definition: &str, phonetic: &str, status: TokenStatus) -> Self {
        Token {
            id: None,
            orthography: orthography.to_string(),
            lang_id: lang_id.to_string(),
            phonetic: phonetic.to_string(),
            status: status,
            definition: definition.to_string(),
            notes: "".to_string(),
            original_context: "".to_string(),
            tags: vec![],
            srs: SRSInfo::default(),
        }
    }
}

impl DB {
    pub async fn seed_vocab_table(&self) -> Result<()> {
        let tokens = vec![
            Token::fancier_token(
                "fr_demo",
                "voix",
                "voice",
                "vwa",
                TokenStatus::L5,
            ),
            Token::fancier_token(
                "fr_demo",
                "cœur",
                "heart",
                "kœʀ",
                TokenStatus::L4,
            ),
            Token::fancier_token(
                "fr_demo",
                "qui",
                "谁",
                "",
                TokenStatus::L3,
            ),
            Token::fancier_token(
                "fr_demo",
                "au",
                "= à le, or",
                "",
                TokenStatus::L2,
            ),
            Token::fancier_token(
                "fr_demo",
                "kiwis",
                "kiwi plural",
                "kiwi",
                TokenStatus::L1,
            ),
            Token::fancier_token(
                "fr_demo",
                "les",
                "le -> les",
                "",
                TokenStatus::IGNORED,
            ),
        ];

        for token in tokens {
            self.create_token(token).await?;
        }

        Ok(())
    }

    pub async fn token_exists(&self, orthography: String, lang_id: String) -> Result<bool> {
        debug_assert!(orthography.to_lowercase() == orthography);

        let sql = "SELECT * FROM vocab WHERE orthography = $orthography AND lang_id = $lang_id";
        let mut res: Response = self.db
            .query(sql)
            .bind(("orthography", &orthography))
            .bind(("lang_id", &lang_id))
            .await?;

        // dbg!(&res);
        match res.take(0) {
            Ok(Some::<Token>(v)) => Ok(true),
            Ok(None) => Ok(false),
            Err(e) => Err(anyhow::anyhow!("Error creating token: {:?}", e)),
        }
    }

    // TODO assert token does not exist?
    pub async fn create_token(&self, token: Token) -> Result<Token> {
        debug_assert!(token.orthography.to_lowercase() == token.orthography);

        let sql = "CREATE vocab CONTENT $tkn";
        let mut res: Response = self.db
            .query(sql)
            .bind(("tkn", token))
            .await?;

        // dbg!(&res);
        match res.take(0) {
            Ok(Some::<Token>(v)) => Ok(v),
            Ok(None) => Err(anyhow::anyhow!("sql didn't fail but no token was returned")),
            Err(e) => Err(anyhow::anyhow!("Error creating token: {:?}", e)),
        }
    }

    pub async fn query_token_by_orthography(&self, orthography: String, lang_id: String) -> Result<Token> {
        debug_assert!(orthography.to_lowercase() == orthography);

        let sql = "SELECT * FROM vocab WHERE orthography = $orthography AND lang_id = $lang_id";
        let mut res: Response = self.db
            .query(sql)
            .bind(("orthography", orthography))
            .bind(("lang_id", lang_id))
            .await?;

        // dbg!(&res);
        // TODO handle more than 1 result
        match res.take(0) {
            Ok(Some::<Token>(v)) => Ok(v),
            _ => Err(anyhow::anyhow!("Error getting token"))
        }
    }

    pub async fn query_tokens_by_orthographies(&self, orthography_set: HashSet<String>, lang_id: String) -> Result<Vec<Token>> {
        for orthography in &orthography_set {
            debug_assert!(orthography.to_lowercase() == *orthography);
        }

        let sql = "SELECT * FROM vocab WHERE orthography INSIDE $orthography AND lang_id = $lang_id";
        let mut res: Response = self.db
            .query(sql)
            .bind(("orthography", orthography_set.iter().cloned().collect::<Vec<String>>()))
            .bind(("lang_id", lang_id))
            .await?;

        // dbg!(&res);
        match res.take(0) {
            Ok::<Vec<Token>, _>(v) => Ok(v),
            _ => Err(anyhow::anyhow!("Error getting token"))
        }
    }

    pub async fn delete_token_by_id(&self, id: String) -> Result<Token> {
        match self.db.delete(("tokens", &id)).await? {
            Some::<Token>(v) => Ok(v),
            _ => Err(anyhow::anyhow!("Error deleting todo"))
        }
    }

    /// query tokens, return set with unmarked tokens for missing orthographies
    pub async fn get_dict_from_orthography_set(&self, orthography_set: HashSet<String>, lang_id: String) -> Result<HashMap<String, Token>> {
        let query_result = self.query_tokens_by_orthographies(orthography_set.clone(), lang_id.clone()).await?;

        // loop through sequence, apply token if found, otherwise apply UNMARKED token
        let populated_seq: HashMap<String, Token> = orthography_set.iter().map(|orthography| {
            (orthography.to_string(), query_result.iter()
                .find(|token| token.orthography == *orthography) // BUG many case sensitivity issues
                .map(|token| Token::clone(token))
                .unwrap_or(Token::unmarked_token(&lang_id, orthography)))
        }).collect::<HashMap<String, Token>>().into();

        Ok(populated_seq)
    }

    pub async fn get_dict_from_orthography_seq(&self, orthography_seq: Vec<String>, lang_id: String) -> Result<HashMap<String, Token>> {
        let orthography_set: HashSet<String> = orthography_seq.iter().cloned().collect::<HashSet<String>>();
        self.get_dict_from_orthography_set(orthography_set, lang_id).await
    }

    pub async fn get_dict_from_text_set(&self, text_set: HashSet<String>, lang_id: String) -> Result<HashMap<String, Token>> {
        let orthography_set: HashSet<String> = text_set.iter().cloned().map(|x| x.to_lowercase()).collect::<HashSet<String>>();
        self.get_dict_from_orthography_set(orthography_set, lang_id).await
    }

    pub async fn get_dict_from_text_seq(&self, text_seq: Vec<String>, lang_id: String) -> Result<HashMap<String, Token>> {
        let orthography_set: HashSet<String> = text_seq.iter().cloned().map(|x| x.to_lowercase()).collect::<HashSet<String>>();
        self.get_dict_from_orthography_set(orthography_set, lang_id).await
    }

    pub async fn update_token(&self, token: Token) -> Result<Token> {
        let sql = "UPDATE vocab SET orthography = $orthography, lemma = $lemma, phonetic = $phonetic, status = $status, lang_id = $lang_id, definition = $definition, notes = $notes WHERE id = $id";
        let mut res: Response = self.db
            .query(sql)
            .bind(token)
            .await?;

        // dbg!(&res);
        match res.take(0) {
            Ok(Some::<Token>(v)) => Ok(v),
            _ => Err(anyhow::anyhow!("Error updating token"))
        }
    }

}

#[cfg(test)]
mod tests {
    use crate::db::DBLocation;

    use super::*;

    #[tokio::test]
    async fn test_create_token() {
        let db = DB::create_db(DBLocation::Mem).await;
        let token = Token::essential_token("langs:en_demo", "test");
        let token = db.create_token(token).await.unwrap();
        println!("{:?}", token);
    }

    #[tokio::test]
    async fn test_query_token_by_orthography() {
        let db = DB::create_db(DBLocation::Mem).await;
        let token = db.create_token(Token::fancier_token("langs:en_demo", "test", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        let token = db.create_token(Token::fancier_token("langs:en_demo", "wrong", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        let token = db.create_token(Token::fancier_token("langs:wrong", "test", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        let token = db.query_token_by_orthography("test".to_string(), "langs:en_demo".to_string()).await.unwrap();

        println!("query result: {:#?}", token);
        assert_eq!(token.orthography, "test".to_string());
        assert_eq!(token.phonetic, "tɛst".to_string());
        assert_eq!(token.definition, "testdef".to_string());
    }

    #[tokio::test]
    async fn test_query_tokens_by_orthographies() {
        let db = DB::create_db(DBLocation::Mem).await;
        add_dummy_tokens(&db).await;

        // make sure we can query all three tokens
        let tokens = db.query_tokens_by_orthographies(
            hashset!{
                "t1".to_string().to_lowercase(),
                "t2".to_string().to_lowercase(),
                "t3".to_string().to_lowercase(),
            },
            "langs:en".to_string()
        ).await.unwrap();
        println!("query result: {:#?}", tokens);
        assert!({
            tokens.iter().any(|token| token.orthography == "t1".to_string()) &&
            tokens.iter().any(|token| token.orthography == "t2".to_string()) &&
            tokens.iter().any(|token| token.orthography == "t3".to_string())
        });
    }

    async fn add_dummy_tokens(db: &DB) {
        db.create_token(Token::fancier_token("langs:en", "t1", "t1_def", "t1_phon", TokenStatus::L1)).await.unwrap();
        db.create_token(Token::fancier_token("langs:en", "t2", "t2_def", "t1_phon", TokenStatus::L1)).await.unwrap();
        db.create_token(Token::fancier_token("langs:en", "t3", "t3_def", "t1_phon", TokenStatus::L1)).await.unwrap();
    }

    #[tokio::test]
    async fn test_get_dict_from_text_seq() {
        let db = DB::create_db(DBLocation::Mem).await;
        add_dummy_tokens(&db).await;

        // make sure we can query all three tokens
        let tokens = db.get_dict_from_text_seq(
            vec![
                "T1".to_string().to_lowercase(),
                "T3".to_string().to_lowercase(),
                "t2".to_string().to_lowercase(),
            ],
            "langs:en".to_string()
        ).await.unwrap();
        println!("query result: {:#?}", tokens);
        assert!({
            tokens.iter().any(|(k, v)| *k == "t1".to_string() && v.orthography == "t1".to_string()) &&
            tokens.iter().any(|(k, v)| *k == "t2".to_string() && v.orthography == "t2".to_string()) &&
            tokens.iter().any(|(k, v)| *k == "t3".to_string() && v.orthography == "t3".to_string())
        });
    }
}
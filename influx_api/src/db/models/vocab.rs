use super::models_prelude::*;
use std::collections::{HashMap, BTreeMap, HashSet};
use crate::prelude::*;

#[derive(Debug, Serialize, Deserialize, TS, Clone, PartialEq, Eq, Hash)]
#[ts(export, export_to = "../influx_ui/src/lib/types/")]
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

const TABLE: &str = "vocab";
pub fn mk_vocab_thing(id: String) -> Thing {
    Thing::from((TABLE.to_string(), id))
}


#[derive(Debug, Serialize, Deserialize, TS, Clone, PartialEq, Eq, Hash)]
#[ts(export, export_to = "../influx_ui/src/lib/types/")]
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
#[ts(export, export_to = "../influx_ui/src/lib/types/")]
pub struct Token {
    #[serde(skip_serializing_if = "Option::is_none")]
    #[ts(type = "{ tb: string, id: {String: string} }")]
    pub id: Option<Thing>,
    pub lang_id: String,
    
    pub orthography: String,
    pub phonetic: String,
    pub definition: String,
    pub notes: String,
    pub original_context: String,
    
    pub status: TokenStatus,
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
                "parler",
                "speak",
                "",
                TokenStatus::L5,
            ),
            Token::fancier_token(
                "fr_demo",
                "parlerez",
                "speak",
                "inflection of parler",
                TokenStatus::L5,
            ),
            Token::fancier_token(
                "fr_demo",
                "habitaient",
                "lived",
                "inflection of habiter",
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

    /// requires that orthography is lowercase
    pub async fn token_exists(&self, orthography: String, lang_id: String) -> Result<bool> {
        debug_assert!(orthography.to_lowercase() == orthography);

        let sql = format!("SELECT * FROM {TABLE} WHERE orthography = $orthography AND lang_id = $lang_id");
        let mut res: Response = self.db
            .query(sql)
            .bind(("orthography", orthography))
            .bind(("lang_id", lang_id))
            .await?;

        // dbg!(&res);
        match res.take(0) {
            // Ok(Some::<Token>(v)) => Ok(Some(v)),
            // Ok(None) => Ok(None),
            Ok(v) => Ok({
                let tkns: Vec<Token> = v;
                tkns.len() != 0
            }),
            Err(e) => Err(anyhow::anyhow!("Error querying token: {:?}", e)),
        }
    }

    /// requires that orthography is lowercase
    /// requires that orthography is not already in database
    pub async fn create_token(&self, token: Token) -> Result<Token> {
        debug_assert!(token.orthography.to_lowercase() == token.orthography);
        assert!(self.token_exists(token.orthography.clone(), token.lang_id.clone()).await? == false);

        let sql = format!("CREATE {TABLE} CONTENT $tkn");
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

    /// requires that orthography is lowercase
    pub async fn query_token_by_orthography(&self, orthography: String, lang_id: String) -> Result<Option<Token>> {
        debug_assert!(orthography.to_lowercase() == orthography);

        let sql = format!("SELECT * FROM {TABLE} WHERE orthography = $orthography AND lang_id = $lang_id");
        let mut res: Response = self.db
            .query(sql)
            .bind(("orthography", orthography))
            .bind(("lang_id", lang_id))
            .await?;

        dbg!(&res);
        match res.take(0) {
            // Ok(Some::<Token>(v)) => Ok(Some(v)),
            // Ok(None) => Ok(None),
            Ok(v) => Ok({
                let tkns: Vec<Token> = v;
                if tkns.len() == 0 {
                    None
                } else if tkns.len() == 1 {
                    Some(tkns[0].clone())
                } else {
                    println!("WARN: More than one token returned for query_token_by_orthography, returning first token");
                    Some(tkns[0].clone())
                }
            }),
            Err(e) => Err(anyhow::anyhow!("Error querying token: {:?}", e)),
        }
    }

    pub async fn query_token_by_id(&self, id: String) -> Result<Option<Token>> {
        let res = self.db.select(mk_vocab_thing(id)).await;

        // dbg!(&res);
        match res {
            Ok(Some::<Token>(v)) => Ok(Some(v)),
            Ok(None) => Ok(None),
            Err(e) => Err(anyhow::anyhow!("Error querying token: {:?}", e)),
        }
    }


    /// requires that orthographies are lowercase
    pub async fn query_tokens_by_orthographies(&self, orthography_set: HashSet<String>, lang_id: String) -> Result<Vec<Token>> {
        for orthography in &orthography_set {
            debug_assert!(orthography.to_lowercase() == *orthography);
        }

        let sql = format!("SELECT * FROM {TABLE} WHERE orthography INSIDE $orthography AND lang_id = $lang_id");
        let mut res: Response = self.db
            .query(sql)
            .bind(("orthography", orthography_set.iter().cloned().collect::<Vec<String>>()))
            .bind(("lang_id", lang_id))
            .await?;

        // dbg!(&res);
        match res.take(0) {
            Ok::<Vec<Token>, _>(v) => Ok(v),
            _ => Err(anyhow::anyhow!("Error querying token"))
        }
    }

    pub async fn delete_token_by_id(&self, id: String) -> Result<Token> {
        match self.db.delete(mk_vocab_thing(id)).await? {
            Some::<Token>(v) => Ok(v),
            None => Err(anyhow::anyhow!("Error deleting token"))
        }
    }

    /// query tokens, return set with unmarked tokens for missing orthographies
    /// requires that orthographies are lowercase
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

    /// requires that orthographies are lowercase
    pub async fn get_dict_from_orthography_seq(&self, orthography_seq: Vec<String>, lang_id: String) -> Result<HashMap<String, Token>> {
        let orthography_set: HashSet<String> = orthography_seq.iter().cloned().collect::<HashSet<String>>();
        self.get_dict_from_orthography_set(orthography_set, lang_id).await
    }

    /// does not require that orthographies are lowercase. they will be converted to lowercase
    pub async fn get_dict_from_text_set(&self, text_set: HashSet<String>, lang_id: String) -> Result<HashMap<String, Token>> {
        let orthography_set: HashSet<String> = text_set.iter().cloned().map(|x| x.to_lowercase()).collect::<HashSet<String>>();
        self.get_dict_from_orthography_set(orthography_set, lang_id).await
    }
    
    /// does not require that orthographies are lowercase. they will be converted to lowercase
    pub async fn get_dict_from_text_seq(&self, text_seq: Vec<String>, lang_id: String) -> Result<HashMap<String, Token>> {
        let orthography_set: HashSet<String> = text_seq.iter().cloned().map(|x| x.to_lowercase()).collect::<HashSet<String>>();
        self.get_dict_from_orthography_set(orthography_set, lang_id).await
    }

    /// requires the token to have an id and previously exist in the database
    /// requires that orthography is lowercase
    /// fails if changing orthography while the new orthography is already in database
    pub async fn update_token_by_id(&self, token: Token) -> Result<Token> {
        assert!(token.id.is_some());
        assert!(token.orthography.to_lowercase() == token.orthography);
        {
            let existing_token = self.query_token_by_id(token.id.clone().unwrap().id.to_string()).await?;
            assert!(existing_token.is_some());
            let existing_token = existing_token.unwrap();
            if token.orthography != existing_token.orthography {
                if self.token_exists(token.orthography.clone(), token.lang_id.clone()).await? {
                    return Err(anyhow::anyhow!("Error updating token: orthography already exists"));
                }
            }
        }

        let sql = format!("UPDATE {TABLE} SET orthography = $orthography, lemma = $lemma, phonetic = $phonetic, status = $status, lang_id = $lang_id, definition = $definition, notes = $notes WHERE id = $id");
        let mut res: Response = self.db
            .query(sql)
            .bind(token)
            .await?;

        // dbg!(&res);
        match res.take(0) {
            Ok(Some::<Token>(v)) => Ok(v),
            Ok(None) => Err(anyhow::anyhow!("sql didn't fail but no token was returned")),
            Err(e) => Err(anyhow::anyhow!("Error updating token: {:?}", e)),
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
        let _ = db.create_token(Token::fancier_token("langs:en_demo", "test", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        let _ = db.create_token(Token::fancier_token("langs:en_demo", "wrong", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        let _ = db.create_token(Token::fancier_token("langs:wrong", "test", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        let res = db.query_token_by_orthography("test".to_string(), "langs:en_demo".to_string()).await;
        assert!(res.is_ok());
        let token = res.unwrap();
        assert!(token.is_some());
        let token = token.unwrap();

        println!("query result: {:#?}", token);
        assert_eq!(token.orthography, "test".to_string());
        assert_eq!(token.phonetic, "tɛst".to_string());
        assert_eq!(token.definition, "testdef".to_string());
    }

    #[tokio::test]
    async fn test_query_token_by_id() {
        let db = DB::create_db(DBLocation::Mem).await;
        let tkn: Token = db.create_token(Token::fancier_token("langs:en_demo", "test", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        let res = db.query_token_by_id(tkn.id.unwrap().id.to_string()).await;
        assert!(res.is_ok());
        let token = res.unwrap().unwrap();
        assert_eq!(token.orthography, "test".to_string());
    }

    #[tokio::test]
    async fn test_update_token() {
        let db = DB::create_db(DBLocation::Mem).await;
        let tkn1: Token = db.create_token(Token::fancier_token("langs:en_demo", "tkn1", "deforig", "", TokenStatus::L1)).await.unwrap();
        let tkn2: Token = db.create_token(Token::fancier_token("langs:en_demo", "tkn2", "deforig", "", TokenStatus::L1)).await.unwrap();
        let res1 = db.query_token_by_id(tkn1.id.unwrap().id.to_string()).await.unwrap().unwrap();
        let tkn1_new_bad_res = db.update_token_by_id(Token {
            id: res1.id.clone(),
            orthography: "tkn2".to_string(),
            lang_id: res1.lang_id.clone(),
            phonetic: res1.phonetic.clone(),
            status: res1.status.clone(),
            definition: res1.definition.clone(),
            notes: res1.notes.clone(),
            original_context: res1.original_context.clone(),
            tags: res1.tags.clone(),
            srs: res1.srs.clone(),
        }).await;
        assert!(tkn1_new_bad_res.is_err());
        let tkn1_new_good_res = db.update_token_by_id(Token {
            id: res1.id.clone(),
            orthography: "tkn1new".to_string(),
            lang_id: res1.lang_id.clone(),
            phonetic: res1.phonetic.clone(),
            status: res1.status.clone(),
            definition: res1.definition.clone(),
            notes: res1.notes.clone(),
            original_context: res1.original_context.clone(),
            tags: res1.tags.clone(),
            srs: res1.srs.clone(),
        }).await;
        assert!(tkn1_new_good_res.is_ok());

        assert!(db.token_exists("tkn1new".to_string(), "langs:en_demo".to_string()).await.unwrap());
        assert!(!db.token_exists("tkn1".to_string(), "langs:en_demo".to_string()).await.unwrap());
    }

    #[tokio::test]
    #[should_panic]
    async fn test_create_duplicate_tokens() {
        let db = DB::create_db(DBLocation::Mem).await;
        let _ = db.create_token(Token::fancier_token("langs:en_demo", "test", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        let _ = db.create_token(Token::fancier_token("langs:en_demo", "test", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();

        let res = db.query_token_by_orthography("test".to_string(), "langs:en_demo".to_string()).await;
        dbg!(&res);
    }
    
    #[tokio::test]
    async fn test_nonexistent_token_query() {
        let db = DB::create_db(DBLocation::Mem).await;
        let _ = db.create_token(Token::fancier_token("langs:en_demo", "test", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        let _ = db.create_token(Token::fancier_token("langs:en_demo", "wrong", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        let _ = db.create_token(Token::fancier_token("langs:wrong", "test", "testdef", "tɛst", TokenStatus::L1)).await.unwrap();
        
        let res = db.query_token_by_orthography("test".to_string(), "langs:fr_demo".to_string()).await;
        assert!(res.is_ok());
        let token = res.unwrap();
        assert!(token.is_none());
        let res = db.query_token_by_orthography("testt".to_string(), "langs:en_demo".to_string()).await;
        assert!(res.is_ok());
        let token = res.unwrap();
        assert!(token.is_none());
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
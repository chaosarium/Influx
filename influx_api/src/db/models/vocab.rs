use super::models_prelude::*;

#[derive(Debug, Serialize, Deserialize, TS, Clone, PartialEq)]
#[ts(export, export_to = "../bindings/")]
pub enum TokenStatus {
    UNMARKED,
    L1,
    L2,
    L3,
    L4,
    L5,
    IGNORED,
}

#[derive(Debug, Serialize, Deserialize, TS, Clone)]
#[ts(export, export_to = "../bindings/")]
pub struct Token {
    #[serde(skip_serializing_if = "Option::is_none")]
    #[ts(type = "string")]
    pub id: Option<Thing>,

    pub orthography: String,
    pub lemma: String,
    pub phonetic: String,
    pub status: TokenStatus,
    pub language: String, // TODO make this relate to language table?
}

impl DB {
    pub async fn create_token(&self, token: Token) -> Result<Token> {
        let sql = "CREATE tokens SET orthography = $orthography, lemma = $lemma, phonetic = $phonetic, status = $status, language = $language";
        let mut res: Response = self.db
            .query(sql)
            .bind(token)
            .await?;

        // dbg!(&res);
        match res.take(0) {
            Ok(Some::<Token>(v)) => Ok(v),
            _ => Err(anyhow::anyhow!("Error creating token"))
        }
    }

    pub async fn query_token_by_orthography(&self, orthography: String) -> Result<Token> {
        let sql = "SELECT * FROM tokens WHERE orthography = $orthography";
        let mut res: Response = self.db
            .query(sql)
            .bind(("orthography", orthography))
            .await?;

        // dbg!(&res);
        match res.take(0) {
            Ok(Some::<Token>(v)) => Ok(v),
            _ => Err(anyhow::anyhow!("Error getting token"))
        }
    }

    pub async fn query_tokens_by_orthographies(&self, orthographies: Vec<String>) -> Result<Vec<Token>> {
        let sql = "SELECT * FROM tokens WHERE orthography INSIDE $orthography";
        let mut res: Response = self.db
            .query(sql)
            .bind(("orthography", orthographies))
            .await?;

        // dbg!(&res);
        match res.take(0) {
            Ok::<Vec<Token>, _>(v) => Ok(v),
            _ => Err(anyhow::anyhow!("Error getting token"))
        }
    }

    pub async fn get_token_seq_from_orthography_seq(&self, orthography_seq: Vec<String>) -> Result<Vec<Token>> {
        let query_result = self.query_tokens_by_orthographies(orthography_seq.clone()).await?;

        // loop through sequence, apply token if found, otherwise apply UNMARKED token
        let populated_seq: Vec<Token> = orthography_seq.iter().map(|orthography| {
            query_result.iter()
                .find(|token| token.orthography == *orthography)
                .map(|token| Token::clone(token))
                .unwrap_or(Token {
                    id: None,
                    orthography: orthography.to_string(),
                    lemma: "".to_string(),
                    phonetic: "".to_string(),
                    status: TokenStatus::UNMARKED,
                    language: "".to_string(),
                })
        }).collect::<Vec<Token>>().into();

        Ok(populated_seq)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_create_token() {
        let db = DB::create_db(false).await;
        let token = Token {
            id: None,
            orthography: "test".to_string(),
            lemma: "test".to_string(),
            phonetic: "test".to_string(),
            status: TokenStatus::UNMARKED,
            language: "test".to_string(),
        };
        let token = db.create_token(token).await.unwrap();
        println!("{:?}", token);
    }

    #[tokio::test]
    async fn test_query_token_by_orthography() {
        let db = DB::create_db(false).await;
        let token = Token {
            id: None,
            orthography: "test".to_string(),
            lemma: "test".to_string(),
            phonetic: "test".to_string(),
            status: TokenStatus::UNMARKED,
            language: "test".to_string(),
        };
        let token = db.create_token(token).await.unwrap();
        let token = db.query_token_by_orthography("test".to_string()).await.unwrap();
        println!("query result: {:#?}", token);
        assert_eq!(token.orthography, "test".to_string());
    }

    #[tokio::test]
    async fn test_querying_lots_of_tokens() {
        let db = DB::create_db(false).await;
        db.create_token(Token {
            id: None,
            orthography: "token1".to_string(),
            lemma: "token1".to_string(),
            phonetic: "token1".to_string(),
            status: TokenStatus::L1,
            language: "token1".to_string(),
        }).await.unwrap();
        db.create_token(Token {
            id: None,
            orthography: "token2".to_string(),
            lemma: "token2".to_string(),
            phonetic: "token2".to_string(),
            status: TokenStatus::L1,
            language: "token2".to_string(),
        }).await.unwrap();
        db.create_token(Token {
            id: None,
            orthography: "token3".to_string(),
            lemma: "token3".to_string(),
            phonetic: "token3".to_string(),
            status: TokenStatus::L1,
            language: "token3".to_string(),
        }).await.unwrap();

        // make sure we can query all three tokens
        let tokens = db.query_tokens_by_orthographies(
            vec![
                "token1".to_string(),
                "token2".to_string(),
                "token3".to_string(),
            ]
        ).await.unwrap();
        // println!("query result: {:#?}", tokens);
        assert!({
            tokens.iter().any(|token| token.orthography == "token1".to_string()) &&
            tokens.iter().any(|token| token.orthography == "token2".to_string()) &&
            tokens.iter().any(|token| token.orthography == "token3".to_string())
        });

        // now query an entire sequence
        let tokens_sequence = db.get_token_seq_from_orthography_seq(
            vec![
                "token1".to_string(),
                "token2".to_string(),
                "token3".to_string(),
                "token1".to_string(),
                "somethingUnknown".to_string(),
                "token1".to_string(),
            ]
        ).await.unwrap();
        println!("sequence result: {:#?}", tokens_sequence);

        assert_eq!(tokens_sequence.len(), 6);
        assert_eq!(tokens_sequence[0].orthography, "token1".to_string());
        assert_eq!(tokens_sequence[1].orthography, "token2".to_string());
        assert_eq!(tokens_sequence[2].orthography, "token3".to_string());
        assert_eq!(tokens_sequence[3].orthography, "token1".to_string());
        assert_eq!(tokens_sequence[4].orthography, "somethingUnknown".to_string());
        assert_eq!(tokens_sequence[4].status, TokenStatus::UNMARKED);
        assert_eq!(tokens_sequence[5].orthography, "token1".to_string());

    }
}
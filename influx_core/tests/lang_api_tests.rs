use axum_test::http::StatusCode;
use axum_test::TestServer;
use expect_test::expect;
use influx_core::db::models::lang::{Language, ParserConfig};
use influx_core::db::InfluxResourceId;
use influx_core::test_utils::{create_test_app, TestDb};
use influx_core::ServerState;
use std::collections::HashMap;
use tabled::{settings::Style, Table, Tabled};

#[derive(Tabled)]
struct LanguageApiResponseRow {
    id: String,
    name: String,
    dicts: String,
    tts_rate: String,
    parser: String,
}

impl From<&Language> for LanguageApiResponseRow {
    fn from(lang: &Language) -> Self {
        Self {
            id: lang
                .id
                .as_ref()
                .map(|id| format!("{}", id))
                .unwrap_or_else(|| "None".to_string()),
            name: lang.name.clone(),
            dicts: format!("{:?}", lang.dicts),
            tts_rate: lang
                .tts_rate
                .map(|r| r.to_string())
                .unwrap_or_else(|| "None".to_string()),
            parser: lang.parser_config.which_parser.clone(),
        }
    }
}

fn create_test_language(name: &str) -> Language {
    let mut parser_args = HashMap::new();
    parser_args.insert("spacy_model".to_string(), "en_core_web_sm".to_string());

    Language {
        id: None,
        name: name.to_string(),
        dicts: vec!["dict1".to_string(), "dict2".to_string()],
        tts_rate: Some(1.0),
        tts_pitch: Some(0.5),
        tts_voice: Some("en-US".to_string()),
        deepl_source_lang: Some("EN".to_string()),
        deepl_target_lang: Some("ES".to_string()),
        parser_config: ParserConfig {
            which_parser: "base_spacy".to_string(),
            parser_args,
        },
    }
}

async fn setup_test_server() -> (TestServer, TestDb) {
    let test_db = TestDb::new().await.unwrap();
    let app = create_test_app(ServerState {
        db: test_db.db.clone(),
    });
    let server = TestServer::new(app).unwrap();
    (server, test_db)
}

#[tokio::test]
#[tracing_test::traced_test]
async fn test_get_empty_language_list() {
    let (server, _test_db) = setup_test_server().await;

    let response = server.get("/lang").await;
    response.assert_status_ok();

    let languages: Vec<Language> = response.json();
    assert!(languages.is_empty());

    // Snapshot test for empty response
    let table_rows: Vec<LanguageApiResponseRow> = languages.iter().map(Into::into).collect();
    let table = Table::new(table_rows).with(Style::rounded()).to_string();

    expect![[r#"
        ╭────┬──────┬───────┬──────────┬────────╮
        │ id │ name │ dicts │ tts_rate │ parser │
        ├────┼──────┼───────┼──────────┼────────┤"#]]
    .assert_eq(&table);
}

#[tokio::test]
#[tracing_test::traced_test]
async fn test_get_language_list_with_data() {
    let (server, test_db) = setup_test_server().await;

    // Create test data
    let lang1 = create_test_language("Japanese");
    let lang2 = create_test_language("Chinese");
    let _created1 = test_db.db.create_language(lang1).await.unwrap();
    let _created2 = test_db.db.create_language(lang2).await.unwrap();

    let response = server.get("/lang").await;
    response.assert_status_ok();

    let languages: Vec<Language> = response.json();
    assert_eq!(languages.len(), 2);

    // Snapshot test for populated response
    let table_rows: Vec<LanguageApiResponseRow> = languages.iter().map(Into::into).collect();
    let table = Table::new(table_rows).with(Style::rounded()).to_string();

    expect![[r#"
        ╭─────────────────────┬──────────┬────────────────────┬──────────┬────────────╮
        │ id                  │ name     │ dicts              │ tts_rate │ parser     │
        ├─────────────────────┼──────────┼────────────────────┼──────────┼────────────┤
        │ InfluxResourceId(1) │ Japanese │ ["dict1", "dict2"] │ 1        │ base_spacy │
        │ InfluxResourceId(2) │ Chinese  │ ["dict1", "dict2"] │ 1        │ base_spacy │
        ╰─────────────────────┴──────────┴────────────────────┴──────────┴────────────╯"#]]
    .assert_eq(&table);
}

#[tokio::test]
#[tracing_test::traced_test]
async fn test_get_language_by_id_success() {
    let (server, test_db) = setup_test_server().await;

    // Create test data
    let lang = create_test_language("Japanese");
    let created = test_db.db.create_language(lang).await.unwrap();
    let created_id = created.id.as_ref().unwrap();

    let response = server
        .get(&format!("/lang/{}", created_id.as_i64().unwrap()))
        .await;
    response.assert_status_ok();

    let language: Option<Language> = response.json();
    assert!(language.is_some());
    let language = language.unwrap();
    assert_eq!(language.name, "Japanese");

    // Snapshot test for single language response
    let table_rows = vec![LanguageApiResponseRow::from(&language)];
    let table = Table::new(table_rows).with(Style::rounded()).to_string();

    expect![[r#"
        ╭─────────────────────┬──────────┬────────────────────┬──────────┬────────────╮
        │ id                  │ name     │ dicts              │ tts_rate │ parser     │
        ├─────────────────────┼──────────┼────────────────────┼──────────┼────────────┤
        │ InfluxResourceId(1) │ Japanese │ ["dict1", "dict2"] │ 1        │ base_spacy │
        ╰─────────────────────┴──────────┴────────────────────┴──────────┴────────────╯"#]]
    .assert_eq(&table);
}

#[tokio::test]
#[tracing_test::traced_test]
async fn test_get_language_by_id_not_found() {
    let (server, _test_db) = setup_test_server().await;

    let response = server.get("/lang/999").await;
    response.assert_status(StatusCode::INTERNAL_SERVER_ERROR); // Based on the handler returning ServerError
    let error_text = response.text();
    assert!(error_text.contains("Language not found"));
}

#[tokio::test]
#[tracing_test::traced_test]
async fn test_get_language_by_id_invalid_format() {
    let (server, _test_db) = setup_test_server().await;

    let response = server.get("/lang/invalid").await;
    response.assert_status(StatusCode::INTERNAL_SERVER_ERROR); // Based on the handler returning ServerError for parse failure

    let error_text = response.text();
    assert!(error_text.contains("Invalid language ID format"));
}

#[tokio::test]
#[tracing_test::traced_test]
async fn test_update_language_success() {
    let (server, test_db) = setup_test_server().await;

    // Create test data
    let lang = create_test_language("Japanese");
    let created = test_db.db.create_language(lang).await.unwrap();

    // Update the language
    let mut updated_language = created.clone();
    updated_language.name = "日本語".to_string();
    updated_language.tts_rate = Some(1.5);

    let response = server.post("/lang/edit").json(&updated_language).await;
    response.assert_status_ok();

    let result_language: Language = response.json();
    assert_eq!(result_language.name, "日本語");
    assert_eq!(result_language.tts_rate, Some(1.5));

    // Snapshot test for update response
    let table_rows = vec![LanguageApiResponseRow::from(&result_language)];
    let table = Table::new(table_rows).with(Style::rounded()).to_string();

    expect![[r#"
        ╭─────────────────────┬────────┬────────────────────┬──────────┬────────────╮
        │ id                  │ name   │ dicts              │ tts_rate │ parser     │
        ├─────────────────────┼────────┼────────────────────┼──────────┼────────────┤
        │ InfluxResourceId(1) │ 日本語 │ ["dict1", "dict2"] │ 1.5      │ base_spacy │
        ╰─────────────────────┴────────┴────────────────────┴──────────┴────────────╯"#]]
    .assert_eq(&table);

    // Verify the change persisted in database
    let languages = test_db.db.get_languages_vec().await.unwrap();
    assert_eq!(languages.len(), 1);
    assert_eq!(languages[0].name, "日本語");
    assert_eq!(languages[0].tts_rate, Some(1.5));
}

#[tokio::test]
#[tracing_test::traced_test]
async fn test_update_language_without_id() {
    let (server, _test_db) = setup_test_server().await;

    // Try to update a language without an ID
    let lang = create_test_language("TestLang");

    let response = server.post("/lang/edit").json(&lang).await;
    response.assert_status(StatusCode::INTERNAL_SERVER_ERROR); // Should fail because ID is required

    let error_text = response.text();
    assert!(error_text.contains("Language ID is required for update"));
}

#[tokio::test]
#[tracing_test::traced_test]
async fn test_update_nonexistent_language() {
    let (server, _test_db) = setup_test_server().await;

    // Try to update a language that doesn't exist
    let mut lang = create_test_language("TestLang");
    lang.id = Some(InfluxResourceId::SerialId(999));

    let response = server.post("/lang/edit").json(&lang).await;
    response.assert_status(StatusCode::INTERNAL_SERVER_ERROR); // Should fail because language doesn't exist

    // Note: Based on the current handler implementation, this might return a different error
    // depending on whether the database returns an error or an empty result
}

#[tokio::test]
#[tracing_test::traced_test]
async fn test_complete_language_api_workflow() {
    let (server, test_db) = setup_test_server().await;

    // 1. Start with empty list
    let response = server.get("/lang").await;
    response.assert_status_ok();
    let languages: Vec<Language> = response.json();
    assert!(languages.is_empty());

    // 2. Create languages directly in database (API doesn't have create endpoint)
    let lang1 = create_test_language("Japanese");
    let lang2 = create_test_language("Chinese");
    let created1 = test_db.db.create_language(lang1).await.unwrap();
    let _created2 = test_db.db.create_language(lang2).await.unwrap();

    // 3. Get list with both languages
    let response = server.get("/lang").await;
    response.assert_status_ok();
    let languages: Vec<Language> = response.json();
    assert_eq!(languages.len(), 2);

    // 4. Get specific language by ID
    let response = server
        .get(&format!(
            "/lang/{}",
            created1.id.as_ref().unwrap().as_i64().unwrap()
        ))
        .await;
    response.assert_status_ok();
    let language: Option<Language> = response.json();
    assert!(language.is_some());
    assert_eq!(language.unwrap().name, "Japanese");

    // 5. Update a language
    let mut updated_language = created1.clone();
    updated_language.name = "日本語".to_string();
    updated_language.tts_rate = Some(2.0);

    let response = server.post("/lang/edit").json(&updated_language).await;
    response.assert_status_ok();
    let result: Language = response.json();
    assert_eq!(result.name, "日本語");
    assert_eq!(result.tts_rate, Some(2.0));

    // 6. Verify final state
    let response = server.get("/lang").await;
    response.assert_status_ok();
    let languages: Vec<Language> = response.json();

    let table_rows: Vec<LanguageApiResponseRow> = languages.iter().map(Into::into).collect();
    let table = Table::new(table_rows).with(Style::rounded()).to_string();

    expect![[r#"
        ╭─────────────────────┬─────────┬────────────────────┬──────────┬────────────╮
        │ id                  │ name    │ dicts              │ tts_rate │ parser     │
        ├─────────────────────┼─────────┼────────────────────┼──────────┼────────────┤
        │ InfluxResourceId(2) │ Chinese │ ["dict1", "dict2"] │ 1        │ base_spacy │
        │ InfluxResourceId(1) │ 日本語  │ ["dict1", "dict2"] │ 2        │ base_spacy │
        ╰─────────────────────┴─────────┴────────────────────┴──────────┴────────────╯"#]]
    .assert_eq(&table);
}

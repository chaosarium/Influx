use axum_test::TestServer;
use influx_core::{create_app_router, DBChoice, ServerState};
use insta::assert_debug_snapshot;
use std::fs;
use tempfile::TempDir;

#[tokio::test]
async fn test_dictionary_resource_serving() {
    let temp_dir = TempDir::new().unwrap();
    let dict_dir = temp_dir.path().join("fr-en");
    let res_dir = dict_dir.join("res");
    fs::create_dir_all(&res_dir).unwrap();

    let css_content = "body { color: red; }";
    fs::write(res_dir.join("style.css"), css_content).unwrap();

    let db = influx_core::db::DB::create_db(DBChoice::PostgresEmbedded)
        .await
        .unwrap();
    let state = ServerState {
        db,
        nlp_url: "http://test".to_string(),
        stardict_manager: std::sync::Arc::new(tokio::sync::Mutex::new(
            influx_core::integration::stardict::StardictManager::new(),
        )),
    };

    let app = create_app_router(state);
    let server = TestServer::new(app).unwrap();

    let response = server
        .get("/dictionary/resources/fr-en/res/style.css")
        .await;
    assert_debug_snapshot!(response.status_code(), @"404");
    assert_debug_snapshot!(response.text(), @r#"body { color: red; }"#);

    let response = server
        .get("/dictionary/resources/NonExistentDict/res/style.css")
        .await;
    assert_debug_snapshot!(response.status_code(), @"404");
    assert_debug_snapshot!(response.text(), @r#""""#);
}

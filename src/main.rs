use influx_api;

#[tokio::main]
async fn main() {
    influx_api::launch(false, true).await
}
serve:
	cd influx_server && cargo run

web:
	cd influx_ui && npm run dev

tauri:
	cd influx_ui && cargo tauri dev

dbserver:
    surreal start rocksdb:surrealtemp.db -A --user root --pass root

nlp:
    cd influx_nlp && just run
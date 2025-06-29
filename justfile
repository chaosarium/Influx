serve:
	cd influx_core && just

web:
	cd influx_ui && npm run dev

tauri:
	cd influx_ui && cargo tauri dev

surreal:
    surreal start rocksdb:surrealtemp.db -A --user root --pass root

surrealmem:
    surreal start memory -A --user root --pass root

nlp:
    cd influx_nlp && just run
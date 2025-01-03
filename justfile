serve:
	cd influx_server && cargo run

web:
	cd influx_ui && npm run dev

tauri:
	cd influx_ui && cargo tauri dev

nlp:
	cd nlp_server && source ../py_venv/bin/activate && python main.py --port 3001 --influx_path ../toy_content

nlpbuild:
	cd nlp_server && source ../py_venv/bin/activate && pyinstaller --onefile main.py --name nlp_server-aarch64-apple-darwin

nlpclean:
	rm -rf nlp_server/dist
	rm -rf nlp_server/build
	rm -rf nlp_server/nlp_server.spec

nlpbin:
	./nlp_server/dist/nlp_server --port 3001 --influx_path ../toy_content
serve:
	cd influx_server && cargo run

web:
	cd influx_ui && npm run dev

nlp:
	cd nlp_server && source ../py_venv/bin/activate && python main.py --port 3001 --influx_path ../toy_content

nlpbuild:
	cd nlp_server && source ../py_venv/bin/activate && pyinstaller --onefile main.py 

nlpclean:
	rm -rf nlp_server/dist
	rm -rf nlp_server/build
	rm -rf nlp_server/main.spec

nlpbin:
	./nlp_server/dist/main --port 3001 --influx_path ../toy_content
serve:
	cd influx_server && cargo run

web:
	cd influx_ui && npm run dev

nlp:
	cd nlp_server && source ../py_venv/bin/activate && python main.py --port 3001 --influx_path ../toy_content

nlpbin:
	cd nlp_server && ./main.bin --port 3001 --influx_path ../toy_content


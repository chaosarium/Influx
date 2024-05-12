serve:
	$(MAKE) serve -C influx_server

web:
	$(MAKE) dev -C influx_ui

nlp:
	$(MAKE) rundev -C nlp_server

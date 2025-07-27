serve:
	cd influx_core && just

surreal:
    surreal start rocksdb:surrealtemp.db -A --user root --pass root

surrealmem:
    surreal start memory -A --user root --pass root

nlp:
    cd influx_nlp && just run

fmt:
    cd influx_core && just fmt
    cd influx_nlp && just fmt
    cd influx_client && just fmt

push:
    jj bookmark set dev -r @-
    jj git push --all

push-main:
    jj bookmark set main -r @-
    jj git push --all
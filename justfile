serve:
	cd influx_core && just

nlp:
    cd influx_nlp && just

client:
    cd influx_client && just sass &
    cd influx_client && just

surreal:
    surreal start rocksdb:surrealtemp.db -A --user root --pass root

surrealmem:
    surreal start memory -A --user root --pass root


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

new-empty-parent:
    jj new
    jj squash --from=@- --to=@ --keep-emptied
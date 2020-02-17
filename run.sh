#!/bin/sh

# allow TRIGGER_FILE env override
if [ -z "$TRIGGER_FILE" ] ; then
    TRIGGER_FILE=/tmp/trigger
fi

set -e

while `true`; do
    $@ &
    mosquitto_pid=$!

    inotifywait -e attrib $TRIGGER_FILE
    kill $mosquitto_pid
    
    echo -n "restarting mosquitto (pid $mosquitto_pid)"
    while [ "`pgrep mosquitto`" != "" ]; do
	echo -n .
	sleep 0.1
    done
    echo done
done

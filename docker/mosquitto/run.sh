#!/bin/sh

# this design is only necessary due to mosquitto not (yet) supporting the idea of certificates
# changing on disk, and being able to re-read them upon a signal (or even better being able to detect the change)
# an open ticket exists for this behavior.  if that behavior exists someday then this container would simply
# be the mosquitto-eclipse container

# instead, launch mosquitto in the background given the command line arguments, and block on
# the TRIGGER_FILE attributes changing (even a 'touch' command triggers it).  restart the
# mosquitto process when that happens.

# allow TRIGGER_FILE env override
if [ -z "$TRIGGER_FILE" ] ; then
    TRIGGER_FILE=/tmp/trigger
fi

set -e

# don't start mosquitto until trigger exists
if [ ! -f $TRIGGER_FILE ]; then
    echo "Initial certificate not yet generated, will try again shortly"
    sleep 5
fi

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

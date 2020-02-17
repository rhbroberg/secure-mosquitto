Stand up a mosquitto server with specified encryption.  The intent is to support:
 * none
 * self-signed cert
 * letsencrypt signed certs
 * psk

This image is a simple extension of the eclipse-mosquitto official image, with a wrapper 'run.sh' script.  The script monitors a file (mapped from a host volume).  When any attribute change is made to the file, the mosquitto process is restarted.  This allows the mosquitto server to be restarted from the outside of the container.  This feature is what allows glue from the LetsEncrypt certificate change to a mosquitto service restart without resorting to using the docker socket, while allowing the LetsEncrypt service to run in another container.

Building.  My host is called ubuntu-18-04-06.brobasino.lan.  change abstraction for yours

    make docker-image

For self-signed cert:

    make do-self-signed DOMAIN=ubuntu-18-04-06.brobasino.lan
    docker run -d --name secure-mosquitto -p 1883:1883 -p 8883:8883 -v `pwd`/config:/mosquitto/config -v `pwd`/trigger:/tmp/trigger secure-mosquitto

Test with:
     mosquitto_sub -h ubuntu-18-04-06.brobasino.lan -t /foo --cafile ./certs/ca.crt -p 8883 &
     mosquitto_pub -h ubuntu-18-04-06.brobasino.lan -t /foo --cafile ./certs/ca.crt -m "foobar" -p 8883

Note: if you want to use your own CA as root,
      mkdir -p certs
      cp /path/to/your/ca certs/ca.crt
      make do-self-signed DOMAIN=ubuntu-18-04-06.brobasino.lan

For letsencrypt cert:

    -e TRIGGER_FILE=/tmp/trigger


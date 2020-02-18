Stand up a mosquitto server with specified encryption.  The intent is to support:
 * none
 * self-signed cert
 * letsencrypt signed certs
 * psk

This image is a simple extension of the eclipse-mosquitto official image, with a wrapper 'run.sh' script.  The script monitors a file (mapped from a host volume).  When any attribute change is made to the file, the mosquitto process is restarted.  This allows the mosquitto server to be restarted from the outside of the container.  This feature is what allows glue from the LetsEncrypt certificate change to a mosquitto service restart without resorting to using the docker socket, while allowing the LetsEncrypt service to run in another container.

I have included the Dockerfiles for the 2 containers to be built here in case you want to extend them.

Building.  My DOMAIN is called ubuntu-18-04-06.brobasino.lan.  Update the .env file for your DOMAIN and EMAIL.

    make -C docker

For self-signed cert:

    make do-self-signed DOMAIN=$DOMAIN
    docker run -d --name secure-mosquitto -p 1883:1883 -p 8883:8883 -v `pwd`/volumes/mosquitto/config:/mosquitto/config -v `pwd`/volumes/mosquitto/log:/mosquitto/log -v `pwd`/trigger:/tmp/trigger secure-mosquitto

Test with:

     mosquitto_sub -h ubuntu-18-04-06.brobasino.lan -t /foo --cafile ./certs/ca.crt -p 8883 &
     mosquitto_pub -h ubuntu-18-04-06.brobasino.lan -t /foo --cafile ./certs/ca.crt -m "foobar" -p 8883

For self-signed cert with your own CA as the root:

      mkdir -p certs
      cp /path/to/your/ca certs/ca.crt
      make do-self-signed

Test the same way as above with self-signed cert.

For letsencrypt cert (make sure your docker host is reachable from the internet on ports 80 and 443 by the DOMAIN name you choose).

    make do-le
    docker-compose up -d

You might want to try to specify DRYRUN=true in the environment as well until you are convinced your forwarding and dns are correct.  This will result in a system with a certificate which mosquitto can use, but it will not be fully functional.

    env DRYRUN=true docker-compose up -d

Test with:

     mosquitto_sub -h mqtt.brobasino.onthegrid.net -p 8883 --capath /etc/ssl/certs/ -t /foo &
     mosquitto_pub -h mqtt.brobasino.onthegrid.net -p 8883 --capath /etc/ssl/certs/ -t /foo -m bar

For no encryption (for completeness: arguably using eclipse-mosquitto would be easier, but if you are testing and want it simple):

    make do-cleartext
    docker run -d --name secure-mosquitto -p 1883:1883 -v `pwd`/volumes/mosquitto/config:/mosquitto/config -v `pwd`/volumes/mosquitto/log:/mosquitto/log -v `pwd`/trigger:/tmp/trigger secure-mosquitto

Test with:

     mosquitto_sub -h ubuntu-18-04-06.brobasino.lan -t /foo -p 1883 &
     mosquitto_pub -h ubuntu-18-04-06.brobasino.lan -t /foo -m "foobar" -p 1883

Random musings:
     useful configuration options
	    - 'psk_hint foo'
	    - 'psk_file /path/to/file'
     	    - 'queue_qos0_messages true' -- allow durable client subscription to receive published messages even if only qos=0
	    - 'persistence true'
	    - 'persistence_location /path/to/file'
	    - 'persistent_client_expiration duration'
	    - 'autosave_interval interval' (interpreted as seconds or count, based on true or false below)
	    - 'autosave_on_changes true'
	    
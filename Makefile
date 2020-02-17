DOMAIN		= brobasino.onthegrid.net
PSK_HINT	= mymqtt
PASSWORD	= password

docker-image:	config/mosquitto.conf
	docker build -t secure-mosquitto .

clean:
	rm -rf mosquitto templates/mosquitto.conf certs config

config:
	@mkdir -p $@

config/config.d:	
	@mkdir -p $@

templates/mosquitto.conf:
	wget -q -O templates/mosquitto.conf https://raw.githubusercontent.com/eclipse/mosquitto/master/mosquitto.conf

config/mosquitto.conf:	config templates/mosquitto.conf
	@perl -p -e 's|^#user .*|user mosquitto|g; s|^#allow_anonymous.*|allow_anonymous true|g; s|^#include_dir.*|include_dir /mosquitto/config/config.d|g' < templates/mosquitto.conf > $@

do-self-signed:	config/config.d/certs.conf self-signed-certs

config/config.d/certs.conf:	config/config.d templates/certs.conf
	@perl -p -e s'/DOMAIN/$(DOMAIN)/g' < templates/certs.conf > config/config.d/certs.conf

config/config.d/psk.conf:	config/config.d templates/psk.conf
	@perl -p -e s'/PSK_HINT/$(PSK_HINT)/g' < templates/psk.conf > config/config.d/psk.conf

certs:
	@mkdir -p $@

certs/server:	certs
	@mkdir -p $@

certs/client:	certs
	@mkdir -p $@

config/certs:	certs
	@mkdir -p $@

self-signed-certs:	server-certs

certs/ca.key:	certs
	openssl genrsa -out certs/ca.key 2048

certs/ca.crt:	certs/ca.key
	openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=MA/L=Boston/O=Dis/CN=$(DOMAIN)" -keyout certs/ca.key -out certs/ca.crt

certs/server.key:	certs/ca.crt
	openssl genrsa -out certs/server.key 2048

certs/server.csr:	certs/server.key
	openssl req -new -out certs/server.csr -key certs/server.key -subj "/C=US/ST=MA/L=Boston/O=Dis-Server/CN=$(DOMAIN)" -keyout certs/ca.key

certs/server.crt:	certs/server.csr
	openssl x509 -req -in certs/server.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/server.crt -days 360

SERVER_CERT_FILES	= ca.crt server.crt server.key
MQTT_CERTS		= $(addprefix config/certs/,$(SERVER_CERT_FILES))

server-certs:	config/certs $(MQTT_CERTS)

$(MQTT_CERTS):	config/certs/%: certs/%
	install -m 644 $< $@
include .env

PSK_HINT	= $(DOMAIN)
MOS_CONFIG_DIR	= volumes/mosquitto/config

all:
	@echo choose do-self-signed or do-le

do-self-signed:	$(MOS_CONFIG_DIR)/config.d/self-certs.conf $(MOS_CONFIG_DIR)/mosquitto.conf $(MOS_CONFIG_DIR)/config.d/logging.conf self-signed-certs

do-le:	$(MOS_CONFIG_DIR)/config.d/le-certs.conf $(MOS_CONFIG_DIR)/mosquitto.conf $(MOS_CONFIG_DIR)/config.d/logging.conf

do-cleartext:	$(MOS_CONFIG_DIR)/mosquitto.conf $(MOS_CONFIG_DIR)/config.d/logging.conf

config:
	@mkdir -p $@

$(MOS_CONFIG_DIR)/config.d:
	@mkdir -p $@

templates/mosquitto.conf:
	wget -q -O templates/mosquitto.conf https://raw.githubusercontent.com/eclipse/mosquitto/master/mosquitto.conf

$(MOS_CONFIG_DIR)/mosquitto.conf:	config templates/mosquitto.conf
	@perl -p -e 's|^#user .*|user mosquitto|g; s|^#allow_anonymous.*|allow_anonymous true|g; s|^#include_dir.*|include_dir /mosquitto/config/config.d|g' < templates/mosquitto.conf > $@

$(MOS_CONFIG_DIR)/config.d/logging.conf:	$(MOS_CONFIG_DIR)/config.d templates/logging.conf
	@perl -p -e s'/DOMAIN/$(DOMAIN)/g' < templates/logging.conf > $@

$(MOS_CONFIG_DIR)/config.d/self-certs.conf:	$(MOS_CONFIG_DIR)/config.d templates/self-certs.conf
	@perl -p -e s'/DOMAIN/$(DOMAIN)/g' < templates/self-certs.conf > $@

$(MOS_CONFIG_DIR)/config.d/le-certs.conf:	$(MOS_CONFIG_DIR)/config.d templates/le-certs.conf
	@perl -p -e s'/DOMAIN/$(DOMAIN)/g' < templates/le-certs.conf > $@

$(MOS_CONFIG_DIR)/config.d/psk.conf:	$(MOS_CONFIG_DIR)/config.d templates/psk.conf
	@perl -p -e s'/PSK_HINT/$(PSK_HINT)/g' < templates/psk.conf > $@

certs:
	@mkdir -p $@

certs/server:	certs
	@mkdir -p $@

certs/client:	certs
	@mkdir -p $@

$(MOS_CONFIG_DIR)/certs:	certs
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
MQTT_CERTS		= $(addprefix $(MOS_CONFIG_DIR)/certs/,$(SERVER_CERT_FILES))

server-certs:	$(MOS_CONFIG_DIR)/certs $(MQTT_CERTS)
	@touch trigger

$(MQTT_CERTS):	$(MOS_CONFIG_DIR)/certs/%: certs/%
	install -m 644 $< $@

clean:
	rm -rf mosquitto templates/mosquitto.conf certs config certbot-image mosquitto-image

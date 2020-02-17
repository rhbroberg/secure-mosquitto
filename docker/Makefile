docker-images:	mosquitto-image certbot-image

mosquitto-image:	mosquitto/Dockerfile mosquitto/run.sh
	cd mosquitto && docker build -t secure-mosquitto .
	touch $@

certbot-image:	certbot/Dockerfile certbot/certbot.sh
	cd certbot && docker build -t certbot .
	touch $@

clean:
	rm -rf certbot-image mosquitto-image

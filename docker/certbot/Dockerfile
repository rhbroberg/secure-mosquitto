FROM python:2.7-alpine

RUN \
	apk update && \
	apk upgrade && \
	apk add \
		coreutils \
        	py-crypto \
		ca-certificates \
        	certbot \
	rm -f /var/cache/apk/*

WORKDIR /opt

COPY certbot.sh .

EXPOSE 80
EXPOSE 443

CMD ["/bin/sh","-c","./certbot.sh"]

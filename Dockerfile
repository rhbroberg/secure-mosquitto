FROM eclipse-mosquitto

RUN \
    apk update && \
    apk upgrade && \
    apk add inotify-tools \
    rm -f /var/cache/apk/*

WORKDIR /opt

COPY run.sh .

CMD [ "sh", "-c", "./run.sh /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf" ]

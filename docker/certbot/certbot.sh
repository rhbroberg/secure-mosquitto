#!/bin/sh -e

set -e

DOMAIN=mqtt.brobasino.onthegrid.net
EMAIL=rhbroberg@gmail.com
CERT_LOCATION=/etc/letsencrypt/live/$DOMAIN
CHECK_DELAY=1d
#CHECK_DELAY=120s
#DRYRUN=x

if [ -n "DRYRUN" ]; then
    DRYRUN_RETRIEVE_ARGS="--staging --test-cert $EXTRA_RETRIEVE_ARGS"
    DRYRUN_RENEW_ARGS="--dry-run $EXTRA_RENEW_ARGS"
fi

while `true` ; do
    echo "Checking certificates in $CERT_LOCATION"

    if [ -d "$CERT_LOCATION" ]; then
	echo "Rewnewing existing certificate"
	certbot renew $DRYRUN_RENEW_ARGS --noninteractive --post-hook "touch /tmp/trigger"
    else
	echo "Retrieving new certificate for $DOMAIN"
	certbot certonly $DRYRUN_RETRIEVE_ARGS --standalone --agree-tos --preferred-challenges http -n -d $DOMAIN -m $EMAIL --post-hook "touch /tmp/trigger"
    fi

    echo "Sleeping $CHECK_DELAY seconds until next check"
    sleep $CHECK_DELAY
done

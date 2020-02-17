#!/bin/sh -e

set -e

#DRYRUN=x
CERT_LOCATION=/etc/letsencrypt/live/$DOMAIN
CHECK_DELAY=1d

if [ -n "$DRYRUN" ]; then
    echo "Warning: in dryrun mode, certificate isn't fully functional"
    DRYRUN_RETRIEVE_ARGS="--staging --test-cert $EXTRA_RETRIEVE_ARGS"
    DRYRUN_RENEW_ARGS="--dry-run $EXTRA_RENEW_ARGS"
    CHECK_DELAY=120s
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

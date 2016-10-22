#!/usr/bin/env bash

if [ -n "$CERTS" ]; then
    certbot certonly --no-self-upgrade -n --text --standalone \
        --standalone-supported-challenges http-01 \
        -d "$CERTS" --keep --expand --agree-tos --email "$EMAIL" \
        || exit 1

    mkdir -p /usr/local/etc/haproxy/certs
    for site in `ls -1 /etc/letsencrypt/live`; do
        cat /etc/letsencrypt/live/$site/privkey.pem \
          /etc/letsencrypt/live/$site/fullchain.pem \
          | tee /usr/local/etc/haproxy/certs/haproxy-"$site".pem >/dev/null
    done
fi

exit 0

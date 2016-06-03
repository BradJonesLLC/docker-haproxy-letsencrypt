#!/usr/bin/env bash

letsencrypt-auto certonly --no-self-upgrade -n --text --standalone \
    --standalone-supported-challenges http-01 \
    -d "$CERTS" --keep --agree-tos --email "$EMAIL"

for site in `ls -1 /etc/letsencrypt/live`; do
cat /etc/letsencrypt/live/$site/privkey.pem \
  /etc/letsencrypt/live/$site/fullchain.pem \
  | tee /usr/local/etc/haproxy/certs/haproxy-"$site".pem >/dev/null
done

exit $?

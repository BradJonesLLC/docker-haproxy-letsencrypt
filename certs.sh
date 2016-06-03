#!/usr/bin/env bash

letsencrypt-auto certonly --no-self-upgrade -n --text --standalone \
    --standalone-supported-challenges http-01 \
    -d "$CERTS" --keep --agree-tos --email "$EMAIL"

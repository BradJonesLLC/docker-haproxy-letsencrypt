#!/usr/bin/env bash

letsencrypt-auto certonly --text --webroot --webroot-path /jail \
    -d "$CERTS" --keep --agree-tos --email "$EMAIL"

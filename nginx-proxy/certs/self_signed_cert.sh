#!/bin/sh

DOMAIN=jira.internal

openssl req -newkey rsa:4096 -sha256 -nodes \
 -keyout $DOMAIN.key -x509 -days 365 -out $DOMAIN.crt \
 -subj "/C=US/ST=New York/L=Brooklyn/O=Acme Corporation/OU=Moby Dock/CN=$DOMAIN"

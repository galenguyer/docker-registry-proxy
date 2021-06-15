FROM docker.io/galenguyer/nginx:latest

RUN apk add --no-cache apache2-utils
COPY scripts/add-user /usr/bin/add-user

COPY conf/nginx.conf /etc/nginx/nginx.conf

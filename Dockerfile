FROM ubuntu:latest

RUN curl -s https://packagecloud.io/install/repositories/varnishcache/varnish5/script.deb.sh | bash

RUN apt-get install -y varnish && \
    apt-get -y clean

ADD default.vcl /etc/varnish/default.vcl

ENV VARNISH_PORT 80
ENV VARNISH_CACHE_SIZE 64m
ENV VARNISHD_PARAMS -p default_ttl=3600 -p default_grace=3600

EXPOSE 80

ADD entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]

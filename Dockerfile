FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish5/script.deb.sh | bash && \
    apt-get install -y --no-install-recommends varnish && \
    apt-get remove -y curl && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

ADD default.vcl /etc/varnish/default.vcl

ENV VARNISH_PORT 80
ENV VARNISH_CACHE_SIZE 64m
ENV VARNISHD_PARAMS -p default_ttl=3600 -p default_grace=3600

EXPOSE 80

ADD entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]

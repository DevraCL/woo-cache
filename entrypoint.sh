#!/bin/bash

for name in VARNISH_BACKEND_PORT VARNISH_BACKEND_HOST
do
    eval value=\$$name
    sed -i "s|{${name}}|${value}|g" /etc/varnish/default.vcl
done

set -e

exec bash -c \
  "exec varnishd -F \
  -f /etc/varnish/default.vcl \
  -s malloc,$CACHE_SIZE \
  $VARNISHD_PARAMS \
  -a 0.0.0.0:${VARNISH_PORT}"


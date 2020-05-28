#!/bin/bash
set -e

exec tor -f /etc/tor/torrc

exec screen -S nginx -dm bash -c "/usr/sbin/nginx -c /etc/nginx/nginx.conf -g 'daemon off;'"
exec screen -S 3proxy -dm bash -c "3proxy"

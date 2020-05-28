#!/bin/bash

LOGDIR=/var/log/nginx

if [ $1 == "scrape" ]; then
	# scrape domain ex bash control.sh scrape
	grep -E -o "................\.onion" $LOGDIR/*.access_log | sort | uniq -u >> $LOGDIR/scrape.txt
elif [ $1 == "filter" ]; then
	# filter visitors by parameter from logs - ip, ua, host etc ex. bash control.sh filter "domain.onion|Mozilla|porn", disable 'private_addr' in nginx first if you plan filtering by ip, runs as 'daemon'
	if [[ -z $2 ]]; then
		echo "$2 missing, can contain regex"
		return 0;
	fi
	tail -f $LOGDIR/*.access_log | grep --line-buffered -E "$2" | awk "{print $1}" | uniq | while read LINE; do
		iptables -A INPUT -s $LINE -j DROP
	done
elif [ $1 == "sort" ]; then
	# sort-clean-reimport filtered ip addresses
	iptables -nL | awk "{print $4}" | sort | uniq -u > /tmp/ips.txt
	iptables -F # warning

	while read -r LINE; do
		iptables -A INPUT -s $LINE -j DROP
	done < /tmp/ips.txt

	rm -rf /tmp/ips.txt
else
	echo "$1 = scrape|filter|sort"
fi

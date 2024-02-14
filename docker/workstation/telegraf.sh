#!/usr/bin/env bash

cat <<AOF | tee /etc/yum.repos.d/influxdata.repo
[influxdata]
name = InfluxData Repository - Stable
baseurl = https://repos.influxdata.com/stable/\$basearch/main
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdata-archive_compat.key
AOF

yum install telegraf -y
if which telegraf &> /dev/null; then
  telegraf --config /tmp/telegraf.conf --test
  cp /tmp/telegraf.conf /etc/telegraf/telegraf.conf
  service telegraf start
else
  >&2 echo ":: telegraf was not successfully installed"
fi

#!/bin/bash
set -ex
script_name=$(basename $0 .sh)
echo "# $script_name inside testrunner container start"

cd /opt || exit 1
# extract config file
[ -f config.tar.gz ] || exit 1
mkdir config
sudo tar -zxvf config.tar.gz -C /opt/
sudo chown root. -R /opt/

# metricbeat
( cd /opt/beat-conf && tar cf - . ) | ( cd /metricbeat && sudo tar xvf - )
#
sync ; sync
echo "# $script_name inside testrunner container end"
exit

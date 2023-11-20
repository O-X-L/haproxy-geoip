#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

DB_MM_COUNTRY='/tmp/maxmind_country.mmdb'
DB_MM_ASN='/tmp/maxmind_asn.mmdb'
DB_II_COUNTRY='/tmp/ipinfo_country.mmdb'
DB_II_ASN='/tmp/ipinfo_asn.mmdb'

TEST_PROXY='http://localhost:6969'
TEST_HDR='TEST-SRC'
TEST_MM=1
TEST_II=1

echo ''

if ! [ -f "$DB_MM_COUNTRY" ] || ! [ -f "$DB_MM_ASN" ]
then
  echo 'WARN: UNABLE TO TEST MaxMind databases as they are missing!'
  echo ''
  TEST_MM=0
fi

if ! [ -f "$DB_II_COUNTRY" ] || ! [ -f "$DB_II_ASN" ]
then
  echo 'WARN: UNABLE TO TEST IPInfo databases as they are missing!'
  echo ''
  TEST_II=0
fi

if [[ "$TEST_MM" == "0" ]] && [[ "$TEST_II" == "0" ]]
then
  echo 'ERROR: NO GeoIP databases found - exiting'
  echo ''
  exit 1
fi

function last_log_haproxy {
  tail -n 1 '/tmp/haproxy_test.log' | cut -d '{' -f2 | cut -d '}' -f1
}

function last_log_haproxy_country() {
  last_log_haproxy | cut -d '|' -f 2
}

function last_log_haproxy_continent() {
  last_log_haproxy | cut -d '|' -f 3
}

function last_log_haproxy_asn() {
  last_log_haproxy | cut -d '|' -f 4
}

function last_log_haproxy_asname() {
  last_log_haproxy | cut -d '|' -f 5
}

function request_time() {
  testSrc="$1"
  reqTime="$(/usr/bin/time -f '%e' curl --silent "$TEST_PROXY" -H "${TEST_HDR}: ${testSrc}" 2>&1 > /dev/null)"
  echo "$reqTime"
}

touch '/tmp/haproxy_geoip_country.map'
touch '/tmp/haproxy_geoip_continent.map'
touch '/tmp/haproxy_geoip_asn.map'
touch '/tmp/haproxy_geoip_asname.map'
ln -sf "$(pwd)/../geoip_lookup.lua" '/tmp/haproxy_geoip_lookup.lua'

echo 'STARTING HAPROXY'
haproxy -W -f haproxy_test.cfg > '/tmp/haproxy_test.log' 2> '/tmp/haproxy_test_err.log' &
sleep 1
TEST_PROXY_PID="$(grep 'worker' < '/tmp/haproxy_test_err.log' | head -n 1 | cut -d '(' -f2 | cut -d ')' -f1)"
set +e

echo ''
echo 'TESTING BACKEND with Lookup-Util'
python3 "$(pwd)/../geoip_lookup_backend_shell.py" > '/tmp/haproxy_geoip_backend_shell.log' &
sleep 2

if [[ "$TEST_MM" == "1" ]]
then
  echo 'LINKING MaxMind databases'
  ln -sf "$DB_MM_COUNTRY" '/tmp/country.mmdb'
  ln -sf "$DB_MM_ASN" '/tmp/asn.mmdb'

  source ./test_requests.sh
fi

if [[ "$TEST_II" == "1" ]]
then
  echo 'LINKING IPInfo databases'
  ln -sf "$DB_II_COUNTRY" '/tmp/country.mmdb'
  ln -sf "$DB_II_ASN" '/tmp/asn.mmdb'

  source ./test_requests.sh
fi

kill "$(pgrep -f 'geoip_lookup_backend_shell.py')"
sleep 5

echo ''
echo 'TESTING BACKEND with Lookup-Lib'
python3 "$(pwd)/../geoip_lookup_backend_lib.py" > '/tmp/haproxy_geoip_backend_lib.log' &
sleep 2

if [[ "$TEST_MM" == "1" ]]
then
  echo 'LINKING MaxMind databases'
  ln -sf "$DB_MM_COUNTRY" '/tmp/country.mmdb'
  ln -sf "$DB_MM_ASN" '/tmp/asn.mmdb'

  source ./test_requests.sh
fi

if [[ "$TEST_II" == "1" ]]
then
  echo 'LINKING IPInfo databases'
  ln -sf "$DB_II_COUNTRY" '/tmp/country.mmdb'
  ln -sf "$DB_II_ASN" '/tmp/asn.mmdb'

  source ./test_requests.sh
fi

kill "$(pgrep -f 'geoip_lookup_backend_lib.py')"

echo ''
echo 'STOPPING HAPROXY'
pkill 'haproxy'
sleep 5

echo ''
echo 'FINISHED - exiting'
echo ''

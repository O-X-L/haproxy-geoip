#!/bin/bash

req1T1="$(request_time '1.1.1.1')"
if [[ "$(last_log_haproxy_country)" != "US" ]] || [[ "$(last_log_haproxy_continent)" != "NA" ]] || [[ "$(last_log_haproxy_asn)" != "AS1333" ]] || [[ "$(last_log_haproxy_asname)" != "Cloudflare, Inc." ]]
then
  echo "ERROR: REQUEST 1 - LOOKUP FAILED"
fi
req1T2="$(request_time '1.1.1.1')"
echo "REQUEST TIMES: ${req1T1} => ${req1T2} (cached)"
if (( "${req1T1: -1}" <= "${req1T2: -1}" ))
then
  echo "ERROR: REQUEST 1 - CACHE NOT HIT"
fi

/bin/kill -USR2 "$TEST_PROXY_PID"
sleep 1
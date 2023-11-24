# HAProxy - GeoIP Lookups

This is an example on how to use GeoIP lookups in combination with HAProxy.

Data linking requests to its origin country and ASN/ISP can be very useful when dealing with application-level attacks.

This allows you also to handle requests from specific countries and ASNs (p.e. datacenters/hosting providers) differently than others.

NOTE: This functionality is covered by the [HAProxy Enterprise Maxmind-Module](https://www.haproxy.com/documentation/hapee/latest/load-balancing/geolocation/maxmind/)! Only use this implementation if you are limited to the community edition.

## Topology

You can implement this in two ways:

* Use a custom backend to do this lookups
* UNTESTED: Use the [resty-maxminddb LUA library](https://raw.githubusercontent.com/anjia0532/lua-resty-maxminddb/master/lib/resty/maxminddb.lua) to query the MMDB databases directly from LUA

### Lookup via Backend

1. Request hits HAProxy

2. HAProxy calls LUA script to delegate GeoIP-database lookup

3. LUA calls a minimal web-service on localhost that queries the GeoIP-database(s)

   In this case we use a basic Python3 HTTP-Server

<img src="https://raw.githubusercontent.com/superstes/haproxy-geoip/latest/topology.svg" width=300>


Integration with [a Golang-based backend](https://github.com/superstes/geoip-lookup-service) will be added.

### Lookup via Library

1. Request hits HAProxy

2. HAProxy calls LUA script for querying the GeoIP-database(s)


----

## Setup

Change the `/tmp/` paths inside the `haproxy_example.cfg`


### Cache-Map

You will have to decide if you want to use [HAProxy Maps](https://www.haproxy.com/blog/introduction-to-haproxy-maps) to cache Lookup results.

This can speed-up the lookup for IPs that have already connected to your server.

It will also use more memory.

See also: `haproxy_example.cfg - test_country_cachemap`

The speed-improvements as seen by running the test-script are: `first: 0.03, second: 0.00`

By utilizing [HAProxy's ipmask](https://www.haproxy.com/blog/ip-masking-in-haproxy) (`src,ipmask(24,48)`) feature we are able to reduce the needed entries inside the map to the minimal subnets that are announced on public BGP.  

### GeoIP

You will have to download some MMDB GeoIP databases.

Per example from [ipinfo.io](https://ipinfo.io/account/data-downloads) or [maxmind](https://maxmind.com)!


### Lookup

#### via Backend

To query the MMDB databases, you will have to install the [maxminddb python-module](https://github.com/maxmind/MaxMind-DB-Reader-python):

```bash
python3 -m pip install maxminddb
```

You will have to update the paths to your database-files in the `backend/geoip_lookup_backend.py` file!

You need to use the `lua/geoip_lookup_w_backend.lua` script.

#### via Library

WARNING: UNTESTED

To query the MMDB databases, you will have to install the [resty-maxminddb LUA library](https://raw.githubusercontent.com/anjia0532/lua-resty-maxminddb/master/lib/resty/maxminddb.lua) and its dependencies.

You need to use the `lua/geoip_lookup_w_lib.lua` script.

----

## Run

### With LUA-Library

```bash
# initialize the haproxy map(s)
touch /tmp/haproxy_geoip_country.map
# start haproxy
haproxy -W -f haproxy_example.cfg
```

### With Lookup-Backend
```bash
# start the web-service
python3 backend/geoip_lookup.py &
# initialize the haproxy map(s)
touch /tmp/haproxy_geoip_country.map
# start haproxy
haproxy -W -f haproxy_example.cfg
```

----

## Testing

You will have to copy some GeoIP databases to `/tmp`:

* '/tmp/maxmind_country.mmdb'
* '/tmp/maxmind_asn.mmdb'
* '/tmp/ipinfo_country.mmdb'
* '/tmp/ipinfo_asn.mmdb'

At least IPInfo OR MaxMind databases need to exist!

```bash
cd test
bash test.sh
>
> CLEANUP
>
> WARN: UNABLE TO TEST MaxMind databases as they are missing!
>
> STARTING HAPROXY
>
> TESTING with PYTHON-BACKEND
> LINKING IPInfo databases
> 127.0.0.1 - - [22/Nov/2023 21:21:00] "GET /?lookup=country&ip=1.1.1.1 HTTP/1.1" 200 -
> 127.0.0.1 - - [22/Nov/2023 21:21:00] "GET /?lookup=continent&ip=1.1.1.1 HTTP/1.1" 200 -
> 127.0.0.1 - - [22/Nov/2023 21:21:00] "GET /?lookup=asn&ip=1.1.1.1 HTTP/1.1" 200 -
> 127.0.0.1 - - [22/Nov/2023 21:21:00] "GET /?lookup=asname&ip=1.1.1.1 HTTP/1.1" 200 -
> REQUEST TIMES: 0.01 => 0.00 (cached)
>
> STOPPING HAPROXY
>
> FINISHED - exiting
```

Feel free to [contribute more test-cases](https://github.com/superstes/haproxy-geoip/blob/latest/test/requests.sh)!

# HAProxy - GeoIP Lookups

This is an example on how to use GeoIP lookups in combination with HAProxy.

Data linking requests to its origin country and ASN/ISP can be very useful when dealing with application-level attacks.

This allows you also to handle requests from specific countries and ASNs (p.e. datacenters/hosting providers) differently than others.

## Topology

1. Request hits HAProxy

2. HAProxy calls LUA script to delegate GeoIP-database lookup

   I would prefer to use [io.popen](https://www.lua.org/manual/5.1/manual.html#pdf-io.popen) so LUA directly executes the query, but this [is blocked by HAProxy](https://discourse.haproxy.org/t/haproxy-1-8-update-to-2-7-3-lua-issues/8454)

3. LUA calls a minimal web-service on localhost that queries the GeoIP-database

   In this case we use a basic Python3 HTTP-Server

<img src="https://raw.githubusercontent.com/superstes/haproxy-geoip-lua/latest/topology.svg" width=300>

----

## Setup

Change the `/tmp/` paths inside the `haproxy_example.cfg`


### Cache-Map

You will have to decide if you want to use [HAProxy Maps](https://www.haproxy.com/blog/introduction-to-haproxy-maps) to cache Lookup results.

This can speed-up the lookup for IPs that have already connected to your server.

It will also use more memory.

See also: `haproxy_example.cfg - test_country_cachemap`

The speed-improvements as seen by running the test-script are: `first: 0.03, second: 0.00`

### GeoIP

You will have to download some MMDB GeoIP databases.

Per example from [ipinfo.io](https://ipinfo.io/account/data-downloads) or [maxmind](https://maxmind.com)!


### Lookup-Backend

This repository shows two different backend-implementations.

One calls a shell-util, the other one uses [a library](https://github.com/maxmind/MaxMind-DB-Reader-python).

#### Shell-Util

To query the MMDB databases, you will have to install the `mmdblookup` util:

```bash
apt install mmdb-bin
```

You will have to update the paths to your database-files in the `geoip_lookup_backend_shell.py` file!

#### Library

To query the MMDB databases, you will have to install the `maxminddb` python-module:

```bash
python3 -m pip install maxminddb
```

You will have to update the paths to your database-files in the `geoip_lookup_backend_lib.py` file!


----

## Run

```bash
# start the web-service
python3 geoip_lookup_backend.py &
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
> WARN: UNABLE TO TEST MaxMind databases as they are missing!
> 
> STARTING HAPROXY
> 
> TESTING BACKEND with Lookup-Util
> LINKING IPInfo databases
> 127.0.0.1 - - [20/Nov/2023 19:10:14] "GET /?lookup=country&ip=1.1.1.1 HTTP/1.1" 200 -
> 127.0.0.1 - - [20/Nov/2023 19:10:14] "GET /?lookup=continent&ip=1.1.1.1 HTTP/1.1" 200 -
> 127.0.0.1 - - [20/Nov/2023 19:10:14] "GET /?lookup=asn&ip=1.1.1.1 HTTP/1.1" 200 -
> 127.0.0.1 - - [20/Nov/2023 19:10:14] "GET /?lookup=asname&ip=1.1.1.1 HTTP/1.1" 200 -
> REQUEST TIMES: 0.03 => 0.00 (cached)
> 
> TESTING BACKEND with Lookup-Lib
> LINKING IPInfo databases
> 127.0.0.1 - - [20/Nov/2023 19:10:22] "GET /?lookup=country&ip=1.1.1.1 HTTP/1.1" 200 -
> 127.0.0.1 - - [20/Nov/2023 19:10:22] "GET /?lookup=continent&ip=1.1.1.1 HTTP/1.1" 200 -
> 127.0.0.1 - - [20/Nov/2023 19:10:22] "GET /?lookup=asn&ip=1.1.1.1 HTTP/1.1" 200 -
> 127.0.0.1 - - [20/Nov/2023 19:10:22] "GET /?lookup=asname&ip=1.1.1.1 HTTP/1.1" 200 -
> REQUEST TIMES: 0.03 => 0.00 (cached)
>
> STOPPING HAPROXY
>
> FINISHED - exiting
```

Feel free to [contribute more test-cases](https://github.com/superstes/haproxy-geoip-lua/blob/latest/test/test_requests.sh)!

# HAProxy - GeoIP Lookups

This is an example on how to use GeoIP lookups in combination with HAProxy.

## Topology

1. Request hits HAProxy

2. HAProxy calls LUA script to delegate GeoIP-database lookup

   I would prefer to use [io.popen](https://www.lua.org/manual/5.1/manual.html#pdf-io.popen) so LUA directly executes the query, but this [is blocked by HAProxy](https://discourse.haproxy.org/t/haproxy-1-8-update-to-2-7-3-lua-issues/8454)

3. LUA calls a minimal web-service on localhost that queries the GeoIP-database

   In this case we use a basic Python3 HTTP-Server

----

## Setup

Change the `/tmp/` paths inside the `haproxy_example.cfg`


### Cache-Map

You will have to decide if you want to use [HAProxy Maps](https://www.haproxy.com/blog/introduction-to-haproxy-maps) to cache Lookup results.

This can speed-up the lookup for IPs that have already connected to your server.

It will also use more memory.

See also: `haproxy_example.cfg - test_country_cachemap`


### GeoIP

You will have to download some MMDB GeoIP databases.

Per example from [ipinfo.io](https://ipinfo.io/account/data-downloads) or [maxmind](https://maxmind.com)!

To query the MMDB databases, you will have to install the `mmdblookup` util:

```bash
apt install mmdb-bin
```

You will have to update the paths to your database-files in the `lookup_geoip_backend.py` file!

----

## Run

```bash
# start the web-service
python3 lookup_geoip_backend.py &
# initialize the haproxy map(s)
touch /tmp/haproxy_geoip_country.map
# start haproxy
haproxy -W -f haproxy_example.cfg
```

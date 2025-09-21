#!/usr/bin/python3

# Source: https://github.com/O-X-L/haproxy-geoip
# Copyright (C) 2025 Rath Pascal (contact+geoip@oxl.at)
# License: MIT

# requirements: pip install maxminddb

from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse

from maxminddb import open_database

PORT = 6970

# for data schema see:
#   ipinfo: https://github.com/ipinfo/sample-database
#   maxmind: https://github.com/maxmind/MaxMind-DB/tree/main/source-data

# ipinfo - https://ipinfo.io/dashboard/downloads
DATABASES = {
    'lite': {
        'file': '/tmp/ipinfo_lite.mmdb', 'fallback_selector': 'country_code', 'fallback': '-',
    },
    'core': {
        'file': '/tmp/ipinfo_core.mmdb', 'fallback_selector': 'city', 'fallback': '-',
    },
}

LOOKUPS = {
    'asn': DATABASES['lite'],
    'as_name': DATABASES['lite'],
    'as_domain': DATABASES['lite'],
    'country_code': DATABASES['lite'],
    'country': DATABASES['lite'],
    'continent_code': DATABASES['lite'],
    'continent': DATABASES['lite'],
    'geo.city': DATABASES['core'],
    'geo.region': DATABASES['core'],
    'geo.country': DATABASES['core'],
    'geo.country_code': DATABASES['core'],
    'geo.continent': DATABASES['core'],
    'geo.continent_code': DATABASES['core'],
    'geo.latitude': DATABASES['core'],
    'geo.longitude': DATABASES['core'],
    'geo.timezone': DATABASES['core'],
    'geo.postal_code': DATABASES['core'],
    'as.asn': DATABASES['core'],
    'as.name': DATABASES['core'],
    'as.domain': DATABASES['core'],
    'as.type': DATABASES['core'],
    'is_anonymous': DATABASES['core'],
    'is_anycast': DATABASES['core'],
    'is_mobile': DATABASES['core'],
    'is_satellite': DATABASES['core'],
    'hostname': DATABASES['core'],
}

# maxmind
# DATABASES = {
#     'lite_country': {'file': '/tmp/maxmind_lite_country.mmdb', 'attr': 'country.iso_code', 'fallback': '-'},
#     'lite_city': {'file': '/tmp/maxmind_lite_city.mmdb', 'attr': 'city.names.en', 'fallback': '-'},
#     'lite_asn': {'file': '/tmp/maxmind_lite_asn.mmdb', 'attr': 'autonomous_system_number', 'fallback': '0'},
# }
#
# LOOKUPS = {
#     'country.iso_code': DATABASES['lite_country'],
#     'continent.code': DATABASES['lite_country'],
#     'city.names.en': DATABASES['lite_city'],
#     'autonomous_system_number': DATABASES['lite_asn'],
#     'autonomous_system_organization': DATABASES['lite_asn'],
# }


def _lookup_mmdb(lookup: str, ip: str) -> str:
    db = LOOKUPS[lookup]
    try:
        if not Path(db['file']).is_file():
            return db['fallback']

        with open_database(db['file']) as db_reader:
            data = db_reader.get(ip)
            for attr in lookup.split('.'):
                if attr in data:
                    data = data[attr]

                else:
                    return db['fallback']

            return data

    except (RuntimeError, KeyError):
        return db['fallback']


def _ensure_str(data: (str, list)) -> str:
    if isinstance(data, list):
        if len(data) > 0:
            return data[0]

        return ''

    return data


class WebRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        q = parse_qs(urlparse(self.path).query)

        if 'ip' not in q:
            self.send_response(400)
            self.end_headers()
            self.wfile.write('No IP provided'.encode('utf-8'))

        ip = _ensure_str(q['ip'])

        if 'lookup' not in q or _ensure_str(q['lookup']) not in LOOKUPS:
            self.send_response(400)
            self.end_headers()
            self.wfile.write('Got unsupported lookup'.encode('utf-8'))

        lookup = _ensure_str(q['lookup'])

        data = _lookup_mmdb(lookup, ip)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(data.encode('utf-8'))
        print(f" > {ip} {lookup} => {data}")


if __name__ == '__main__':
    server = HTTPServer(('127.0.0.1', PORT), WebRequestHandler)
    server.serve_forever()

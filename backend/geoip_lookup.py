#!/usr/bin/python3

# Source: https://github.com/O-X-L/haproxy-geoip
# Copyright (C) 2024 Rath Pascal
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
        'selectors': [
            'asn', 'as_name', 'as_domain', 'country_code', 'country',
            'continent_code', 'continent',
        ],
    },
    'core': {
        'file': '/tmp/ipinfo_core.mmdb', 'fallback_selector': 'city', 'fallback': '-',
        'selectors': [
            'geo.city', 'geo.region', 'geo.country', 'geo.country_code', 'geo.continent', 'geo.continent_code',
            'geo.latitude', 'geo.longitude', 'geo.timezone', 'geo.postal_code',
            'as.asn', 'as.name', 'as.domain', 'as.type',
            'is_anonymous', 'is_anycast', 'is_mobile', 'is_satellite', 'hostname',
        ],
    },
}
DATABASES['asn'] = DATABASES['lite']
DATABASES['country'] = DATABASES['lite']
DATABASES['continent'] = DATABASES['lite']
DATABASES['city'] = DATABASES['core']

# maxmind
# DATABASES = {
#     'country': {'file': '/tmp/country.mmdb', 'attr': 'country.iso_code', 'fallback': '00'},
#     'continent': {'file': '/tmp/country.mmdb', 'attr': 'continent.code', 'fallback': '00'},
#     'city': {'file': '/tmp/city.mmdb', 'attr': 'city.names.en', 'fallback': '-'},
#     'asn': {'file': '/tmp/asn.mmdb', 'attr': 'autonomous_system_number', 'fallback': '0'},
#     'asname': {'file': '/tmp/asn.mmdb', 'attr': 'autonomous_system_organization', 'fallback': '-'},
# }


def _lookup_mmdb(db: dict, selector: str, ip: str) -> str:
    try:
        if not Path(db['file']).is_file():
            return db['fallback']

        with open_database(db['file']) as db_reader:
            data = db_reader.get(ip)
            for attr in selector.split('.'):
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

        if 'lookup' not in q or _ensure_str(q['lookup']) not in DATABASES:
            self.send_response(400)
            self.end_headers()
            self.wfile.write('Got unsupported lookup'.encode('utf-8'))

        lookup = _ensure_str(q['lookup'])
        selector = DATABASES[lookup]['fallback_selector']

        if 'filter' in q:
            if _ensure_str(q['filter']) not in DATABASES[lookup]['selectors']:
                self.send_response(400)
                self.end_headers()
                self.wfile.write('Got unsupported filter/selector'.encode('utf-8'))

            else:
                selector = _ensure_str(q['filter'])

        data = _lookup_mmdb(DATABASES[lookup], selector, ip)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(data.encode('utf-8'))
        print(f" > {ip} {lookup} => {data}")


if __name__ == '__main__':
    server = HTTPServer(('127.0.0.1', PORT), WebRequestHandler)
    server.serve_forever()

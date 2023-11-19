#!/usr/bin/python3

import subprocess
from pathlib import Path
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse

PORT = 6970

# https://ipinfo.io/account/data-downloads
DATABASES = {
    'country': {'file': '/tmp/country.mmdb', 'attr': 'country', 'fallback': '00'},
    'continent': {'file': '/tmp/country.mmdb', 'attr': 'continent', 'fallback': '00'},
    'asn': {'file': '/tmp/asn.mmdb', 'attr': 'asn', 'fallback': '0'},
    'asn_name': {'file': '/tmp/asn.mmdb', 'attr': 'name', 'fallback': '-'},
}


def _lookup_mmdb(db: dict, ip: str) -> str:
    if not Path(db['file']).is_file():
        return db['fallback']

    try:
        with subprocess.Popen(
            ['mmdblookup', '-f', db['file'], '-i', ip, db['attr']],
            shell=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ) as p:
            b_stdout, _ = p.communicate(timeout=2)
            stdout_raw = b_stdout.decode('utf-8').strip()
            if stdout_raw.find('"') != -1:
                return stdout_raw.split('"')[1]  # "US" <utf8_string>

            if stdout_raw == '':
                return db['fallback']

            return stdout_raw

    except (subprocess.TimeoutExpired, subprocess.SubprocessError, subprocess.CalledProcessError,
            OSError, IOError):
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

        if 'lookup' not in q or _ensure_str(q['lookup']) not in DATABASES:
            self.send_response(400)
            self.end_headers()
            self.wfile.write('Got unsupported lookup'.encode("utf-8"))

        if 'ip' not in q:
            self.send_response(400)
            self.end_headers()
            self.wfile.write('No IP provided'.encode("utf-8"))

        lookup = _ensure_str(q['lookup'])
        ip = _ensure_str(q['ip'])
        data = _lookup_mmdb(DATABASES[lookup], ip)
        print(f"{lookup} | {ip} => {data}")
        self.send_response(200)
        self.end_headers()
        self.wfile.write(data.encode("utf-8"))


if __name__ == "__main__":
    server = HTTPServer(('127.0.0.1', PORT), WebRequestHandler)
    server.serve_forever()

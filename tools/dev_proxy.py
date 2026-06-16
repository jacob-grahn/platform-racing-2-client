#!/usr/bin/env python3
"""Local dev server for the OpenFL html5 build.

Serves the static build *and* proxies `/api/*` to the live PR2 server. Because
the proxied requests come back through this same origin, the browser sees
same-origin responses and the missing CORS headers on pr2hub.com stop being a
problem.

Usage:

    python3 tools/dev_proxy.py            # serves export/html5/bin on :8000
    python3 tools/dev_proxy.py --port 9000 --dir export/html5/bin

Then open, for example:

    http://localhost:8000/?screen=campaign&apiHost=/api

The client builds level URLs on `apiHost`, so `/api/files/lists/campaign/1`
is forwarded to `https://pr2hub.com/files/lists/campaign/1`.
"""

import argparse
import http.server
import os
import ssl
import urllib.error
import urllib.request

UPSTREAM = "https://pr2hub.com"
API_PREFIX = "/api"
# pr2hub.com may reject requests without a browser-ish User-Agent.
USER_AGENT = "Mozilla/5.0 (pr2-haxe-dev-proxy)"


def build_ssl_context():
    """Prefer certifi's CA bundle. The python.org macOS builds often ship with
    no usable system CA store, which otherwise fails cert verification."""
    try:
        import certifi

        return ssl.create_default_context(cafile=certifi.where())
    except ImportError:
        return ssl.create_default_context()


SSL_CONTEXT = build_ssl_context()


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == API_PREFIX or self.path.startswith(API_PREFIX + "/"):
            self.proxy("GET")
        else:
            super().do_GET()

    def do_POST(self):
        if self.path == API_PREFIX or self.path.startswith(API_PREFIX + "/"):
            self.proxy("POST")
        else:
            self.send_error(404)

    def proxy(self, method):
        upstream_url = UPSTREAM + self.path[len(API_PREFIX):]
        body = None
        headers = {"User-Agent": USER_AGENT}
        if method == "POST":
            length = int(self.headers.get("Content-Length", "0"))
            body = self.rfile.read(length)
            content_type = self.headers.get("Content-Type")
            if content_type:
                headers["Content-Type"] = content_type
        request = urllib.request.Request(upstream_url, data=body, headers=headers, method=method)
        try:
            with urllib.request.urlopen(request, timeout=20, context=SSL_CONTEXT) as response:
                body = response.read()
                status = response.status
                content_type = response.headers.get("Content-Type", "text/plain")
        except urllib.error.HTTPError as error:
            body = error.read()
            status = error.code
            content_type = error.headers.get("Content-Type", "text/plain")
        except Exception as error:  # noqa: BLE001 - surface any proxy failure to the client
            body = f"dev proxy error fetching {upstream_url}: {error}".encode("utf-8")
            status = 502
            content_type = "text/plain"

        self.log_message("proxy %s %s -> %s [%s]", method, self.path, upstream_url, status)
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--dir", default="export/html5/bin", help="static build directory to serve")
    args = parser.parse_args()

    directory = os.path.abspath(args.dir)
    if not os.path.isdir(directory):
        parser.error(f"build directory not found: {directory} (run `haxelib run openfl build html5` first)")

    handler = lambda *handler_args, **handler_kwargs: Handler(*handler_args, directory=directory, **handler_kwargs)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    print(f"serving {directory} on http://localhost:{args.port}")
    print(f"proxying {API_PREFIX}/* -> {UPSTREAM}/*")
    print(f"open http://localhost:{args.port}/?screen=campaign&apiHost={API_PREFIX}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nshutting down")
        server.shutdown()


if __name__ == "__main__":
    main()

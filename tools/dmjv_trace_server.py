#!/usr/bin/env python3
"""Capture Flash DMJV PR2TRACE lines sent over a localhost AS3 Socket."""

import argparse
import os
import socketserver
import sys
import threading


POLICY_RESPONSE = (
    '<?xml version="1.0"?>'
    '<!DOCTYPE cross-domain-policy SYSTEM "http://www.adobe.com/xml/dtds/cross-domain-policy.dtd">'
    '<cross-domain-policy>'
    '<allow-access-from domain="*" to-ports="9451" />'
    '</cross-domain-policy>\0'
).encode("utf-8")


class TraceHandler(socketserver.BaseRequestHandler):
    def handle(self):
        pending = b""
        while True:
            chunk = self.request.recv(65536)
            if not chunk:
                break
            pending += chunk
            if b"<policy-file-request/>" in pending:
                self.request.sendall(POLICY_RESPONSE)
                return
            while b"\n" in pending:
                line, pending = pending.split(b"\n", 1)
                self.server.write_line(line)
        if pending.strip():
            self.server.write_line(pending)


class TraceServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True

    def __init__(self, address, output_path):
        super().__init__(address, TraceHandler)
        self.output_path = output_path
        os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
        self.output = open(output_path, "w", encoding="utf-8", buffering=1)
        self.lock = threading.Lock()
        self.line_count = 0

    def write_line(self, raw_line):
        text = raw_line.decode("utf-8", errors="replace").strip()
        if not text:
            return
        with self.lock:
            self.output.write(text)
            self.output.write("\n")
            self.line_count += 1

    def server_close(self):
        try:
            if hasattr(self, "output"):
                self.output.close()
        finally:
            super().server_close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=9451)
    parser.add_argument("--out", default="test/output/dmjv-flash/physics.log")
    args = parser.parse_args()

    with TraceServer((args.host, args.port), args.out) as server:
        print(f"Trace server listening on {args.host}:{args.port}, writing {args.out}", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            print(f"Trace server stopped after {server.line_count} lines", file=sys.stderr, flush=True)


if __name__ == "__main__":
    main()

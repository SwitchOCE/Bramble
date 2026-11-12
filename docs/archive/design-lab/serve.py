"""Serve the design lab locally with caching turned off.

Python's plain http.server sends no cache headers, so browsers guess and keep old
copies of CSS and JS. After an update that mixes new code with old styles, which
breaks layouts and hover states. This server tells the browser never to cache.

Usage: python serve.py [port]   (default 8771; serves this folder on 127.0.0.1)
"""
import functools
import http.server
import os
import sys


class NoCache(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, must-revalidate')
        self.send_header('Expires', '0')
        super().end_headers()

    def log_message(self, fmt, *args):  # keep the console quiet
        pass


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8771
    root = os.path.dirname(os.path.abspath(__file__))
    handler = functools.partial(NoCache, directory=root)
    with http.server.ThreadingHTTPServer(('127.0.0.1', port), handler) as httpd:
        print(f'design lab on http://127.0.0.1:{port}/ (no caching)', flush=True)
        httpd.serve_forever()


if __name__ == '__main__':
    main()

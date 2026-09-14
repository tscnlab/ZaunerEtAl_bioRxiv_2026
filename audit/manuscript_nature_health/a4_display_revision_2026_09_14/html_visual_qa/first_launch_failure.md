# Initial sandbox bind restriction

The first ordinary sandbox launch of `serve_frozen.py` reached its symlink-checked one-file temporary root, then failed at `ThreadingHTTPServer(('127.0.0.1',0),Handler)` with `PermissionError: [Errno 1] Operation not permitted`. No server listener or browser session was created. The command exited with status 1.

The same exact-file root is retained for the standard execution-permission request. No alternate browser, profile change, proxy, external tunnel or different server behavior is used. If that request is rejected, browser QA stops.

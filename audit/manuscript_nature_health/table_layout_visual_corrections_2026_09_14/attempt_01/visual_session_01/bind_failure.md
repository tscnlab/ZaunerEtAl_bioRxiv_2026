# Ordinary sandbox bind restriction

The first server start completed its source and symlink preflight, then the
default shell sandbox rejected binding the local socket with PermissionError
(operation not permitted). No browser navigation occurred and no server was
started. The next start uses the normal explicit shell approval mechanism for
the same six-route, read-only 127.0.0.1 server. This is not a browser rejection
and does not change a browser security setting.

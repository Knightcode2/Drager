"""Instant hand-off: if DragShift is already running, pass files to it and exit *before*
importing Qt. Right-click → DragShift / Send To then opens the menu in milliseconds."""
from __future__ import annotations

import json
import os
import sys


def ipc_name() -> str:
    return "DragShift-" + (os.environ.get("USERNAME") or os.environ.get("USER") or "user")


def try_handoff(argv: list[str]) -> bool:
    if "--selftest" in argv:
        return False
    files = [os.path.abspath(a) for a in argv[1:] if not a.startswith("-") and os.path.exists(a)]
    payload = {"files": files} if files else {"show": "--quiet" not in argv}
    data = json.dumps(payload).encode("utf-8")
    try:
        path = "\\\\.\\pipe\\" + ipc_name()       # QLocalServer's named pipe: \\.\pipe\<name>
        with open(path, "wb", buffering=0) as f:
            f.write(data)
            import time
            time.sleep(0.15)  # let the running copy read before the pipe closes
        return True
    except OSError:
        return False

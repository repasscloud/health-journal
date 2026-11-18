#!/usr/bin/env bash
set -euo pipefail

# Run from the project root, even when invoked from another directory.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

for tool in flutter python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Required tool missing from PATH: %s\n' "$tool" >&2
    exit 1
  fi
done

# Build the fictional web demo and serve it only on this machine.
flutter build web --release
interactive=0
if [[ -t 0 ]]; then
  interactive=1
fi

# Prefer the usual URL. Replace only a verified preview from this checkout.
python3 - health-journal-web-preview "$interactive" <<'PYTHON' &
import errno
import os
import re
import signal
import subprocess
import sys
import time
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

host = "127.0.0.1"
preferred_port = 8765
handler = partial(SimpleHTTPRequestHandler, directory="build/web")

def process_output(*command):
    try:
        return subprocess.run(
            command, capture_output=True, text=True, timeout=2, check=True
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def stop_previous_preview():
    listeners = process_output(
        "lsof", "-a", "-nP", "-t", f"-iTCP@{host}:{preferred_port}", "-sTCP:LISTEN"
    ).split()
    for pid in set(listeners):
        # Check ownership, working directory and the exact preview invocation.
        # Also recognise the previous script's plain python http.server command.
        cwd = process_output("lsof", "-a", "-p", pid, "-d", "cwd", "-Fn").splitlines()
        if f"n{os.getcwd()}" not in cwd:
            continue
        process = process_output("ps", "-ww", "-p", pid, "-o", "uid=,command=").strip()
        uid, _, command = process.partition(" ")
        interpreter, _, args = command.strip().partition(" ")
        if uid != str(os.getuid()) or not re.fullmatch(
            r"python(?:3(?:[.]\d+)?)?", Path(interpreter).name, re.IGNORECASE
        ):
            continue
        legacy = f"-m http.server {preferred_port} --bind {host} --directory "
        if args not in {
            "- health-journal-web-preview 0",
            "- health-journal-web-preview 1",
            legacy + "build/web",
            legacy + str(Path.cwd() / "build/web"),
        }:
            continue
        try:
            os.kill(int(pid), signal.SIGTERM)
        except ProcessLookupError:
            pass
        except PermissionError:
            return False
        print(f"Replacing the previous Health Journal preview on port {preferred_port}.", flush=True)
        return True
    return False


def open_server():
    try:
        return ThreadingHTTPServer((host, preferred_port), handler)
    except OSError as error:
        if error.errno != errno.EADDRINUSE:
            raise

    if stop_previous_preview():
        # Give the previous server a moment to release its listening socket.
        for _ in range(20):
            time.sleep(0.1)
            try:
                return ThreadingHTTPServer((host, preferred_port), handler)
            except OSError as error:
                if error.errno != errno.EADDRINUSE:
                    raise

    server = ThreadingHTTPServer((host, 0), handler)
    print(f"Port {preferred_port} is in use. Using an available port.", flush=True)
    return server


try:
    server = open_server()
except OSError as error:
    sys.exit(f"Could not start the web server: {error}")

with server:
    print(f"\nHealth Journal demo: http://{host}:{server.server_port}/", flush=True)
    if sys.argv[2] == "1":
        print("Press c to stop the server (no Enter needed), or use Ctrl+C.", flush=True)
    server.serve_forever()
PYTHON
server_pid=$!

# Stop and reap only this invocation's server, including on Ctrl+C or SIGTERM.
stop_server() {
  if [[ -n "${terminal_state:-}" ]]; then
    stty "$terminal_state" || true
  fi
  if kill "$server_pid" 2>/dev/null; then
    wait "$server_pid" 2>/dev/null || true
  fi
}
trap stop_server EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ "$interactive" == 1 ]]; then
  # Keep single-key input enabled between timed reads.
  terminal_state=$(stty -g)
  stty -icanon -echo min 1 time 0
  # Check for server exit between reads so startup errors surface promptly.
  while kill -0 "$server_pid" 2>/dev/null; do
    if IFS= read -r -n 1 -t 1 key && [[ "$key" == [cC] ]]; then
      printf '\nStopping the web server.\n'
      exit 0
    fi
  done
fi

# With redirected input, simply wait. Preserve the server's failure status.
wait "$server_pid"

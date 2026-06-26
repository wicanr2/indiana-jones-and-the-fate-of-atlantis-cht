#!/usr/bin/env bash
# Portable launcher: use the bundled libs + the bundled game data dir.
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -d "$HERE/lib" ] && export LD_LIBRARY_PATH="$HERE/lib:${LD_LIBRARY_PATH:-}"
exec "$HERE/bin/scummvm" -p "$HERE/data" --auto-detect "$@"

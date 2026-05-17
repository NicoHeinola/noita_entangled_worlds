#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env"
fi

for cmd in cargo rustup python3 i686-w64-mingw32-gcc zip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing required command: $cmd" >&2
        echo "Install it first, then rerun this script." >&2
        exit 1
    fi
done

rustup target add i686-pc-windows-gnu >/dev/null

cargo build -p ewext --release --target i686-pc-windows-gnu
cp target/i686-pc-windows-gnu/release/ewext.dll quant.ew/ewext.dll
version="$(python3 scripts/ci_version.py | awk '/^Version:/ { print $2 }')"
# printf 'return "%s"\n' "$version" > quant.ew/files/version.lua
python3 scripts/ci_make_archives.py mod

echo "Built DLL: $repo_root/target/i686-pc-windows-gnu/release/ewext.dll"
echo "Updated mod folder: $repo_root/quant.ew"
echo "Updated mod version: $version"

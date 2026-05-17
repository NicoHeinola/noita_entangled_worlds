#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

target="i686-pc-windows-gnu"

if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env"
fi

for cmd in cargo rustup python3 zip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing required command: $cmd" >&2
        echo "Install it first, then rerun this script." >&2
        exit 1
    fi
done

ensure_mingw_i686() {
    if command -v i686-w64-mingw32-gcc >/dev/null 2>&1; then
        return 0
    fi

    if ! command -v apt-get >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1; then
        echo "Missing i686 MinGW tools and automatic installation is unavailable on this system." >&2
        echo "Install i686-w64-mingw32-gcc, then rerun this script." >&2
        exit 1
    fi

    echo "Installing MinGW i686 toolchain with sudo..."
    sudo apt-get update
    sudo apt-get install -y gcc-mingw-w64-i686
}

ensure_mingw_i686

rustup toolchain install nightly --profile minimal >/dev/null
rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu >/dev/null
rustup target add "$target" --toolchain nightly >/dev/null

cargo +nightly build \
    --manifest-path ewext/Cargo.toml \
    --release \
    --target "$target" \
    -Zbuild-std="panic_abort,std"

cp "$repo_root/ewext/target/$target/release/ewext.dll" "$repo_root/quant.ew/ewext.dll"
version="$(python3 scripts/ci_version.py | awk '/^Version:/ { print $2 }')"
printf 'return "%s"\n' "$version" > "$repo_root/quant.ew/files/version.lua"
python3 scripts/ci_make_archives.py mod

echo "Built DLL: $repo_root/ewext/target/$target/release/ewext.dll"
echo "Updated mod folder: $repo_root/quant.ew"
echo "Updated mod version: $version"
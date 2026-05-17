#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

target="x86_64-pc-windows-gnu"

if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env"
fi

for cmd in cargo rustup; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing required command: $cmd" >&2
        echo "Install it first, then rerun this script." >&2
        exit 1
    fi
done

ensure_mingw_x86_64() {
    if command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1 && command -v x86_64-w64-mingw32-windres >/dev/null 2>&1; then
        return 0
    fi

    if ! command -v apt-get >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1; then
        echo "Missing x86_64 MinGW tools and automatic installation is unavailable on this system." >&2
        echo "Install x86_64-w64-mingw32-gcc and x86_64-w64-mingw32-windres, then rerun this script." >&2
        exit 1
    fi

    echo "Installing MinGW x86_64 toolchain with sudo..."
    sudo apt-get update
    sudo apt-get install -y binutils-mingw-w64-x86-64 gcc-mingw-w64-x86-64
}

ensure_mingw_x86_64

rustup target add "$target" >/dev/null

export CC_x86_64_pc_windows_gnu=x86_64-w64-mingw32-gcc
export CXX_x86_64_pc_windows_gnu=x86_64-w64-mingw32-g++
export AR_x86_64_pc_windows_gnu=x86_64-w64-mingw32-ar
export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER=x86_64-w64-mingw32-gcc
export WINDRES=x86_64-w64-mingw32-windres

cargo build --manifest-path noita-proxy/Cargo.toml --release --target "$target"

output_dir="$repo_root/noita-proxy/target/$target/release"
if [[ -f "$repo_root/redist/steam_api64.dll" ]]; then
    cp "$repo_root/redist/steam_api64.dll" "$output_dir/steam_api64.dll"
fi

echo "Built EXE: $output_dir/noita-proxy.exe"
if [[ -f "$output_dir/steam_api64.dll" ]]; then
    echo "Copied runtime DLL: $output_dir/steam_api64.dll"
fi
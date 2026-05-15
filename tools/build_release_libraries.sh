#!/usr/bin/env bash
set -euo pipefail

export ZIG_GLOBAL_CACHE_DIR="${ZIG_GLOBAL_CACHE_DIR:-$PWD/.zig-cache/global}"
export ZIG_LOCAL_CACHE_DIR="${ZIG_LOCAL_CACHE_DIR:-$PWD/.zig-cache/local}"
mkdir -p "$ZIG_GLOBAL_CACHE_DIR" "$ZIG_LOCAL_CACHE_DIR"

cargo build --release
cargo zigbuild --release --target x86_64-pc-windows-gnu
cargo zigbuild --release --target x86_64-unknown-linux-gnu

cp target/x86_64-pc-windows-gnu/release/dream_coastline.dll target/release/dream_coastline.dll
cp target/x86_64-unknown-linux-gnu/release/libdream_coastline.so target/release/libdream_coastline.so

ls -lh \
  target/release/libdream_coastline.dylib \
  target/release/dream_coastline.dll \
  target/release/libdream_coastline.so

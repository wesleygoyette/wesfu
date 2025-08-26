#!/bin/bash
# Build script for Windows client (cross-compilation from macOS/Linux)

set -e

echo "Building client for Windows target (x86_64-pc-windows-gnu)..."

# Ensure Rust target is installed
echo "Checking for Rust Windows target..."
cargo target list | grep -q "x86_64-pc-windows-gnu" || rustup target add x86_64-pc-windows-gnu

# Build the client for Windows
echo "Running cargo build for Windows..."
cargo build --release --target x86_64-pc-windows-gnu --manifest-path client/Cargo.toml

# Output location
echo "Windows build output: target/x86_64-pc-windows-gnu/release/client.exe"

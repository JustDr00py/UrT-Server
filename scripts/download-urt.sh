#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Urban Terror 4.3 – Server Files Downloader
#
# Downloads the official Urban Terror 4.3.4 Linux dedicated server files
# and unpacks them into ./urt-game/ so Docker can mount them.
#
# Usage:  bash scripts/download-urt.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEST="${PROJECT_DIR}/urt-game"

URT_VERSION="4.3.4"

echo "=================================================="
echo " Urban Terror ${URT_VERSION} Server Downloader"
echo "=================================================="
echo ""
echo "Destination: ${DEST}"
echo ""

# ── Dependency checks ─────────────────────────────────────────────────────────
for cmd in wget unzip; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: '${cmd}' is required but not installed."
        exit 1
    fi
done

# ── Download ──────────────────────────────────────────────────────────────────
# Urban Terror distributes the server as part of its full release.
# Visit https://www.urbanterror.info/downloads/ to get the current direct link.
# Paste the Linux dedicated server URL below when you have it:

echo "Please download Urban Terror ${URT_VERSION} Linux dedicated server from:"
echo "  https://www.urbanterror.info/downloads/"
echo ""
echo "Then extract the contents so the structure looks like:"
echo "  ${DEST}/"
echo "  ├── Quake3-UrT-Ded.x86_64   (or .i386)"
echo "  ├── q3ut4/"
echo "  │   ├── pak0.pk3"
echo "  │   ├── zUrT43_001.pk3"
echo "  │   └── ... (other pk3 files)"
echo "  └── baseq3/"
echo ""
echo "If you have a direct download URL, set URT_DOWNLOAD_URL and re-run:"
echo "  URT_DOWNLOAD_URL='https://...' bash scripts/download-urt.sh"
echo ""

# ── Auto-download if URL provided ────────────────────────────────────────────
if [[ -n "${URT_DOWNLOAD_URL:-}" ]]; then
    ARCHIVE="/tmp/urt-server.zip"

    echo "Downloading from: ${URT_DOWNLOAD_URL}"
    wget -O "$ARCHIVE" "${URT_DOWNLOAD_URL}"

    echo "Extracting to ${DEST}..."
    mkdir -p "${DEST}"
    unzip -o "$ARCHIVE" -d "${DEST}"
    rm -f "$ARCHIVE"

    # Make binary executable
    find "${DEST}" -name "Quake3-UrT-Ded*" -exec chmod +x {} \;
    find "${DEST}" -name "ioq3urt*"         -exec chmod +x {} \;

    echo ""
    echo "Done! Files are in: ${DEST}"
    echo "Run 'docker compose up --build' to start the server."
else
    echo "When ready, run:"
    echo "  docker compose up --build"
fi

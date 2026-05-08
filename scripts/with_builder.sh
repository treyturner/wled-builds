#!/usr/bin/env bash
set -euo pipefail

PUID="${PUID:-$(id -u)}"
PGID="${PGID:-$(id -g)}"

# Build repo root (contains scripts/ and platformio_override.ini)
REPO_ROOT="$PWD"

if [[ -f "$REPO_ROOT/.env.local" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$REPO_ROOT/.env.local"
  set +a
fi

# WLED_DIR is assumed to be a relative path under the repo root.
WLED_DIR="${WLED_DIR:-WLED}"
SOURCE_DIR="$REPO_ROOT/$WLED_DIR"

if [[ ! -f "$SOURCE_DIR/platformio.ini" ]]; then
  echo "ERROR: platformio.ini not found in: $SOURCE_DIR"
  echo "Run scripts/with_builder.sh from the build repo root containing $WLED_DIR/."
  exit 2
fi

docker run --rm \
  $([ -t 0 ] && echo -t) $([[ "$-" =~ i ]] && echo -i) \
  --pull always \
  -e PUID="$PUID" \
  -e PGID="$PGID" \
  -e UMASK="${UMASK:-002}" \
  -e FLASH_MODE \
  -e FLASH_SIZE \
  -e GIT_REF \
  -e IOT_SSID \
  -e OUT_DIR \
  -e WLED_DIR \
  -e WPA_KEY \
  -e PLATFORMIO_NO_ANSI \
  -e PLATFORMIO_DISABLE_PROGRESSBAR \
  -e PLATFORMIO_CORE_DIR=/work/.platformio \
  -e NPM_CONFIG_CACHE=/work/.npm \
  -v "$REPO_ROOT:/work" \
  -w "/work/$WLED_DIR" \
  ghcr.io/treyturner/platformio-builder \
  "$@"

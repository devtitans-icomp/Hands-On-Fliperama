#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AOSP_ROOT="$(cd "$REPO_DIR/../.." && pwd)"
LOCAL_MANIFESTS_DIR="$AOSP_ROOT/.repo/local_manifests"

if [ ! -d "$AOSP_ROOT/.repo" ]; then
  echo "[ERRO] Diretório .repo não encontrado em: $AOSP_ROOT"
  echo "Execute 'repo init -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r67 --depth=1' na raiz do AOSP primeiro."
  exit 1
fi

mkdir -p "$LOCAL_MANIFESTS_DIR"
cp -f "$REPO_DIR/manifests/manifest_brcm_rpi.xml" "$LOCAL_MANIFESTS_DIR/"
cp -f "$REPO_DIR/manifests/remove_projects.xml" "$LOCAL_MANIFESTS_DIR/"

echo "[OK] Manifests copiados para $LOCAL_MANIFESTS_DIR:"
ls -la "$LOCAL_MANIFESTS_DIR"
echo ""
echo "Próximo passo (na raiz $AOSP_ROOT):"
echo "  repo sync -c --no-tags --no-clone-bundle --force-sync -j8"

#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AOSP_ROOT="$(cd "$REPO_DIR/../.." && pwd)"
PATCHES_DIR="$REPO_DIR/patches"

if [ ! -d "$PATCHES_DIR" ]; then
  echo "[INFO] Pasta patches/ não encontrada. Nada para aplicar."
  exit 0
fi

shopt -s nullglob
patches=("$PATCHES_DIR"/*.patch)
shopt -u nullglob

if [ "${#patches[@]}" -eq 0 ]; then
  echo "[INFO] Nenhum arquivo .patch encontrado em $PATCHES_DIR."
  exit 0
fi

applied=0
skipped=0

for patch_file in "${patches[@]}"; do
  base="$(basename "$patch_file" .patch)"
  proj="${base//__/\/}"
  proj_dir="$AOSP_ROOT/$proj"

  if [ ! -d "$proj_dir" ]; then
    echo "[ERRO] Diretório alvo não encontrado no AOSP: $proj_dir (patch: $(basename "$patch_file"))"
    exit 1
  fi

  if git -C "$proj_dir" apply --reverse --check "$patch_file" 2>/dev/null; then
    echo "[OK - JÁ APLICADO] $proj ($(basename "$patch_file"))"
    skipped=$((skipped + 1))
  elif git -C "$proj_dir" apply --check "$patch_file" 2>/dev/null; then
    git -C "$proj_dir" apply "$patch_file"
    echo "[APLICADO] $proj ($(basename "$patch_file"))"
    applied=$((applied + 1))
  else
    echo "[ERRO] Falha ao aplicar patch $(basename "$patch_file") em $proj_dir."
    echo "       Verifique alterações locais conflitantes com: git -C $proj_dir status"
    exit 1
  fi
done

echo ""
echo "Concluído: $applied aplicado(s), $skipped já estava(m) aplicado(s)."

#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AOSP_ROOT="$(cd "$REPO_DIR/../.." && pwd)"
PATCHES_DIR="$REPO_DIR/patches"
PROJECT_LIST="$AOSP_ROOT/.repo/project.list"

if [ ! -f "$PROJECT_LIST" ]; then
  echo "[ERRO] Arquivo $PROJECT_LIST não encontrado. Este repositório precisa estar em <AOSP_ROOT>/device/Hands-On-Fliperama."
  exit 1
fi

mkdir -p "$PATCHES_DIR"
rm -f "$PATCHES_DIR"/*.patch

exported=0
untracked_warnings=0

while IFS= read -r proj; do
  [ -z "$proj" ] && continue
  proj_dir="$AOSP_ROOT/$proj"
  [ -d "$proj_dir" ] || continue

  # Captura alterações staged e unstaged em arquivos rastreados (ou marcados com git add -N)
  diff_content="$(git -C "$proj_dir" diff HEAD --binary 2>/dev/null || true)"
  if [ -n "$diff_content" ]; then
    patch_name="${proj//\//__}.patch"
    printf "%s\n" "$diff_content" > "$PATCHES_DIR/$patch_name"
    echo "[EXPORTADO] $proj -> patches/$patch_name"
    exported=$((exported + 1))
  fi

  # Avisa se houver arquivos novos não rastreados dentro de um repo nativo do AOSP
  untracked="$(git -C "$proj_dir" ls-files --others --exclude-standard 2>/dev/null || true)"
  if [ -n "$untracked" ]; then
    echo "[AVISO] Arquivos não rastreados em '$proj' (não incluídos no patch):"
    echo "$untracked" | sed 's/^/        /'
    echo "        -> Se quiser incluí-los no patch, rode 'git -C $proj add -N <arquivo>' e reexecute este script."
    untracked_warnings=$((untracked_warnings + 1))
  fi
done < "$PROJECT_LIST"

echo ""
echo "Concluído: $exported patch(es) exportado(s) em $PATCHES_DIR."
if [ "$untracked_warnings" -gt 0 ]; then
  echo "Atenção: $untracked_warnings repositório(s) possuem arquivos não rastreados (veja avisos acima)."
fi

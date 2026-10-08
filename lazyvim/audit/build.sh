#!/usr/bin/env bash
# Post-process the raw dumps: diff live against pristine Neovim, and attribute
# each locked plugin to the spec file that asked for it.
#
# Run after `:luafile audit/dump.lua` in a live session.
set -uo pipefail

cd "$(dirname "$0")"
RAW=raw
LV=~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins

have() { [ -s "$RAW/$1" ]; }

# --- 1. Live vs pristine 0.12 -------------------------------------------------
# Without this, gcc / grn / gO / ]q / gx read as "LazyVim features" when they are
# Neovim defaults from vim/_core/defaults.
for f in keymaps autocmds commands globals; do
  if have "clean-$f.tsv" && have "$f.tsv"; then
    diff <(sort "$RAW/clean-$f.tsv") <(sort "$RAW/$f.tsv") > "diff-$f.txt"
    printf '%-22s %s lines added by the config\n' "$f" "$(grep -c '^>' "diff-$f.txt")"
  else
    printf '%-22s SKIPPED (run dump.lua live first)\n' "$f"
  fi
done

# Options: the in-file `differs` column is cheaper than a diff and catches more.
if have options.tsv; then
  awk -F'\t' 'NR==1 || $5=="true"' "$RAW/options.tsv" > diff-options.txt
  printf '%-22s %s options differ from nvim defaults\n' options "$(($(wc -l < diff-options.txt) - 1))"
fi

# --- 2. Plugin provenance -----------------------------------------------------
# lazy.nvim does not record which spec file asked for a plugin (_.module is not a
# field), so grep -- scoped to exactly the imported module set. Grepping all of
# LazyVim gives false hits from the 90+ extras that are not enabled.
SCOPE=(
  "$LV"/*.lua
  "$LV"/lsp/*.lua
  "$LV"/extras/lang/json.lua
  "$LV"/extras/lang/markdown.lua
  "$LV"/extras/lang/nix.lua
  "$LV"/extras/lang/typescript/*.lua
  ../lua/plugins
)

{
  printf 'plugin\tasked_for_by\n'
  jq -r 'keys[]' ../lazy-lock.json | while read -r p; do
    hits=$(rg -l --no-messages -F "$p" "${SCOPE[@]}" 2>/dev/null \
      | sed -e "s|.*/lazyvim/plugins/extras/lang/|x:|" \
            -e "s|.*/lazyvim/plugins/lsp/|core:lsp/|" \
            -e "s|.*/lazyvim/plugins/|core:|" \
            -e "s|.*/lua/plugins/|user:|" \
      | paste -sd, -)
    printf '%s\t%s\n' "$p" "${hits:-UNATTRIBUTED}"
  done
} > "$RAW/plugin-provenance.tsv"
printf '%-22s %s plugins, %s unattributed\n' provenance \
  "$(($(wc -l < "$RAW/plugin-provenance.tsv") - 1))" \
  "$(grep -c UNATTRIBUTED "$RAW/plugin-provenance.tsv")"

# --- 3. Extras source, for reading in full ------------------------------------
# Seven extras are active, not the four in lazyvim.json. LazyVim auto-selects a
# default for picker / cmp / explorer in config/init.lua:426-440 and imports it
# without recording it anywhere in the repo -- which is why snacks.picker and
# snacks.explorer appear from nowhere. spec-modules.txt from the live dump is the
# authoritative list; these are the ones that resolve today.
for e in \
  lang/json lang/markdown lang/nix \
  lang/typescript/init lang/typescript/vtsls lang/typescript/biome \
  editor/snacks_picker editor/snacks_explorer coding/blink; do
  [ -f "$LV/extras/$e.lua" ] || continue
  printf '\n═══════════ %s ═══════════\n' "$e"
  cat "$LV/extras/$e.lua"
done > "$RAW/extras-source.txt"
printf '%-22s %s lines\n' extras-source "$(wc -l < "$RAW/extras-source.txt")"

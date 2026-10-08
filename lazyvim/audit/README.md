# Migration audit runbook

Artifacts: `audit/raw/*` (generated, gitignored) → `../AUDIT.md` (hand-decided, committed).

## Already done

- Versions frozen, `checker.enabled = false` in `lua/config/lazy.lua`.
- `lazy-lock.json` snapshotted to `audit/lazy-lock.frozen.json`.
- Pristine-Neovim baseline: `audit/raw/clean-*.tsv`.
- Plugin provenance + concatenated extras source: `audit/raw/plugin-provenance.tsv`,
  `extras-source.txt`.
- Keystroke telemetry armed behind `NVIM_AUDIT=1`.

## What you run

1. **Start collecting usage now**, so the signal is ready when decisions are due:

       export NVIM_AUDIT=1     # in your shell profile, for the next two weeks

2. **The live dump.** Open a real TypeScript repo, open a few real files of different
   types, wait for LSP to attach, then:

       :luafile audit/dump.lua

   Interactive, not headless: `VeryLazy` fires via `vim.schedule` after `VimEnter`, so a
   `-c` invocation runs too early, and LSP clients only exist with real files loaded.
   Sanity check: the script prints `did_very_lazy = true`.

3. **The filetype probe**, twice:

       :luafile audit/probe.lua
       :lua vim.g.audit_probe_real = true
       :luafile audit/probe.lua

   The second pass also materialises the `lsp=`-scoped snacks maps as real buffer-local
   maps, which cross-checks the `by_lsp` upvalue extraction in `dump.lua`.

4. **Build the diffs:**

       ./audit/build.sh

5. **Capture the rest by hand** into `AUDIT.md`: `:checkhealth`, `:LazyExtras`,
   `:Lazy profile`, `:LazyFormatInfo` and `:ConformInfo` per filetype.

## Then read

~2,100 lines, in dependency order, filling in the Decision columns as you go:
`lazyvim/config/options.lua` (118) · `config/keymaps.lua` (215) · `config/autocmds.lua`
(131) · `config/init.lua` (466) · `plugins/ui.lua` (330) · `plugins/editor.lua` (271) ·
`plugins/lsp/init.lua` (318) · `plugins/treesitter.lua` (214) · `util/root.lua` (205) ·
`util/format.lua` (196).

One inventory section per sitting, in this order: Options → Globals → Autocmds → Commands →
Plugins → Extras → LSP/format/lint → Keymaps (biggest, do last — by then you recognise most
rows) → Implicit mechanisms.

## Teardown

Delete `audit/telemetry.lua` and its `require` in `lua/config/keymaps.lua`, unset
`NVIM_AUDIT`, and decide whether `checker.enabled` goes back on.

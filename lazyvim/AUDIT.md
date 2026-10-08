# LazyVim Migration Inventory

Frozen against: **LazyVim `c10948c5` (16.0.0)** · lazy.nvim `85c7ff3` (11.17.5) ·
snacks.nvim `882c996` · **Neovim 0.12.5** · macOS aarch64-darwin
Generated 2026-09-17. Regenerate: `:luafile audit/dump.lua`, then `./audit/build.sh`.

`checker.enabled` is **off** in `lua/config/lazy.lua` for the duration — a mid-audit
`:Lazy update` invalidates every `file:line` in the Source columns. Turn it back on, or
leave it off deliberately, at cutover.

## Decision legend

| Code | Meaning |
| --- | --- |
| `KEEP` | Reimplement verbatim in the new config |
| `ADAPT` | Reimplement, but changed — say how in Notes |
| `DROP` | Deliberately not carried over |
| `OWN` | Already my own code — moves as-is |
| `?` | Don't know if I use it. Default action: DROP, and see if I miss it |

## Provenance legend

`nvim` (0.12 default, present in `--clean`) · `cfg` (`lazyvim/config/*`) ·
`core` (`lazyvim/plugins/*`) · `x:<extra>` · `plugin` (the plugin's own default) ·
`user` (`lua/plugins`, `lua/jcing`)

---

## 0. Finding that reframes the rest

**Seven LazyVim extras are active, not the four in `lazyvim.json`.**

`lazyvim.json` lists `lang.json`, `lang.markdown`, `lang.nix`, `lang.typescript`. On top of
those, `lazyvim/config/init.lua:426-440` picks a default for three categories and imports
the corresponding extra without recording it anywhere in this repo:

| Category | Auto-selected extra | Lines |
| --- | --- | --- |
| picker | `editor.snacks_picker` | 265 |
| cmp | `coding.blink` | 212 |
| explorer | `editor.snacks_explorer` | 24 |

This is the direct explanation for snacks feeling omnipresent and undebuggable: its two
largest surfaces are contributed by extras that appear in no file you have ever edited.
`lang.typescript` is likewise a *directory* import — `init.lua` plus `biome.lua`,
`vtsls.lua`, `oxc.lua`, `tsgo.lua`, 544 lines in total.

Active extras total ~1,250 lines. `audit/raw/extras-source.txt` has all of them
concatenated for reading. `audit/raw/spec-modules.txt` (live dump) is the authoritative
list — confirm against it.

---

## 1. Keymaps

Source: `audit/raw/keymaps.tsv`, `keymaps-scoped.tsv`, `keymaps-lazyspec.tsv`,
`diff-keymaps.txt`. One `###` per leader group, then non-leader, then mode-specific.

Columns: Key · Mode · Description · Provenance · Source · **Scope** · Used · **Decision** ·
**Notes**. Only the last two are hand-written.

**Scope is the column that earns the exercise** — `global` / `ft:markdown` / `lsp:biome` /
`has=rename` / `buf`. Conditionally-existing maps are exactly the ones that feel like magic
today, and nothing else makes them visible.

Give each group a rollup line: `> 23 maps · KEEP 9 · ADAPT 3 · DROP 8 · ? 3`

Groups to create: `<leader>b` · `<leader>c` · `<leader>f` · `<leader>g` · `<leader>q` ·
`<leader>s` · `<leader>t` · `<leader>u` · `<leader>w` · `<leader>x` · `<leader>` other ·
non-leader `g*` · non-leader `[` `]` · `<C-*>` · insert/visual/terminal · buffer-local by
filetype · LSP-conditional.

---

## 2. Options

Source: `audit/diff-options.txt` (rows where the live value differs from the Neovim
default). Columns: Option · Scope · LazyVim value · Neovim default · Provenance · Decision ·
Notes.

Mark in bold any row where your own code already overrides LazyVim — `clipboard` is one,
and it is settled, not open.

---

## 3. Globals (`vim.g`)

Source: `audit/diff-globals.txt`. Small but disproportionately important: these are
LazyVim's feature flags (`root_spec`, `autoformat`, `lazyvim_picker`, `ai_cmp`,
`trouble_lualine`, `snacks_animate`, `deprecation_warnings`, …). Each one is behaviour you
would otherwise rediscover by accident.

---

## 4. Autocmds

Source: `audit/diff-autocmds.txt`. Columns: Group · Event · Pattern · **What it does** ·
Provenance · Source · Decision · Notes.

"What it does" must be written in plain English by hand. It is the column that actually
cures the intransparency; everything else is generated.

---

## 5. User commands

Source: `audit/diff-commands.txt`, cross-referenced with
`audit/raw/verbose-command.txt` (`nvim_get_commands` exposes no callback, so there is no
`debug.getinfo` attribution here). `:PrBase` is `OWN`.

---

## 6. Plugins (40)

Source: `audit/raw/plugins.tsv` (load trigger, fragment count, fragment key sets) joined
with `audit/raw/plugin-provenance.tsv` (which spec file asked for it).

`n_frags > 1` flags a merge you must understand before reimplementing. Known ranking:
`snacks.nvim` is touched by 6 spec files, `nvim-lspconfig` by 13, `LazyVim` by 21.

Already established from provenance:

| Plugin | Asked for by | Note |
| --- | --- | --- |
| `diffview.nvim`, `git-conflict.nvim`, `toggleterm.nvim`, `nvim-highlight-colors`, `jcing-dark.nvim` | user only | `OWN` — these are your deliberate additions |
| `blink.cmp` | user spec + `x:coding.blink` | the extra is auto-enabled, see §0 |
| `friendly-snippets` | nothing in the active import set | pulled in by `x:coding.blink`; verify, else it is lock drift |
| `catppuccin`, `tokyonight.nvim` | `core:colorscheme.lua` | unused — jcing-dark is the active scheme |
| `nui.nvim` | `core:ui.lua` | noice's dependency only |

---

## 7. Extras — contribution breakdown

One `###` per active extra (all seven), each listing exactly what it added: plugins,
treesitter parsers, Mason tools, LSP servers, `formatters_by_ft`, `linters_by_ft`, keymaps.
Then a decision per contribution, not per extra.

**Orphan check:** Mason has `jq` and `markdown-toc` installed. If nothing in the active
import set requests them, they are leftovers from a removed extra and are free to drop.

---

## 8. LSP / format / lint

### 8.1 LSP keymaps

Source: `audit/raw/lsp-keys.tsv`, `lspconfig-opts.lua`.

Mechanism: declared in `nvim-lspconfig` opts as `servers["*"].keys` and
`servers.<name>.keys`, merged via `opts_extend = { "servers.*.keys" }`, installed by
`lazyvim/plugins/lsp/keymaps.lua` through `Snacks.keymap.set` with an `lsp` filter.
`has = "X"` expands to `textDocument/X` and the map exists only in buffers with a capable
client. Later registrations win — which is exactly why your biome `<leader>co` shadows the
core one in biome buffers and nowhere else.

### 8.2 Formatters (conform)

Source: `audit/raw/conform-opts.lua`, `filetypes.tsv`, plus `:LazyFormatInfo` and
`:ConformInfo` per filetype.

Mechanism (`lazyvim/util/format.lua`): one `BufWritePre` autocmd in augroup `LazyFormat`;
enablement cascades `vim.b.autoformat` over `vim.g.autoformat`; a priority-ordered registry
where conform registers at 100 and the LSP formatter at 1, so conform wins wherever it has
a formatter. `formatexpr` routes `gq` through the same path.

### 8.3 Linters (nvim-lint)

Source: `audit/raw/lint-opts.lua`, `filetypes.tsv`. The trigger autocmd
(`BufWritePost`/`BufReadPost`/`InsertLeave`) is LazyVim's, not nvim-lint's — it does not
ship one, so it must be rewritten.

---

## 9. Implicit mechanisms

The only section that cannot be generated, and the one that actually answers "why does it
do that". One `###` each, ending in a decision and a line-count estimate to reimplement.

- **Root detection** — `vim.g.root_spec`, `lazyvim/util/root.lua`, 205 lines. Silently
  decides the cwd for every picker and grep. The single biggest source of "why did it
  search *there*".
- **Formatter registry and priority** — §8.2.
- **`LazyFile` pseudo-event** — LazyVim's synthetic alias for
  `BufReadPost`/`BufNewFile`/`BufWritePre`, used by ~8 plugins. Replace with real events.
- **`Snacks.toggle`** — the entire `<leader>u*` namespace is generated, not written.
- **`safe_keymap_set` deferral** — LazyVim skips a map if lazy's `keys` handler already
  claims that lhs, which is why some maps appear to come from two places.
- **Icon set** — `lazyvim/config/init.lua` `M.icons`, consumed by lualine, bufferline,
  trouble, diagnostic signs and mini.icons. Copy verbatim or accept drift everywhere at once.
- **`opts_extend`** — lazy.nvim's list-append merge. Anything relying on append semantics
  must be flattened by hand.

---

## 10. Rollup

| Section | Rows | KEEP | ADAPT | DROP | OWN | ? |
| --- | --- | --- | --- | --- | --- | --- |
| Keymaps | | | | | | |
| Options | | | | | | |
| Globals | | | | | | |
| Autocmds | | | | | | |
| Commands | | | | | | |
| Plugins | 40 | | | | | |

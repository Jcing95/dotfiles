-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Over SSH there's no local clipboard tool (xclip/pbcopy) reachable, so yanks
-- never reach the local system clipboard. Route the clipboard through OSC 52:
-- nvim hands yanked text to the terminal, which writes it to the *local*
-- clipboard. Travels through SSH (and tmux, if `set-clipboard on`) as plain
-- terminal bytes. Requires Neovim 0.10+ and an OSC 52-capable terminal (WezTerm
-- supports it out of the box).
--
-- LazyVim deliberately sets `clipboard = ""` over SSH (see its options.lua), so
-- re-enable `unnamedplus` here to keep yank/paste routed through `+` seamlessly.
if vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }
  vim.opt.clipboard = "unnamedplus"
end

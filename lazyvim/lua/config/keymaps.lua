-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Migration audit only: records which keymaps actually get pressed, under
-- NVIM_AUDIT=1. Delete this and audit/telemetry.lua once AUDIT.md is decided.
if vim.env.NVIM_AUDIT then
  pcall(dofile, vim.fn.stdpath("config") .. "/audit/telemetry.lua")
end

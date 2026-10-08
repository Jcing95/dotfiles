return {
  "saghen/blink.cmp",
  opts = {
    completion = {
      list = {
        -- navigation previews the item into the buffer and only cancel undoes it,
        -- so any non-keyword char (space) silently commits the selection
        selection = { auto_insert = false },
      },
    },
    keymap = {
      ["<CR>"] = false,
      ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
    },
  },
}

local colors = require("colors")

sbar.add("item", "notch", {
  position = "center",
  display  = "main",
  icon     = { drawing = false },
  label    = { drawing = false },
  width    = 212,
  background = {
    border_width  = 2,
    border_color  = colors.green,
    corner_radius = 8,
  },
})

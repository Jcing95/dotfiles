local colors = require("colors")

sbar.add("item", "indicator_spacer", {
  position     = "right",
  icon         = { drawing = false },
  label        = { drawing = false },
  width        = 15,
  padding_left = 10,
  background = {
    color         = colors.green_bg,
    border_width  = 2,
    border_color  = colors.green,
    corner_radius = 10,
    height        = 15,
    y_offset      = 4,
  },
})

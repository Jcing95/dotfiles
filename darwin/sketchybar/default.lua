local colors   = require("colors")
local settings = require("settings")

sbar.default({
  icon = {
    font          = { family = settings.font, style = "Light", size = 13.0 },
    color         = colors.white,
    padding_left  = 6,
    padding_right = 4,
  },
  label = {
    font          = { family = settings.font, style = "Light", size = 13.0 },
    color         = colors.white,
    padding_left  = 4,
    padding_right = 6,
  },
  background = {
    color          = colors.transparent,
    corner_radius  = 10,
    height         = 40,
    padding_right  = 5,
  },
})

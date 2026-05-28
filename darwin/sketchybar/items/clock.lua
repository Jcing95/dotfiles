local settings = require("settings")

local clock = sbar.add("item", "clock", {
  position     = "e",
  update_freq  = 10,
  icon         = { drawing = false },
  label = {
    string        = os.date("%H:%M"),
    font          = { family = settings.font, style = "Regular", size = 13.0 },
    padding_right = 10,
  },
  padding_left = 10,
})

clock:subscribe({ "routine", "system_woke" }, function()
  clock:set({ label = os.date("%H:%M") })
end)

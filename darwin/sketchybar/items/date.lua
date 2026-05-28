local settings = require("settings")

local date = sbar.add("item", "date", {
  position      = "q",
  update_freq   = 60,
  icon          = { drawing = false },
  label = {
    string        = os.date("%d.%m"),
    font          = { family = settings.font, style = "Regular", size = 13.0 },
    padding_left  = 10,
  },
  padding_right = 10,
})

date:subscribe({ "routine", "system_woke" }, function()
  date:set({ label = os.date("%d.%m") })
end)

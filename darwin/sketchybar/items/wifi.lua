local settings = require("settings")

local wifi = sbar.add("item", "wifi", {
  position    = "right",
  update_freq = 10,
  icon = {
    font          = { family = settings.font, style = "Light", size = 15.0 },
    padding_left  = 10,
    padding_right = 10,
  },
  label = { drawing = false },
})

local function update()
  sbar.exec("ipconfig getifaddr en0 2>/dev/null", function(result, exit_code)
    local connected = exit_code == 0 and result and result:gsub("%s+", "") ~= ""
    wifi:set({
      icon = connected and settings.wifi_icons.connected
                       or  settings.wifi_icons.disconnected,
    })
  end)
end

wifi:subscribe({ "wifi_change", "system_woke", "routine" }, update)

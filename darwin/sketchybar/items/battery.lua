local settings = require("settings")

local battery = sbar.add("item", "battery", {
  position    = "right",
  update_freq = 60,
  icon        = { padding_left = 10 },
  label       = { padding_right = 6 },
})

local function update()
  sbar.exec("pmset -g batt", function(info)
    if not info then return end

    local pct = info:match("(%d+)%%")
    if not pct then
      battery:set({ icon = settings.battery_icons.unknown, label = "N/A" })
      return
    end

    pct = tonumber(pct)
    local icon
    if info:find("AC Power") then
      icon = settings.battery_icons.charging
    elseif pct >= 80 then icon = settings.battery_icons[80]
    elseif pct >= 60 then icon = settings.battery_icons[60]
    elseif pct >= 40 then icon = settings.battery_icons[40]
    elseif pct >= 20 then icon = settings.battery_icons[20]
    else                  icon = settings.battery_icons[0]
    end

    battery:set({ icon = icon, label = pct .. "%" })
  end)
end

battery:subscribe({ "routine", "power_source_change", "system_woke" }, update)

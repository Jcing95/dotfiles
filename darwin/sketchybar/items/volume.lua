local settings = require("settings")

local volume = sbar.add("item", "volume", {
  position    = "right",
  update_freq = 30,
  icon = {
    font         = { family = settings.font, style = "Light", size = 15.0 },
    padding_left = 10,
  },
  label = { padding_right = 6 },
})

local function pick_icon(vol, muted)
  if muted or vol == 0 then return settings.volume_icons.muted end
  if vol >= 66 then return settings.volume_icons[66]
  elseif vol >= 33 then return settings.volume_icons[33]
  else return settings.volume_icons[1] end
end

-- Read volume + mute in one osascript call; used for routine/woke refresh and
-- to fetch mute state when the volume_change event fires. `get volume settings`
-- returns a record string like:
--   output volume:50, input volume:75, alert volume:100, output muted:false
-- so we parse each field by name (order-independent).
local function refresh(known_vol)
  sbar.exec("osascript -e 'get volume settings'", function(result)
    if not result then return end
    local vol = known_vol or tonumber(result:match("output volume:(%d+)"))
    if not vol then return end
    local muted = result:match("output muted:(%a+)") == "true"
    volume:set({
      icon  = pick_icon(vol, muted),
      label = muted and "muted" or (vol .. "%"),
    })
  end)
end

-- volume_change delivers the new percentage instantly via env.INFO
volume:subscribe("volume_change", function(env)
  refresh(tonumber(env.INFO))
end)

volume:subscribe({ "routine", "system_woke" }, function()
  refresh(nil)
end)

-- Populate immediately on load instead of waiting for the first routine tick.
refresh(nil)

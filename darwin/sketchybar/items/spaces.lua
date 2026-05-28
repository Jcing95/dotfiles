local colors   = require("colors")
local settings = require("settings")

sbar.add("event", "aerospace_workspace_change")

for sid = 1, 9 do
  sbar.add("item", "space." .. sid, {
    position = "left",
    icon = {
      string        = tostring(sid),
      font          = { family = settings.font, style = "Regular", size = 13.0 },
      padding_left  = 10,
      padding_right = 10,
      color         = colors.gray,
    },
    label = { drawing = false },
    background = {
      color         = colors.transparent,
      height        = 40,
      corner_radius = 0,
    },
    click_script = "aerospace workspace " .. sid,
  })
end

local function apply(focused, non_empty)
  focused = (focused or ""):gsub("%s+", "")
  local present = {}
  for w in (non_empty or ""):gmatch("%S+") do present[w] = true end

  for sid = 1, 9 do
    local s        = tostring(sid)
    local is_focus = focused == s
    sbar.set("space." .. s, {
      drawing    = (present[s] or is_focus) and "on" or "off",
      icon       = { color = is_focus and colors.white        or colors.gray },
      background = { color = is_focus and colors.space_active or colors.transparent },
    })
  end
end

local function update(env)
  env = env or {}
  sbar.exec("aerospace list-workspaces --monitor all --empty no 2>/dev/null", function(non_empty)
    sbar.exec("aerospace list-workspaces --focused 2>/dev/null", function(focused)
      if not focused or focused:gsub("%s+", "") == "" then
        focused = env.FOCUSED_WORKSPACE or ""
      end
      apply(focused, non_empty)
    end)
  end)
end

local updater = sbar.add("item", "space_updater", {
  position    = "left",
  drawing     = false,
  update_freq = 5,
})

updater:subscribe({ "aerospace_workspace_change", "front_app_switched", "routine" }, update)

update()

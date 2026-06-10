local settings = require("settings")

local review_url = "https://github.com/pulls?q=is%3Aopen+is%3Apr+user-review-requested%3AJcing95+archived%3Afalse+"

local github_reviews = sbar.add("item", "github_reviews", {
  position     = "e",
  update_freq  = 60,
  drawing      = false,
  icon         = { string = settings.github_icon, padding_left = 10 },
  label        = { padding_right = 6 },
  click_script = "open '" .. review_url .. "'",
})

local function update()
  sbar.exec(
    "PATH=\"/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/opt/homebrew/bin:$PATH\" "
      .. "gh api -X GET search/issues -f q='is:open is:pr user-review-requested:@me archived:false' --jq '.total_count' 2>/dev/null",
    function(result, exit_code)
      if exit_code ~= 0 or not result then
        github_reviews:set({ drawing = false })
        return
      end

      local count = tonumber((result:gsub("%s+", "")))
      if not count or count <= 0 then
        github_reviews:set({ drawing = false })
        return
      end

      github_reviews:set({ drawing = true, label = "\u{EA64} " .. tostring(count) })
    end
  )
end

github_reviews:subscribe({ "routine", "system_woke" }, update)

update()

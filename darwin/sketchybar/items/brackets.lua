local colors = require("colors")

local frame = {
	border_width = 2,
	border_color = colors.green,
	color = colors.green_bg,
	corner_radius = 10,
	height = 40,
}

sbar.add("bracket", "notch_group", { "date", "notch", "clock" }, {
	background = frame,
})

local spaces_members = {}
for sid = 1, 9 do
	spaces_members[sid] = "space." .. sid
end
sbar.add("bracket", "spaces_group", spaces_members, {
	background = frame,
})

sbar.add("bracket", "right_group", { "volume", "wifi", "battery" }, {
	background = frame,
})

sbar.add("bracket", "github_group", { "github_reviews" }, {
	background = frame,
})

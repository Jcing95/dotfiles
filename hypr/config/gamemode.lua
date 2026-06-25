local in_transition = false

local function toggle(target)
	if in_transition then
		return
	end
	in_transition = true
	hl.dispatch(hl.dsp.submap(target))
	hl.timer(function()
		in_transition = false
	end, { timeout = 100, type = "oneshot" })
end

hl.bind("CTRL + SUPER + TAB", function()
	toggle("game")
end)

hl.define_submap("game", function()
	hl.bind("CTRL + SUPER + TAB", function()
		toggle("reset")
	end)
end)

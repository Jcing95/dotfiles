-- "Game mode" submap — suppresses every non-universal Hyprland keybind so
-- games (Starcraft control groups on CTRL+0..9, etc.) receive their keys
-- directly. Waybar's built-in hyprland/submap module shows the state.
--
-- Same key for enter/exit: after dispatching the submap change inside the
-- bind callback, Hyprland re-evaluates the same press in the new submap
-- and fires its bind too — instantly toggling back. Guard with a flag
-- that's cleared by a short timer so only the first dispatch lands.

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

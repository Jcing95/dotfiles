-- Affinity runs under Wine and manages its own tool panels, pickers and modal
-- dialogs as top-level windows, so tiling scatters them across the layout.
hl.window_rule({
	name = "affinity-float",
	match = { class = [[^[Aa]ffinity\.exe$]] },
	float = true,
})

-- Starting an in-app drag maps an untitled helper window under the cursor.
-- Focusing it makes Wine cancel the drag before it begins.
hl.window_rule({
	name = "affinity-no-focus-steal",
	match = { class = [[^[Aa]ffinity\.exe$]], initial_title = [[^$]] },
	no_initial_focus = true,
})

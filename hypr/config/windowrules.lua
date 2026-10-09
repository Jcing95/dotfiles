-- Affinity runs under Wine and manages its own tool panels, pickers and modal
-- dialogs as top-level windows, so tiling scatters them across the layout.
hl.window_rule({
	name = "affinity-float",
	match = { class = [[^[Aa]ffinity\.exe$]] },
	float = true,
})

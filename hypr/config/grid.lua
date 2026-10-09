-- Rebuild the dwindle tree of the active workspace into equal columns: one row up to 4 windows, two rows above.
-- Odd count with two rows: the rightmost column holds a single full-height window.
local function arrange()
	local ws = hl.get_active_workspace()
	if not ws then
		return
	end

	local wins = {}
	for _, w in ipairs(hl.get_windows({ workspace = ws, mapped = true })) do
		if not w.hidden then
			table.insert(wins, w)
		end
	end
	local n = #wins
	if n < 2 then
		return
	end
	table.sort(wins, function(a, b)
		if a.at.x ~= b.at.x then
			return a.at.x < b.at.x
		end
		return a.at.y < b.at.y
	end)

	local function addr(w)
		return "address:" .. w.address
	end
	local function focus(w)
		hl.dispatch(hl.dsp.focus({ window = addr(w) }))
	end
	local function tile(w)
		hl.dispatch(hl.dsp.window.float({ action = "disable", window = addr(w) }))
	end

	local active = hl.get_active_window()
	local rows = n <= 4 and 1 or 2
	local cols = math.ceil(n / rows)
	local tops, bottoms = {}, {}
	for i, w in ipairs(wins) do
		table.insert((rows == 1 or i % 2 == 1) and tops or bottoms, w)
	end

	-- Float everything but the first window, then re-tile one by one with preselect.
	for i = 2, n do
		hl.dispatch(hl.dsp.window.float({ action = "enable", window = addr(wins[i]) }))
	end
	tile(tops[1])

	for k = 2, cols do
		focus(tops[k - 1])
		hl.dispatch(hl.dsp.layout("preselect r"))
		tile(tops[k])
	end

	-- Ratios must be set before the bottoms are added, while each top's parent is still its column-chain node.
	-- Dwindle ratios span 0..2 with 1 = half; splitratio only takes deltas, and fresh nodes start at the default.
	local base = hl.get_config("dwindle.default_split_ratio")
	for k = 1, cols - 1 do
		focus(tops[k])
		hl.dispatch(hl.dsp.layout(string.format("splitratio %.4f", 2 / (cols - k + 1) - base)))
	end

	for k, b in ipairs(bottoms) do
		focus(tops[k])
		hl.dispatch(hl.dsp.layout("preselect d"))
		tile(b)
	end

	if active then
		focus(active)
	end
end

hl.bind("SUPER + SHIFT + G", arrange)

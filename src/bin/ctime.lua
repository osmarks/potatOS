local prefixes = {
	{-12, "p"},
	{-9, "n"},
	{-6, "u"},
	{-3, "m"},
	{0, ""},
	{3, "k"},
	{6, "M"}
}

local function SI_prefix(value, unit)
    local x = math.log(value, 10)
	local last
	for _, t in ipairs(prefixes) do
		if t[1] > x then
			break	
		end
		last = t
	end
	local dp = 2 - math.floor(x - last[1])
	return (("%%.%df%%s%%s"):format(dp)):format(value / 10^(last[1]), last[2], unit)
end

local w = term.getSize()
local rows = {}
for _, info in pairs(process.list()) do
	table.insert(rows, { info.name or tostring(info.ID), SI_prefix(info.execution_time, "s"), SI_prefix(info.ctime, "s") })
end

local max_width_per_column = {}

for _, row in ipairs(rows) do
	for i, cell in ipairs(row) do
		max_width_per_column[i] = math.max(max_width_per_column[i] or 0, cell:len() + 1) 
	end
end

local vw_width = 0

for i = #max_width_per_column, 1, -1 do
	if i > 1 then
		vw_width = vw_width + max_width_per_column[i]
	end
end

local fw_start = w - vw_width

for _, row in ipairs(rows) do
	local s
	for i, cell in ipairs(row) do
		if i == 1 then
			s = cell:sub(1, fw_start - 1) .. (" "):rep((fw_start - 1) - cell:len())
		else
			cell = " " .. cell
			s = s .. (" "):rep(max_width_per_column[i] - cell:len()) .. cell
		end
	end

	textutils.pagedPrint(s)
end
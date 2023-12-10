local function try_files(lst)
	for _, v in pairs(lst) do
		local z = potatOS.read(v)
		if z then return z end
	end
	error "no file found"
end

local pos = _G
local thing = ...
if not thing then error "Usage: viewsource [name of function to view]" end
-- find function specified on command line
for part in thing:gmatch "[^.]+" do
	pos = pos[part]
	if not pos then error(thing .. " does not exist: " .. part) end
end

local info = debug.getinfo(pos)
if not info.linedefined or not info.lastlinedefined or not info.source or info.lastlinedefined == -1 then error "Is this a Lua function?" end
local sourcen = info.source:gsub("@", "")
local code
if sourcen == "[init]" then
	code = init_code
else
	code = try_files {sourcen, fs.combine("lib", sourcen), fs.combine("bin", sourcen), fs.combine("dat", sourcen)}
end
local out = ""

local function lines(str)
	local t = {}
	local function helper(line)
		table.insert(t, line)
		return ""
	end
	helper((str:gsub("(.-)\r?\n", helper)))
	return t
end

for ix, line in pairs(lines(code)) do
	if ix >= info.linedefined and ix <= info.lastlinedefined then
		out = out .. line .. "\n"
	end
end
local filename = ".viewsource-" .. thing
local f = fs.open(filename, "w")
f.write(out)
f.close()
shell.run("edit", filename)
fs.delete(filename)
-- POTATOPLEX: The best potatOS feature

local args = {...}
local targs = table.concat(args, " ")
local text

if args[1] and fs.exists(args[1]) then
	local f = fs.open(args[1], "r")
	text = f.readAll()
	f.close()
end

local function randpick(l)
	if #l == 1 then return l[1] end
	return l[math.random(1, #l)]
end

local function potatoplex_is_installed()
	if fs.isDir "startup" then return false end
	local f = fs.open("startup", "r")
	if not f then return false end
	return f.readAll():match "POTATOPLEX"
end

if commands then
	print "Enabling Command Potatoplex mode. Do not attempt to resist."
	_G.os.pullEvent = coroutine.yield
	
	if not potatoplex_is_installed() then
		print "Installing as startup"
		settings.set("shell.allow_startup", true)
		settings.set("shell.allow_disk_startup", false)
		settings.save ".settings"
		if fs.exists "startup" then fs.delete "startup" end
		local f = fs.open("startup", "w")
		f.write([[
-- POTATOPLEX!!!!!
_G.os.pullEvent = coroutine.yield
local h = http.get "https://pastebin.com/raw/wYBZjQhN"
local t = h.readAll()
h.close()
local fn, err = load(t, "=potatoplex")
if not fn then error(err)
else fn() end
		]])
	end

	local items = {
		"minecraft:diamond_block",
		"minecraft:emerald_block",
		"minecraft:redstone_block",
		"minecraft:lapis_block",
		"minecraft:iron_block",
		"minecraft:gold_block",
		"minecraft:command_block",
		"computronics:oc_special_parts",
		"opencomputers:casecreative",
		{"opencomputers:material", 25},
		{"opencomputers:material", 22},
		{"opencomputers:material", 19},
		{"opencomputers:component", 19},
		{"opencomputers:component", 18},
		{"opencomputers:component", 12},
		{"opencomputers:component", 32},
		{"opencomputers:card", 0},
		{"plethora:module", 7},
		{"plethora:module", 1},
		"bibliocraft:bookcasecreative",
		"minecraft:nether_star",
		"quark:pirate_hat"
	}

	local baseblocks = {
		"minecraft:wool",
		"minecraft:concrete",
		"minecraft:concrete_powder",
		"chisel:antiblock",
		"chisel:energizedvoidstone",
		"chisel:voidstonerunic",
		"chisel:voidstone",
		"minecraft:end_portal",
		"quark:stained_clay_tiles",
		"quark:stained_planks",
		"quark:quilted_wool",
		"quark:cavecrystal",
		"minecraft:stained_hardened_clay",
		"minecraft:stained_glass",
		"minecraft:stained_glass_pane",
		{"minecraft:white_glazed_terracotta", 0},
		{"minecraft:orange_glazed_terracotta", 0},
		{"minecraft:magneta_glazed_terracotta", 0},
		{"minecraft:light_blue_glazed_terracotta", 0},
		{"minecraft:yellow_glazed_terracotta", 0},
		{"minecraft:lime_glazed_terracotta", 0},	
		{"minecraft:pink_glazed_terracotta", 0},
		{"minecraft:gray_glazed_terracotta", 0},
		{"minecraft:silver_glazed_terracotta", 0},
		{"minecraft:cyan_glazed_terracotta", 0},
		{"minecraft:purple_glazed_terracotta", 0},
		{"minecraft:blue_glazed_terracotta", 0},
		{"minecraft:brown_glazed_terracotta", 0},
		{"minecraft:green_glazed_terracotta", 0},
		{"minecraft:red_glazed_terracotta", 0},
		{"minecraft:black_glazed_terracotta", 0},
		{"minecraft:bedrock", 0},
		{"minecraft:diamond_block", 0},
		{"minecraft:emerald_block", 0},
		{"minecraft:redstone_block", 0},
		{"minecraft:lapis_block", 0},
		{"minecraft:iron_block", 0},
		{"minecraft:gold_block", 0}
	}

	local blocks = {}
	for _, b in pairs(baseblocks) do
		if type(b) == "table" then table.insert(blocks, b)
		else
			for i = 0, 15 do
				table.insert(blocks, {b, i})
			end
		end
	end

	local x, y, z = commands.getBlockPosition()
	local cx, cz = math.floor(x / 16) * 16, math.floor(z / 16) * 16
	
	local give_items = not targs:match "scrooge"

	while true do
		for i = 1, 8 do
			local rx, ry, rz = math.random(cx, cx + 15), math.random(0, 255), math.random(cz, cz + 15)
			local pick = randpick(blocks)
			local meta, block = pick[2], pick[1]
			if rx ~= x and ry ~= y and rz ~= z then
				commands.execAsync(("setblock %d %d %d %s %d replace"):format(rx, ry, rz, block, meta))
			end
		end
		if give_items and math.random(0, 1000) == 42 then
			print "POTATO FESTIVAL!"
			for i = 1, 36 do
				local pick = randpick(items)
				local meta = 0
				local item = pick
				if type(pick) == "table" then meta = pick[2] item = pick[1] end
				commands.execAsync(("give @a %s 64 %d"):format(item, meta))
			end
		end
		sleep()
	end
end

local monitors = {peripheral.find "monitor"}
local signs = {peripheral.find "minecraft:sign"}
table.insert(monitors, term.current())

local duochrome_mode = targs:find "duochrome" ~= nil
local function random_color()
	if duochrome_mode then
		if math.random(0, 1) == 0 then return colors.black
		else return colors.white end
	end
	return math.pow(2, math.random(0, 15))
end

local function random_segment(text)
	local start = math.random(1, #text)
	return text:sub(start, math.random(start, #text))
end

local sixel_mode = targs:find "sixel" ~= nil
local min, max = 0, 255
if sixel_mode then
	min, max = 128, 159
end

local function random_char()
	return string.char(math.random(min, max))
end

local colors = {}
if duochrome_mode then
	colors = {"0", "f"}
else
	for i = 0, 15 do table.insert(colors, ("%x"):format(i)) end
end

local function random_pick(list)
	return list[math.random(1, #list)]
end

local function one_pixel(m, x, y)
	m.setCursorPos(x, y)
	if text then
		m.setBackgroundColor(random_color())
		m.setTextColor(random_color())
		m.write(random_segment(text))
	else	
		m.blit(random_char(), random_pick(colors), random_pick(colors))
	end
end

local chat_colors = {
	"k",
	"l",
	"m",
	"n",
	"o"
}
for i = 0, 16 do table.insert(chat_colors, string.format("%x", i)) end

local hook = _G.potatoplex_hook

local slowpalette_mode = targs:find "slowpalette" ~= nil
local function run(m)
	local w, h = m.getSize()

	for i = 1, 16 do
		local x, y = math.random(1, w), math.random(1, h)
		one_pixel(m, x, y)
	end
	if not slowpalette_mode or math.random(0, 20) == 13 then
		m.setPaletteColor(random_color(), math.random(), math.random(), math.random())
	end
	if hook then hook(m) end
end

for k, v in pairs(monitors) do if v.setTextScale then v.setTextScale(1) end end

local function line()
	local out = "\167" .. random_pick(chat_colors)
	for i = 1, 32 do
		out = out .. random_char()
	end
	return out
end

while true do
	for k, v in pairs(monitors) do
		pcall(run, v)
		sleep(0)
	end
	for k, v in pairs(signs) do
		pcall(v.setSignText, line(), line(), line(), line())
		sleep()
	end
end
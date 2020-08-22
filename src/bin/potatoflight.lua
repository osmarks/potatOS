if peripheral.getType "back" ~= "neuralInterface" then error "for neural interfaces with kinetic augments and stuff, silly potato" end

local user = "gollark"
if settings.get "flight_user" then user = settings.get "flight_user" end
if potatOS and potatOS.registry then 
	user = potatOS.registry.get "flight_user"
	if not user then error "Please set your username with `est flight_user [username]`" end
end
local modules = peripheral.wrap "back"

local function length(x, y, z)
	return math.sqrt(x * x + y * y + z * z)
end

local function round(num, dp)
	local mult = 10^(dp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local canvas = modules.canvas()

-- Backported from Opus Neural ElytraFly since it has a nicer implementation than I do
local function display(meta)
  if canvas then
	local w, h = canvas.getSize()
    if not canvas.group then
      canvas.group = canvas.addGroup({ w - 80, 15 })
      canvas.group.addRectangle(0, 0, 60, 30, 0x00000033)
      canvas.pitch = canvas.group.addText({ 4, 5 }, '') -- , 0x202020FF)
      canvas.pitch.setShadow(true)
      canvas.pitch.setScale(.75)
      canvas.group2 = canvas.addGroup({ w - 10, 15 })
      canvas.group2.addLines(
        { 0,   0 },
        { 0, 180 },
        { 5, 180 },
        { 5,   0 },
        0x202020FF,
        2)
      canvas.meter = canvas.group2.addRectangle(0, 0, 5, 1)
    end
    local size = math.abs(meta.pitch) -- math.ceil(math.abs(meta.pitch) / 9)
    local y = 0
    local color = 0x202020FF
    if meta.pitch < 0 then
      y = size
      color = 0x808080FF
    end
    canvas.meter.setPosition(0, 90 - y)
    canvas.meter.setSize(5, size)
    canvas.meter.setColor(color)
    canvas.pitch.setText(string.format('Pitch: %s\nMotion Y: %s\nSpeed: %s',
      math.floor(-meta.pitch),
      round(meta.motionY, 2),
      round(length(meta.motionX, meta.motionY, meta.motionZ), 2)))
  end
end

--[[
local function pad(s, i)
	return ("%s %s%.1f"):format(s, i >= 0 and "+" or "", i)
end

local overlay = {
	function(meta) return pad("X:", meta.motionX) end,
	function(meta) return pad("Y:", meta.motionY) end,
	function(meta) return pad("Z:", meta.motionZ) end,
	function(meta) return pad("  ", length(meta.motionX, meta.motionY, meta.motionZ)) end,
	function(meta) return pad("P:", meta.power) end
}

local objects
local function draw_overlay(meta)
	if not objects then
		objects = {}
		local w, h = canv.getSize()
		for ix in pairs(overlay) do
			objects[ix] = canv.addText({w - 40, ix * 10 + 5}, "")
			objects[ix].setColor(0xFFFFFFFF)
		end
	end
	for ix, f in pairs(overlay) do
		objects[ix].setText(f(meta))
	end
end
]]

local function get_power(meta)
	local power = 4
	if meta.isElytraFlying or meta.isFlying then power = 1 end
	if meta.isSneaking then power = 4 end
	if _G.tps then
		power = power * (20 / _G.tps)
	end
	return math.min(power, 4)
end

local function get_meta()
	local meta = modules.getMetaByName(user)
	meta.power = get_power(meta)
	display(meta)
	return meta
end

while true do
	local meta = get_meta()
  
	while (not _G.stop_flight) and (meta.isSneaking or meta.isFlying or meta.isElytraFlying) do
		modules.launch(meta.yaw, meta.pitch, meta.power)
		sleep(0.1)
		meta = get_meta()
	end

	if meta.motionY < -0.8 then
		modules.launch(0, 270, meta.power / 2)
	end

	sleep(0.4)
end
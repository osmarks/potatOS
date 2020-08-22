local clock = peripheral.find("manipulator", function(_, o) return o.hasModule "minecraft:clock" end)

local run = true
while run do
	term.clear()
	term.setCursorPos(1, 1)
	local ms = os.epoch "utc" % 1000
	local gametime = os.time()
	local integer = math.floor(gametime)
	local fractional = gametime - integer
	local gametimestring = ("%02d:%02d"):format(integer, math.floor(fractional * 60))
	local out = {
		{"UTC", (os.date "!%H:%M:%S.%%03d %d/%m/%Y"):format(ms)},
		{"Server time", (os.date "%H:%M:%S.%%03d %d/%m/%Y"):format(ms)},
		{"World time", ("%s on %d"):format(gametimestring, os.day())}
	}
	if clock then
		table.insert(out, {"Celestial angle", ("%f degrees"):format(clock.getCelestialAngle())})
		table.insert(out, {"Moon phase", tostring(clock.getMoonPhase())})
		table.insert(out, {"World time (ticks)", tostring(clock.getTime())})
	end
	textutils.tabulate(unpack(out))
	print "Press ; to exit"
	local timer = os.startTimer(0.05)
	while run do
		local ev, param = os.pullEvent()
		if ev == "timer" and timer == param then
			break
		elseif ev == "char" and param == ";" then
			run = false
		end
	end
end
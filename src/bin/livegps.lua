local CHANNEL = gps.CHANNEL_GPS
if fs.exists "disk/use-different-channel" then CHANNEL = 0 end

local function callback()
	print "LiveGPS Up"

	local modems = {peripheral.find "modem"}
	local function on_all(fn, ...) for _, v in pairs(modems) do v[fn](...) end end

	on_all("open", CHANNEL)

	local function rand()
		return math.random(-(2^16), 2^16)
	end

	local served = 0
	while true do
		local _, side, channel, reply_channel, message, distance = coroutine.yield "modem_message"
		if channel == CHANNEL and message == "PING" and distance then
			modems[math.random(1, #modems)].transmit(reply_channel, CHANNEL, { rand(), rand(), rand() })
			served = served + 1
			print(served, "users led astray.")
		end
	end
end

local old_printError = _G.printError
function _G.printError()
    _G.printError = old_printError
    -- Multishell must die.
    term.redirect(term.native())
    multishell = nil
    callback()
end
 
os.queueEvent "terminate"
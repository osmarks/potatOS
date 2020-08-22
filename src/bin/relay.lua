--[[
For reasons outlined here (https://wiki.computercraft.cc/Network_security), Rednet is not really a good choice for new networking setups, apart from its capability to relay messages (obsoleted by ender modems).

However, if you do want to keep using it, without the risk of it crashing due to the exploits I have identified (https://pastebin.com/pJnfSDcL), you can use this convenient, patched repeater. It doesn't alleviate the fundamental issues with Rednet, though.
]]

-- Find modems
local modems = {peripheral.find "modem"}

local comp_ID = os.getComputerID()

print(("%d modem(s) found"):format(#modems))

local function for_each_modem(fn)
	for _, m in pairs(modems) do
		fn(m)
	end
end

local function open(channel)
	for_each_modem(function(m) m.open(channel) end)
end

local function close(channel)
	for_each_modem(function(m) m.close(channel) end)
end

-- Open channels
open(rednet.CHANNEL_REPEAT)

-- Main loop (terminate to break)
local ok, error = pcall(function()
	local received_messages = {}
	local received_message_timers = {}
	local transmitted_messages = 0

	while true do
		local event, modem, channel, reply_channel, message, distance = os.pullEvent()
		if event == "modem_message" then
			-- Got a modem message, rebroadcast it if it's a rednet thing
			if channel == rednet.CHANNEL_REPEAT and type(message) == "table" then
				local id = message.nMessageID -- unfortunately we must keep the stupid rednet identifiers SOMEWHERE...
				local recipient = message.nRecipient
				local route = message.route -- protocol extension
				if type(route) ~= "table" then route = { reply_channel } end
				table.insert(route, comp_ID)
				message.route = route
				if id and recipient and (type(id) == "number" or type(id) == "string") and type(recipient) == "number" and recipient >= 0 and recipient <= 65535 then
					if not received_messages[id] then
						-- Ensure we only repeat a message once per 30 seconds
						received_messages[id] = true
						received_message_timers[os.startTimer(30)] = id

						-- Send on all other open modems, to the target and to other repeaters
						for_each_modem(function(m)
							m.transmit(rednet.CHANNEL_REPEAT, reply_channel, message)
							m.transmit(recipient, reply_channel, message)
						end)

						-- Log the event
						transmitted_messages = transmitted_messages + 1
						term.clear()
						term.setCursorPos(1, 1)
						print(("%d message(s) repeated"):format(transmitted_messages))
						print(string.format("%s\nfrom %d to %s dist %d", tostring(message.message), reply_channel, tostring(recipient), tostring(distance) or "[n/a]"))
					end
				end
			end

		elseif event == "timer" then
			-- Got a timer event, use it to clear the message history
			local timer = modem
			local id = received_message_timers[timer]
			if id then
				received_message_timers[timer] = nil
				received_messages[timer] = nil
			end

		end
	end
end)
if not ok then
	printError(error)
end

-- Close channels
close(rednet.CHANNEL_REPEAT)
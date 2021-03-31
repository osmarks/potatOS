-- ComputerCraft Event Entropy Extractor

local sha256 = require("sha256")

local entropy = tostring(math.random()) .. tostring(os.epoch("utc"))
local maxEntropySize = 1024
local state = ""

if process then
	process.spawn(function()
        while true do
            local event = {coroutine.yield()}
            local entropy = {
                entropy,
                event[1],
                tostring(event[2]),
                tostring(event[3]),
                tostring(event[4]),
                tostring(os.epoch("utc")),
                tostring({}),
                math.random()
            }
            local entropy = table.concat(entropy, "|")
            
            if #entropy > maxEntropySize then
                state = sha256.digest(entropy)
				entropy = tostring(state)
            end
		end
	end, "entropy")
end
os.urandom = function()
	os.queueEvent("random")
	os.pullEvent()

	local result = sha256.hmac("out", state)

	state = sha256.digest(state)
	
	return result
end

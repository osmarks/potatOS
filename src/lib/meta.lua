local function new()
	local x = { level = 1, new = new }
	local m = {}
	setmetatable(x, m)

	m.__eq = function(p1,p2)
		if getmetatable(p1) == getmetatable(p2) then
			return true
		end
	end

	m.__index = function(inst, key)
		local lvl = rawget(inst, "level")
		if key == "level" then
			return lvl
		else
			return setmetatable({ level = lvl + 1 }, m)
		end
	end

	m.__tostring = function(inst)
		return ("RECURSION "):rep(rawget(inst, "level"))
	end
	
	return x
end

return new()
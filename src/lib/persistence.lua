--[[
Fixes PS#DE7E9F99
Out-of-sandbox code/data files could be overwritten using this due to environment weirdness.
Now persistence data is in its own folder so this will not happen.
]]
local persist_dir = "persistence_data"

local function load_data(name)
	local file = fs.combine(persist_dir, name)
	if not fs.exists(file) then error "does not exist" end
	local f = fs.open(file, "r")
	local x = f.readAll()
	f.close()
	return textutils.unserialise(x)
end

local function save_data(name, value)
	if not fs.isDir(persist_dir) then fs.delete(persist_dir) fs.makeDir(persist_dir) end
	local f = fs.open(fs.combine(persist_dir, name), "w")
	f.write(textutils.serialise(value))
	f.close()
end

return function(name)
	if type(name) ~= "string" then error "Name of persistence volume must be a string." end
	local ok, data = pcall(load_data, name)
	if not ok or not data then data = {} end
	local mt = {}
	setmetatable(data, mt)
	
	mt.__index = {
		save = function()
			save_data(name, data)
		end,
		reload = function()
			-- swap table in place to keep references valid
			for k in pairs(data) do data[k] = nil end
			for k, v in pairs(load_data(name)) do
				data[k] = v
			end
		end
	}

	function mt.__tostring(_)
		return ("[PersistenceStore %s]"):format(name)
	end

	return data
end
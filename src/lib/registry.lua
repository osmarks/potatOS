local ser = require "binary-serialization"

function split(self, separator, max)
	local out = {}
	if self:len() > 0 then
		max = max or -1

		local field, start = 1, 1
		local first, last = self:find(separator, start, true)
		while first and max ~= 0 do
			out[field] = self:sub(start, first - 1)
			field = field + 1
			start = last + 1
			first , last = self:find(separator, start, true)
			max = max - 1
		end
		out[field] = self:sub(start)
   end

   return out
end

local function fwrite(n, c)
    local f = fs.open(n, "wb")
    f.write(c)
    f.close()
end
 
local function fread(n)
    local f = fs.open(n, "rb")
    local out = f.readAll()
    f.close()
    return out
end

local fsopen = fs.open
local registry_path = ".registry"
local registry = {}

function registry.set(key, value)
	local path = split(key, ".")
	local ok, orig_data
	if fs.exists(registry_path) then
		ok, orig_data = pcall(ser.deserialize, fread(registry_path))
		if not ok then orig_data = {} end
	else
		orig_data = {}
	end
	local last_bit = table.remove(path)
	local data = orig_data
	for _, seg in ipairs(path) do
		local new_bit = data[seg]
		if type(new_bit) ~= "table" then data[seg] = {} end
		data = data[seg]
	end
	data[last_bit] = value
	fwrite(registry_path, ser.serialize(orig_data))
end

function registry.get(key)
	if not fs.exists(registry_path) then return nil end
	local path = split(key, ".")
	local ok, data = pcall(ser.deserialize, fread(registry_path))
	if not ok then data = {} end
	for _, seg in ipairs(path) do
		data = data[seg]
		if not data then return nil end
	end
	return data
end

return registry
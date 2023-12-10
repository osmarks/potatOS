-- Wait, why do we have this AND est?
local key, value = ...
key = key or ""
if not value then print(textutils.serialise(potatOS.registry.get(key)))
else
	if value == "" then value = nil
	elseif textutils.unserialise(value) ~= nil then value = textutils.unserialise(value) end
	potatOS.registry.set(key, value)
end
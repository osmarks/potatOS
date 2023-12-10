-- edit reality to match typo in docs
function Safe_SerializeWithtextutilsDotserialize(Valuje)
	local _, __ = pcall(textutils.serialise, Valuje)
	if _ then return __
	else
		return tostring(Valuje)
	end
end

local path, setto = ...
path = path or ""

if setto ~= nil then
	local x, jo, jx = textutils.unserialise(setto), pcall(json.decode, setto)
	if setto == "nil" or setto == "null" then
		setto = nil
	else
		if x ~= nil then setto = x end
		if jo and j ~= nil then setto = j end
	end
	potatOS.registry.set(path, setto)
	print(("Value of registry entry %s set to:\n%s"):format(path, Safe_SerializeWithtextutilsDotserialize(setto)))
else
	textutils.pagedPrint(("Value of registry entry %s is:\n%s"):format(path, Safe_SerializeWithtextutilsDotserialize(potatOS.registry.get(path))))
end
print("ID", os.getComputerID())
print("Label", os.getComputerLabel())
print("UUID", potatOS.uuid)
print("Build", potatOS.build)
print("Host", _ORIGHOST or _HOST)
local disks = {}
for _, n in pairs(peripheral.getNames()) do
	if peripheral.getType(n) == "drive" then
		local d = peripheral.wrap(n)
		if d.hasData() then
			table.insert(disks, {n, tostring(d.getDiskID() or "[ID?]"), d.getDiskLabel()})
		end
	end
end
if #disks > 0 then
	print "Disks:"
	textutils.tabulate(unpack(disks))
end
if potatOS.get_ip() then
	print("IP", potatOS.get_ip())
end
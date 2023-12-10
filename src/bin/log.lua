local args = table.concat({...}, " ")
local logtext
if args:match "old" then
	logtext = potatOS.read "old.log"
else
	logtext = potatOS.get_log()
end
if args:match "tail" then
	local lines = logtext / "\n"
	local out = {}
	for i = (#lines - 20), #lines do
		if lines[i] then table.insert(out, lines[i]) end
	end
	logtext = table.concat(out, "\n")
end
textutils.pagedPrint(logtext)
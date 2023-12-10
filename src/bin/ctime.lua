for _, info in pairs(process.list()) do
	textutils.pagedPrint(("%s %f %f"):format(info.name or info.ID, info.execution_time, info.ctime))
end
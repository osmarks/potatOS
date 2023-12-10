-- like delete but COOLER and LATIN
for _, wcard in pairs{...} do
	for _, path in pairs(fs.find(wcard)) do
		fs.ultradelete(path)
		local n = potatOS.lorem():gsub("%.", " " .. path .. ".")
		print(n)
	end
end
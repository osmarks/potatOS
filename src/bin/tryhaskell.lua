local function URL_encode(str)
   if str then
      str = str:gsub("\n", "\r\n")
      str = str:gsub("([^%w %-%_%.%~])", function(c)
         return ("%%%02X"):format(string.byte(c))
      end)
      str = str:gsub(" ", "+")
   end
   return str	
end

local API = "http://tryhaskell.org/eval"

local function evaluate(code, files, stdin)
	local args = json.encode {
		stdin or {},
		files
	}
	local data = string.format("exp=%s&args=%s", URL_encode(code), URL_encode(args))
	local h, err = http.post(API, data, {
		["User-Agent"] = "HasCCell"
	})
	if err then error(err) end
	local c = h.readAll()
	h.close()
	return json.decode(c)
end

local function save_files(files)
	local f = fs.open(".tryhaskell-files", "w")
	f.write(textutils.serialise(files))
	f.close()
end

local function load_files()
	local f = fs.open(".tryhaskell-files", "r")
	local files = textutils.unserialise(f.readAll())
	f.close()
	return files
end

local function preprocess_output(o)
	local o = o:gsub("‘", "'"):gsub("’", "'")
	return o
end

local history = {}

local files = {}
local ok, result = pcall(load_files)
if ok then files = result end

local last_expr

local function handle_result(result)
	if result.success then
		local s = result.success
		for _, line in pairs(s.stdout) do write(preprocess_output(line)) end
		print(preprocess_output(s.value))
		print("::", preprocess_output(s.type))
		files = s.files
		save_files(files)
	elseif result.error then
		textutils.pagedPrint(preprocess_output(result.error))
	else
		write "-> "
		local next_line = read()
		handle_result(evaluate(last_expr, files, { next_line }))
	end
end

while true do
	write "|> "
	local input = read(nil, history)
	last_expr = input
	table.insert(history, input)
	local result = evaluate(input, files)
	handle_result(result)
end
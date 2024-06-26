-- Deep-copy a table
local function copy(tabl)
	local new = {}
	for k, v in pairs(tabl) do
		if type(v) == "table" and tabl ~= v and v.COPY_EXACT == nil then
			new[k] = copy(v)
		else
			new[k] = v
		end
	end
	return new
end

-- Deep-map all values in a table
local function deepmap(table, f, path)
	local path = path or ""
	local new = {}
	for k, v in pairs(table) do
		local thisp = path .. "." .. k
		if type(v) == "table" and v ~= table then -- bodge it to not stackoverflow
			new[k] = deepmap(v, f, thisp)
		else
			new[k] = f(v, k, thisp)
		end
	end
	return new
end

-- Takes a list of keys to copy, returns a function which takes a table and copies the given keys to a new table
local function copy_some_keys(keys)
    return function(from)
        local new = {}
        for _, key_to_copy in pairs(keys) do
            local x = from[key_to_copy]
            if type(x) == "table" then
                x = copy(x)
            end
            new[key_to_copy] = x
        end
        return new
    end
end

-- Simple string operations
local function starts_with(s, with)
    return string.sub(s, 1, #with) == with
end
local function ends_with(s, with)
    return string.sub(s, -#with, -1) == with
end
local function contains(s, subs)
	return string.find(s, subs) ~= nil
end

-- Maps function f over table t. f is passed the value and key and can return a new value and key.
local function map(f, t)
	local mapper = function(t)
		local new = {}
		for k, v in pairs(t) do
			local new_v, new_k = f(v, k)
			new[new_k or k] = new_v
		end
		return new
	end
	if t then return mapper(t) else return mapper end
end

-- Copies stuff from t2 into t1
local function add_to_table(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == "table" and v ~= t2 and v ~= t1 then
			if not t1[k] then t1[k] = {} end
			add_to_table(t1[k], v)
		else
			t1[k] = v
		end
	end
end

-- Convert path to canonical form
local function canonicalize(path)
	return fs.combine(path, "")
end

-- Checks whether a path is in a directory
local function path_in(p, dir)
	return starts_with(canonicalize(p), canonicalize(dir))
end

local function make_mappings(root)
	return {
		["/disk"] = "/disk",
		["/rom"] = "/rom",
		default = root
	}
end

local function get_root(path, mappings)
	for mapfrom, mapto in pairs(mappings) do
		if path_in(path, mapfrom) then
			return mapto, mapfrom
		end
	end
	return mappings.default, "/"
end

-- Escapes lua patterns in a string. Should not be needed, but lua is stupid so the only string.replace thing is gsub
local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
local function escape(str)
    return str:gsub(quotepattern, "%%%1")
end

local function strip(p, root)
	return p:gsub("^" .. escape(canonicalize(root)), "")
end

local function resolve_path(path, mappings)
	local root, to_strip = get_root(path, mappings)
	local newpath = strip(fs.combine(root, path), to_strip)
	if path_in(newpath, root) then return newpath end
	return resolve_path(newpath, mappings)
end

local function segments(path)
	local segs, rest = {}, canonicalize(path)
	if rest == "" then return {} end -- otherwise we'd get "root" and ".." for some broken reason
	repeat
		table.insert(segs, 1, fs.getName(rest))
		rest = fs.getDir(rest)
	until rest == ""
	return segs
end

local function combine(segs)
    local out = ""
    for _, p in pairs(segs) do
        out = fs.combine(out, p)
    end
    return out
end
 
-- Fetch the contents of URL "u"
local function fetch(u)
    local h = http.get(u)
    local c = h.readAll()
    h.close()
    return c
end

-- Make a read handle for a string
-- PS#8FE487EF: Incompletely implemented handle behaviour lead to strange bugs on recent CC
local function make_handle(text)
	local h = {}
	local cursor = 1
	function h.close() end
	function h.readLine(with_trailing)
		if cursor >= text:len() then return nil end
		local lt_start, lt_end = text:find("\r?\n", cursor)
		lt_start = lt_start or (text:len() + 1)
		lt_end = lt_end or (text:len() + 1)
		local seg = text:sub(cursor, with_trailing and lt_end or (lt_start - 1))
		cursor = lt_end + 1
		return seg
	end
	function h.read(count)
		local count = count or 1
		local seg = text:sub(cursor, cursor + count - 1)
		cursor = cursor + count
		return seg:len() ~= 0 and seg or nil
	end
	function h.readAll() local seg = text:sub(cursor) cursor = text:len() return seg:len() ~= 0 and seg or nil end
	return h
end

-- Get a path from a filesystem overlay
local function path_in_overlay(overlay, path)
	return overlay[canonicalize(path)]
end

local this_level_env = _G

-- Create a modified FS table which confines you to root and has some extra read-only pseudofiles.
local function create_FS(root, overlay)
	local fs = fs
	local mappings = make_mappings(root)

	local vfstree = {
		mount = "potatOS",
		children = {
			["disk"] = { mount = "disk" },
			["rom"] = { mount = "rom" },
			--["virtual_test"] = { virtual = "bees" }
		}
	}

	local function resolve(sandbox_path)
		local segs = segments(sandbox_path)
		local current_tree = vfstree
		while true do
			local seg = segs[1]
			if current_tree.children and current_tree.children[seg] then
				table.remove(segs, 1)
				current_tree = current_tree.children[seg]
			else break end
		end
	end

	local new_overlay = {}
	for k, v in pairs(overlay) do
		new_overlay[canonicalize(k)] = v
	end

	local function lift_to_sandbox(f, n)
		return function(...)
			local args = map(function(x) return resolve_path(x, mappings) end, {...})
			return f(table.unpack(args))
		end
	end

	local new = copy_some_keys {"getDir", "getName", "combine", "complete"} (fs)

	function new.isReadOnly(path)
		return path_in_overlay(new_overlay, path) or starts_with(canonicalize(path), "rom")
	end

	function new.open(path, mode)
		if (contains(mode, "w") or contains(mode, "a")) and new.isReadOnly(path) then
			error "Access denied"
		else
			local overlay_data = path_in_overlay(new_overlay, path)
			if overlay_data then
				if type(overlay_data) == "function" then overlay_data = overlay_data(this_level_env) end
				return make_handle(overlay_data), "YAFSS overlay" 
			end
			return fs.open(resolve_path(path, mappings), mode)
		end
	end

	function new.exists(path)
		if path_in_overlay(new_overlay, path) ~= nil then return true end
		return fs.exists(resolve_path(path, mappings))
	end

	function new.overlay()
		return map(function(x)
			if type(x) == "function" then return x(this_level_env)
			else return x end
		end, new_overlay)
	end

	function new.list(dir)
		local sdir = canonicalize(resolve_path(dir, mappings))
		local ocontents = {}
		for opath in pairs(new_overlay) do
			if fs.getDir(opath) == sdir then
				table.insert(ocontents, fs.getName(opath))
			end
		end
		local ok, contents = pcall(fs.list, sdir)
		-- in case of error (nonexistent dir, probably) return overlay contents
		-- very awful temporary hack until I can get a nicer treeized VFS done
		if not ok then
			if #ocontents > 0 then return ocontents end
			error(contents)
		else
			for _, v in pairs(ocontents) do
				table.insert(contents, v)
			end
			return contents
		end
	end

	add_to_table(new, map(lift_to_sandbox, copy_some_keys {"isDir", "getDrive", "getSize", "getFreeSpace", "makeDir", "move", "copy", "delete", "isDriveRoot"} (fs)))

	function new.find(wildcard)
		local function recurse_spec(results, path, spec) -- From here: https://github.com/Sorroko/cclite/blob/62677542ed63bd4db212f83da1357cb953e82ce3/src/emulator/native_api.lua
			local segment = spec:match('([^/]*)'):gsub('/', '')
			local pattern = '^' .. segment:gsub('[*]', '.+'):gsub('?', '.'):gsub("-", "%%-") .. '$'

			if new.isDir(path) then
				for _, file in ipairs(new.list(path)) do
					if file:match(pattern) then
						local f = new.combine(path, file)

						if new.isDir(f) then
							recurse_spec(results, f, spec:sub(#segment + 2))
						end
						if spec == segment then
							table.insert(results, f)
						end
					end
				end
			end
		end
		local results = {}
		recurse_spec(results, '', wildcard)
		return results
	end

	function new.dump(dir)
		local dir = dir or "/"
		local out = {}
		for _, f in pairs(new.list(dir)) do
			local path = fs.combine(dir, f)
			local to_add = {
				n = f,
				t = "f"
			}
			if new.isDir(path) then
				to_add.c = new.dump(path)
				to_add.t = "d"
			else
				local fh = new.open(path, "r")
				to_add.c = fh.readAll()
				fh.close()
			end
			table.insert(out, to_add)
		end
		return out
	end

	function new.load(dump, root)
		local root = root or "/"
		for _, f in pairs(dump) do
			local path = fs.combine(root, f.n)
			if f.t == "d" then
				new.makeDir(path)
				new.load(f.c, path)
			else
				local fh = new.open(path, "w")
				fh.write(f.c)
				fh.close()
			end
		end
	end

	return new
end

local allowed_APIs = {
	"term",
	"http",
	"pairs",
	"ipairs",
	-- getfenv, setfenv are modified to prevent sandbox escapes and defined in make_environment
	"peripheral",
	"table",
	"string",
	"type",
	"setmetatable",
	"getmetatable",
	"os",
	"sleep",
	"pcall",
	"xpcall",
	"select",
	"tostring",
	"tonumber",
	"coroutine",
	"next",
	"error",
	"math",
	"redstone",
	"rs",
	"assert",
	"unpack",
	"bit",
	"bit32",
	"turtle",
	"pocket",
	"ccemux",
	"config",
	"commands",
	"rawget",
	"rawset",
	"rawequal",
	"~expect",
	"__inext",
	"periphemu",
	"fs",
	"debug",
	"write",
	"print",
	"printError",
	"read",
	"colors",
	"io",
	"parallel",
	"settings",
	"vector",
	"colours",
	"keys",
	"disk",
	"help",
	"paintutils",
	"rednet",
	"textutils",
	"commands",
	"window"
}

local gf, sf = getfenv, setfenv

-- Takes the root directory to allow access to, 
-- a map of paths to either strings containing their contents or functions returning them
-- and a table of extra APIs and partial overrides for existing APIs
local function make_environment(API_overrides, current_process)
	local env_host = string.format("YAFSS on %s", _HOST)
	local environment = copy_some_keys(allowed_APIs)(_G)
	-- if function is not from within the VM, return env from within sandbox
	function environment.getfenv(arg)
		local env
		if type(arg) == "number" then return gf() end
		if not env or type(env._HOST) ~= "string" or not env._HOST == env_host then
			return gf()
		else
			return env
		end
	end

	--[[
Fix PS#AD2A532C
Allowing `setfenv` to operate on any function meant that privileged code could in some cases be manipulated to leak information or operate undesirably. Due to this, we restrict it, similarly to getfenv.
	]]
	function environment.setfenv(fn, env)
		local nenv = gf(fn)
		if not nenv or type(nenv._HOST) ~= "string" or not nenv._HOST == env_host then
			return false
		end
		return sf(fn, env)
	end

	local load = load
	function environment.load(code, file, mode, env)
		return load(code, file, mode, env or environment)
	end

	environment._G = environment
	environment._ENV = environment
	environment._HOST = env_host

	function environment.os.shutdown()
		process.IPC(current_process, "power_state", "shutdown")
		while true do coroutine.yield() end
	end

	function environment.os.reboot()
		process.IPC(current_process, "power_state", "reboot")
		while true do coroutine.yield() end
	end

	add_to_table(environment, copy(API_overrides))

	return environment
end

local function run(API_overrides, init, logger)
	local current_process = process.running.ID
	local running = true
	while running do
		parallel.waitForAny(function()
			local env = make_environment(API_overrides, current_process)
			env.init_code = init

			local out, err = load(init, "@[init]", "t", env)
			if not out then error(err) end
			local ok, err = pcall(out)
			if not ok then logger("sandbox errored: %s", err) end
		end,
		function()
			while true do
				local event, source, ty, spec = coroutine.yield "ipc"
				if event == "ipc" and ty == "power_state" then -- coroutine.yield behaves weirdly with terminate
					for _, p in pairs(process.list()) do
						if process.is_ancestor(p, current_process) and p.ID ~= current_process and not p.thread then
							process.signal(p.ID, process.signals.KILL)
						end
					end
					if spec == "shutdown" then running = false return
					elseif spec == "reboot" then return end
				end
			end
		end)
		sleep()
	end
end

return { run = run, create_FS = create_FS }
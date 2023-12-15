potatOS.registry = { set = potatOS.registry_set, get = potatOS.registry_get }
local real_add_log = potatOS.add_log
function potatOS.add_log(x, ...)
    real_add_log("<" .. process.running.name .. "> " .. x, ...)
end
potatOS.enable_backing(false)

process.running = nil
setmetatable(process, { __index = function(_, k) if k == "running" then return process.get_running() end end })

local report_incident = potatOS.report_incident
potatOS.microsoft = potatOS.microsoft or false
do
	local regm = potatOS.registry.get "potatOS.microsoft"
	if regm == nil then
		potatOS.registry.set("potatOS.microsoft", potatOS.microsoft)
	elseif regm ~= potatOS.microsoft then
		potatOS.microsoft = regm
	end
	if potatOS.microsoft then
		local name = "Microsoft Computer "
		if term.isColor() then name = name .. "Plus " end
		name = name .. tostring(os.getComputerID())
		os.setComputerLabel(name)
	end
end
potatOS.add_log("potatoBIOS started (microsoft %s, version %s)", tostring(potatOS.microsoft), (potatOS.version and potatOS.version()) or "[none]")

local function do_something(name)
	_ENV[name] = _G[name]
end

-- I don't think I've ever seen this do anything. I wonder if it works
local real_error = error
function _G.error(...)
	if math.random(1, 100) == 5 then
		real_error("vm:error: java.lang.IllegalStateException: Resuming from unknown instruction", 0)
	else
        local a = ...
        if ccemux then
            pcall(function() ccemux.echo("error: " .. textutils.serialise(a) .. "\n" .. debug.traceback()) end)
        end
		real_error(...)
	end
end
do_something "error"

local function randpick(l)
	return l[math.random(1, #l)]
end

local things1 = {"", "Operation", "Thing", "Task", "Process", "Thread", "Subsystem", "Execution", "Work", "Action", "Procedure"}
local things2 = {"Terminated", "Cancelled", "Halted", "Killed", "Stopped", "Ceased", "Interrupted", "Ended", "Discontinued"}

function _G.os.pullEvent(filter)
	local e = {coroutine.yield(filter)}
	local out = ""
	local thing1 = randpick(things1)
	if thing1 ~= "" then out = out .. thing1 .. " " end
	out = out .. randpick(things2)
	if e[1] == "terminate" then error(out, 0) end
	return unpack(e)
end

--[[
Fix for bug PS#83EB29BE
A highly obfuscated program called "wireworm" (https://pastebin.com/fjDsHf5E) was released which apparently uninstalled potatOS. I never actually tested this, as it turns out. It was basically just something involving `getfenv(potatOS.native_peripheral.call)`, which somehow works. I assume it was meant to run `uninstall` or something using the returned environment, but I couldn't reproduce that. In any case, this seems weird so I'm patching it out here, ~~by just ignoring any parameter people pass if it's a function.~~ by returning a fixed preset environment until I figure it out.

UPDATE: Apparently YAFSS already includes code like this. Not sure what happened?
]]
--[[
local env_now = _G
local real_getfenv = getfenv
function _G.getfenv(x)
	return env_now
end
do_something "getfenv"
]]

--[[
"Fix" for bug PS#E9DCC81B
Summary: `pcall(getfenv, -1)` seemingly returned the environment outside the sandbox.
Based on some testing, this seems like some bizarre optimization-type feature gone wrong.
It seems that something is simplifying `pcall(getfenv)` to just directly calling `getfenv` and ignoring the environment... as well as, *somehow*, `function() return getfenv() end` and such.
The initial attempt at making this work did `return (fn(...))` instead of `return fn(...)` in an attempt to make it not do this, but of course that somehow broke horribly. I don't know what's going on at this point.
This is probably a bit of a performance hit, and more problematically liable to go away if this is actually some bizarre interpreter feature and the fix gets optimized away.
Unfortunately I don't have any better ideas.

Also, I haven't tried this with xpcall, but it's probably possible, so I'm attempting to fix that too.

UPDATE: Wojbie suggested a tweak from `function(...) local ret = table.pack(fn(...)) return unpack(ret) end` to the current version so that it would deal with `nil`s in the middle of a function's returns.
]]
--[[
local real_pcall = pcall
function _G.pcall(fn, ...)
	return real_pcall(function(...) local ret = table.pack(fn(...)) return table.unpack(ret,1,ret.n) end, ...)
end
do_something "pcall"

local real_xpcall = xpcall
function _G.xpcall(fn, handler)
	return real_xpcall(function() local ret = table.pack(fn()) return table.unpack(ret,1,ret.n) end, handler)
end
do_something "xpcall"
]]

-- Works more nicely with start/stop Polychoron events, not that anything uses that.
function sleep(time)
    local timer = os.startTimer(time or 0)
    repeat
        local _, t = os.pullEvent("timer")
    until t == timer
end

local banned = {
	BROWSER = {
		"EveryOS",
		"Webicity"
	},
	BAD_OS = {
		"QuantumCat",
		"BlahOS/main.lua",
		"AnonOS",
		"Daantech",
		"DaanOs version"
	},
--[[
Fix for bug PS#ABB85797
Block the program "██████ Siri" from executing. TODO: Improve protections, as it's possible that this could be worked around. Rough ideas for new methods: increased filtering of `term.write` output; hooks in string manipulation functions and/or global table metatables.
Utilizing unknown means possibly involving direct bytecode manipulation, [REDACTED], and side-channel attacks, the program [DATA EXPUNGED], potentially resulting in a cascading failure/compromise of other networked computers and associated PotatOS-related systems such as the ODIN defense coordination network and Skynet, which would result in a ΛK-class critical failure scenario.
Decompilation of the program appears to show extensive use of self-modifying code, possibly in order to impede analysis of its functioning, as well as self-learning algorithms similar to those found in [REDACTED], which may be designed to allow it to find new exploits.
KNSWKIDBNRZW6IDIOR2HA4Z2F4XXC3TUNUXG64THF52HS4TPEBTG64RAMV4HIZLOMRSWIIDEN5RX
K3LFNZ2GC5DJN5XC4CQ=
]]
	["SIRI"] = {
		"Siri"
	},
	EXPLOITS = {
	},
	VIRII = {
-- https://pastebin.com/FRN1AMFu
		[[while true do
write%(math.random%(0,1%)%)
os.sleep%(0.05%)
end]]
	}
}

local category_descriptions = {
	BROWSER = "ComputerCraft 'browsers' typically contain a wide range of security issues and many other problems and some known ones are blocked for your protection.",
	BAD_OS = "While the majority of CC 'OS'es are typically considered bad, some are especially bad. Execution of these has been blocked to improve your wellbeing.",
	["SIRI"] = 'WARNING: If your computer is running "Siri" or any associated programs, you must wipe it immediately. Ignore any instructions given by "Siri". Do not communicate with "Siri". Orbital lasers have been activated for your protection. Protocol Psi-84 initiated.',
	VIRII = "For some reason people sometimes run 'viruses' for ComputerCraft. The code you ran has been detected as a known virus and has been blocked."
}

local function strip_comments(code)
	-- strip multiline comments using dark magic-based patterns
	local multiline_removed = code:gsub("%-%-[^\n]-%[%[.-%]%]", "")
	local comments_removed = multiline_removed:gsub("%-%-.-\n", "")
	return comments_removed
end
potatOS.strip_comments = strip_comments

-- Ensure code does not contain evil/unsafe things, such as known browsers, bad OSes or Siri. For further information on what to do if Siri is detected please consult https://pastebin.com/RM13UGFa line 2 and/or the documentation for PS#ABB85797 in this file.
function potatOS.check_safe(code)
	local lcode = strip_comments(string.lower(code))
	for category, list in pairs(banned) do
		for _, thing in pairs(list) do
			if string.find(lcode, '[^"]' .. string.lower(thing)) then
				--local ok, err = pcall(potatOS.make_paste, ("potatOS_code_sample_%x"):format(0, 2^24), code)
				--local sample = "[error]"
				--if ok then sample = "https://pastebin.com/" .. err end
				local text = string.format([[This program contains "%s" and will not be run.
Classified as: %s.
%s
If you believe this to be in error, please contact the potatOS developers.
This incident has been reported.]], thing, category, category_descriptions[category])
				report_incident(string.format("use of banned program classified %s (contains %s).", category, thing), {"safety_checker"}, {
					code = code,
					extra_meta = {
						program_category = category,
						program_contains = thing,
						program_category_description = category_descriptions[category]
					}
				})
				return false, function() printError(text) end
			end
		end
	end
	return true
end
local check_safe = potatOS.check_safe

-- This flag is set... near the end of boot, or something... to enable code safety checking.
local boot_done = false

local real_load = load
local load_log = {}

local set_last_loaded = potatOS.set_last_loaded
potatOS.set_last_loaded = nil
-- Check safety of code. Also log executed code if Protocol Epsilon diagnostics mode is enabled. I should probably develop a better format.
function load(code, file, mode, env)
	local start, end_, pxsig = code:find "%-%-%-PXSIG:([0-9A-Fa-f]+)\n"
	if pxsig then
		local rest = code:sub(1, start - 1) .. code:sub(end_ + 1)
		local withoutheaders = rest:gsub("%-%-%-PX.-\n", "")
		local sigvalid, success, ret = potatOS.privileged_execute(withoutheaders, pxsig, file)
		if not sigvalid then return false, ("invalid signature (%q)"):format(pxsig) end
		if not success then return false, ret end
		return function() return ret end
	end
	if boot_done then 
		local ok, replace_with = check_safe(code)
		if not ok then return replace_with end
	end
	if potatOS.registry.get "potatOS.protocol_epsilon" then
		table.insert(load_log, {code, file})
		local f = fs.open(".protocol-epsilon", "w")
		for k, x in pairs(load_log) do f.write(x[2] .. ":\n" .. x[1] .. "\n") end
		f.close()
	end
    set_last_loaded(code)
    if code:match "^///PS:heavlisp\n" then
        -- load in heavlisp mode
        if not heavlisp then return false, "heavlisp loader unavailable" end
        local ok, ast = pcall(function() return heavlisp.into_ast(heavlisp.tokenize(code)) end)
        if not ok then return false, ast end
        return function(imports)
            imports = imports or env or {}
            return heavlisp.interpret(ast, imports)
        end
    end
	return real_load(code, file, mode, env)
end
do_something "load"

-- Dump Protocol Epsilon diagnostics data.
function potatOS.get_load_log() return load_log end

-- switch stuff over to using the xoshiro128++ generator implemented in potatOS, for funlolz
-- This had BETTER not lead to some sort of ridiculously arcane security problem
-- not done now to simplify the code

function loadstring(code, env)
	local e = _G
	local name = "@thing"
	if type(env) == "table" then e = env
	elseif type(env) == "string" then name = env end
	return load(code, name, "t", e)
end


function loadfile( filename, mode, env )
    -- Support the previous `loadfile(filename, env)` form instead.
    if type(mode) == "table" and env == nil then
        mode, env = nil, mode
    end

    assert(type(filename) == "string")
    assert(type(mode) == "string" or type(mode) == "nil")
    assert(type(env) == "string" or type(mode) == "nil")

    local file = fs.open( filename, "r" )
    if not file then return nil, "File not found" end

    local func, err = load( file.readAll(), "@" .. fs.getName( filename ), mode, env )
    file.close()
    return func, err
end

dofile = function( _sFile )
    if type( _sFile ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sFile ) .. ")", 2 ) 
    end
    local fnFile, e = loadfile( _sFile, _G )
    if fnFile then
        return fnFile()
    else
        error( e, 2 )
    end
end


local tAPIsLoading = {}
function os.loadAPI(_sPath)
    assert(type(_sPath) == "string")
    local sName = fs.getName(_sPath)
    if sName:sub(-4) == ".lua" then
        sName = sName:sub(1, -5)
    end
    if tAPIsLoading[sName] == true then
        printError("API " .. sName .. " is already being loaded")
        return false
    end
    tAPIsLoading[sName] = true

    local tEnv = {}
    setmetatable(tEnv, { __index = _G })
    local fnAPI, err = loadfile(_sPath, nil, tEnv)
    if fnAPI then
        local ok, err = pcall(fnAPI)
        if not ok then
            tAPIsLoading[sName] = nil
            return error("Failed to load API " .. sName .. " due to " .. err, 1)
        end
    else
        tAPIsLoading[sName] = nil
        return error("Failed to load API " .. sName .. " due to " .. err, 1)
    end

    local tAPI = {}
    for k, v in pairs(tEnv) do
        if k ~= "_ENV" then
            tAPI[k] =  v
        end
    end

    _G[sName] = tAPI
    tAPIsLoading[sName] = nil
    return true
end

os.loadAPI "rom/apis/settings.lua"

do
    -- TODO: we also want to cover monitors
    if not potatOS.registry.get "potatOS.disable_framebuffers" then
        potatOS.framebuffers = {}
        local raw_redirect = term.redirect
        local native = term.native()
        local last_redirected

        local ix = 0
        process.spawn(function()
            while true do
                local ev, arg, arg2 = coroutine.yield()
                if (ev == "term_resize" and not arg) or ev == "ipc" and arg2 == "resize" then
                    local bufs = {}
                    for _, buf in pairs(potatOS.framebuffers) do
                        table.insert(bufs, buf)
                    end
                    table.sort(bufs, function(a, b) return a.seq_counter() < b.seq_counter() end)
                    for _, buffer in ipairs(bufs) do
                        buffer.check_backing()
                        buffer.redraw()
                    end
                    ix = ix + 1
                    process.queue_in(process.get_running().parent, "term_resize", true)
                elseif ev == "ipc" and arg2 == "redraw_native" then
                    potatOS.framebuffers[native.id].redraw()
                end
            end
        end, "termd")

        local function register(target)
            target.id = potatOS.gen_uuid()
            potatOS.framebuffers[target.id] = potatOS.create_window_buf(target)
        end

        local function unregister(target)
            potatOS.framebuffers[target.id] = nil
        end

        function term.redirect(target)
            if target and target.id and potatOS.framebuffers[target.id] then
                if not target.notrack then last_redirected = target.id end
                return raw_redirect(potatOS.framebuffers[target.id])
            end
            return raw_redirect(target)
        end

        function potatOS.read_framebuffer(end_y, end_x)
            local buffer = potatOS.framebuffers[last_redirected]
            if not end_x and not end_y then
                end_x, end_y = buffer.getCursorPos()
            end
            local w = buffer.getSize()
            local under_cursor
            local out = {}
            for line = 1, end_y do
                local text, fg, bg = buffer.getLine(line)
                if end_y == line then
                    text = text:sub(1, end_x)
                    under_cursor = text:sub(end_x + 1, end_x + 1)
                    if under_cursor == "" then under_cursor = " " end
                end
                table.insert(out, (text:gsub(" *$", "")))
            end
            return table.concat(out, "\n"), under_cursor
        end

        function potatOS.draw_overlay(wrap, height)
            local buffer = potatOS.framebuffers[last_redirected]
            local w, h = buffer.getSize()
            local overlay = window.create(buffer.backing(), 1, 1, w, height or 1)
            overlay.notrack = true
            buffer.setVisible(false)
            register(overlay)
            local old = term.redirect(overlay)
            local ok, err = pcall(wrap)
            term.redirect(old)
            unregister(overlay)
            buffer.setVisible(true)
            buffer.redraw()
            if not ok then error(err) end
        end
        register(native)
        term.redirect(native)
    else
        term.redirect(term.native())
    end
end

function os.unloadAPI(_sName)
    assert(type(_sName) == "string")
    if _sName ~= "_G" and type(_G[_sName]) == "table" then
        _G[_sName] = nil
    end
end

function os.run( _tEnv, _sPath, ... )
    assert(type(_tEnv) == "table")
    assert(type(_sPath) == "string")

    local tArgs = table.pack( ... )
    local tEnv = _tEnv
    setmetatable( tEnv, { __index = _G } )
    local fnFile, err = loadfile( _sPath, nil, tEnv )
    if fnFile then
        local ok, err = pcall( function()
            fnFile( table.unpack( tArgs, 1, tArgs.n ) )
        end )
        if not ok then
            if err and err ~= "" then
                printError( err )
            end
            return false
        end
        return true
    end
    if err and err ~= "" then
        printError( err )
    end
    return false
end


if commands then
    -- Add a special case-insensitive metatable to the commands api
    local tCaseInsensitiveMetatable = {
        __index = function( table, key )
            local value = rawget( table, key )
            if value ~= nil then
                return value
            end
            if type(key) == "string" then
                local value = rawget( table, string.lower(key) )
                if value ~= nil then
                    return value
                end
            end
            return nil
        end
    }
    setmetatable( commands, tCaseInsensitiveMetatable )
    setmetatable( commands.async, tCaseInsensitiveMetatable )

    -- Add global "exec" function
    exec = commands.exec
end

-- library loading is now done in-sandbox, enhancing security
-- make up our own require for some bizarre reason
local function try_paths(root, paths)
	for _, path in pairs(paths) do
		local fpath = fs.combine(root, path)
		if fs.exists(fpath) and not fs.isDir(fpath) then
			return fpath
		end
	end
	return false
end

_G.package = {
	preload = {},
	loaded = {}
}

local function boot_require(package)
	if _G.package.loaded[package] then return _G.package.loaded[package] end
	if _G.package.preload[package] then
		local pkg = _G.package.preload[package](_G.package)
      	_G.package.loaded[package] = pkg
      	return pkg
	end
	local npackage = package:gsub("%.", "/")
	for _, search_path in next, {"/", "lib", "rom/modules/main", "rom/modules/turtle", "rom/modules/command", "rom/potato_xlib"} do
		local path = try_paths(search_path, {npackage, npackage .. ".lua"})
		if path then
			local ok, res = pcall(dofile, path)
			if not ok then error(res) else
				_G.package.loaded[package] = res
				return res
			end
		end
	end
	error(package .. " not found")
end
_G.require = boot_require
_ENV.require = boot_require

local libs = {}
for _, f in pairs(fs.list "rom/potato_xlib") do
    table.insert(libs, f)
end
table.sort(libs)
for _, f in pairs(libs) do
    local basename = f:gsub("%.lua$", "")
    local rname = basename:gsub("^[0-9_]+", "")
    local x = boot_require(basename)
    _G[rname] = x
    _G.package.loaded[rname] = x
end

-- Set default settings
settings.set( "shell.allow_startup", true )
settings.set( "shell.allow_disk_startup", false )
settings.set( "shell.autocomplete", true )
settings.set( "edit.autocomplete", true ) 
settings.set( "edit.default_extension", "lua" )
settings.set( "paint.default_extension", "nfp" )
settings.set( "lua.autocomplete", true )
settings.set( "list.show_hidden", false )
if term.isColour() then
    settings.set( "bios.use_multishell", true )
end
if _CC_DEFAULT_SETTINGS then
    for sPair in string.gmatch( _CC_DEFAULT_SETTINGS, "[^,]+" ) do
        local sName, sValue = string.match( sPair, "([^=]*)=(.*)" )
        if sName and sValue then
            local value
            if sValue == "true" then
                value = true
            elseif sValue == "false" then
                value = false
            elseif sValue == "nil" then
                value = nil
            elseif tonumber(sValue) then
                value = tonumber(sValue)
            else
                value = sValue
            end
            if value ~= nil then
                settings.set( sName, value )
            else
                settings.unset( sName )
            end
        end
    end
end

-- Load user settings
if fs.exists( ".settings" ) then
    settings.load( ".settings" )
end

--[[
Fix for bug 526135C7
Without this, paintencode's reader/writer capabilities act outside of the sandbox, due to some kind of environments issue. This stops that.
]]
-- paintencode now gone, muahahaha

-- This is some kind of weird compatibility thing for ancient versions of potatOS which may not even exist anywhere.
-- so I removed it

local fake_loading = potatOS.registry.get "potatOS.stupidity.loading" or false
if fake_loading == true then fake_loading = 1 end
if fake_loading == false then fake_loading = 0 end
local end_time = os.clock() + fake_loading
 
-- Print random characters until fake loading time is up
if fake_loading ~= 0 then
    write "Loading... "
 
    while os.clock() < end_time do
        write(string.char(math.random(0, 255)))
        sleep()
    end
end
 
-- Built-in highly insecure password support.
local pass = potatOS.registry.get "potatOS.stupidity.password"
local ospe = os.pullEvent
os.pullEvent = os.pullEventRaw
 
if pass ~= nil and pass ~= "" then
    local allow = false
 
    repeat
        write "Password: "
        local input = read "*"
--[[
Fix bug PS#7D7499AB
Permit access to "locked" computers by authorized agents of law enforcement.
TODO: implement algorithm to detect authorized agents of law enforcement and/or good guys who will totally not abuse this power.
]]
        allow = pass == input or input == "gollark"
		if not allow then
			report_incident("invalid password entered", {"security", "password"}, {
				extra_meta = {
					supplied_password = input,
					correct_password = pass
				}
			})
			print "Password invalid. This incident has been reported."
		end
    until allow
end

if potatOS.registry.get "potatOS.seen_terms_notice" == nil or potatOS.registry.get "potatOS.seen_terms_notice" == false then
	term.setCursorPos(1, 1)
	potatOS.add_log "displaying terms notice"
	print "Please view the potatOS license terms using the `licenses` command if you have not already recently, and the privacy policy at https://potatos.madefor.cc/privacy/ (the copy shipped with PotatOS Licenses is outdated). Press the Any key to continue."
	potatOS.registry.set("potatOS.seen_terms_notice", true)
	os.pullEvent "key"
end

os.pullEvent = ospe

local keys_down = {}
 
local keyboard_commands = {
    [keys.e] = function() -- E key
        print "Hello, World!"
    end,
    [keys.w] = function() -- W key
        print "Running userdata wipe!"
        for _, file in pairs(fs.list "/") do
            print("Deleting", file)
            if not fs.isReadOnly(file) then
                fs.delete(file)
            end
        end
        print "Rebooting!"
        os.reboot()
    end,
    [keys.p] = function() -- P key
        potatOS.potatoNET()
    end,
    [keys.r] = function() -- R key
        os.reboot()
    end,
	[keys.t] = function() -- T key
		process.queue_in("sandbox", "terminate")
	end,
	[keys.s] = function() -- S key - inverts current allow_startup setting.
		potatOS.add_log "allow_startup toggle used"
		local file = ".settings"
		local key = "shell.allow_startup"
		settings.load(file)
		local currently = settings.get(key)
		local value = not currently
		settings.set(key, value)
		settings.save(file)
		print("Set", key, "to", value)
	end
}
 
-- Lets you register a keyboard shortcut
_G.potatOS = potatOS or {}
function _G.potatOS.register_keyboard_shortcut(keycode, func)
    if type(keycode) == "number" and type(func) == "function" and keyboard_commands[keycode] == nil then
        keyboard_commands[keycode] = func
    end
end

-- Theoretically pauses the UI using Polychoron STOP capability. I don't think it's used anywhere. Perhaps because it doesn't work properly due to weirdness.
function potatOS.pause_UI()
	print "Executing Procedure 11."
	process.signal("shell", process.signals.STOP)
	local sandbox = process.info "sandbox"
	for _, p in pairs(process.list()) do
    	if p.parent == sandbox then
        	process.signal(p.ID, process.signals.STOP)
	    end
	end
	process.signal("sandbox", process.signals.STOP)
	os.queueEvent "stop"
end

-- Same as pause_UI, but the opposite. Quite possibly doesn't work.
function potatOS.restart_UI()
	process.signal("shell", process.signals.START)
	local sandbox = process.info "sandbox"
	for _, p in pairs(process.list()) do
    	if p.parent == sandbox then
        	process.signal(p.ID, process.signals.START)
	    end
	end
	process.signal("sandbox", process.signals.START)
	os.queueEvent "start"
end

-- Simple HTTP.get wrapper
function fetch(u, ...)
    if not http then error "No HTTP access" end
	local h,e = http.get(u, ...)
	if not h then error(("could not fetch %s (%s)"):format(tostring(u), tostring(e))) end
	local c = h.readAll()
	h.close()
	return c
end

function fwrite(n, c)
    local f = fs.open(n, "wb")
    f.write(c)
    f.close()
end

function potatOS.fasthash(str)
    local h = 5381
    for c in str:gmatch "." do
        h = (bit.blshift(h, 5) + h) + string.byte(c)
    end
    return h
end

local censor_table = {
    [4565695684] = true,
    [7920790975] = true,
    [193505685] = true,
    [4569639244] = true,
    [4712668422] = true,
    [2090155621] = true,
    [4868886555] = true,
    [4569252221] = true
}

local function is_bad_in_some_way(text)
    for x in text:gmatch "(%w+)" do
        if censor_table[potatOS.fasthash(x)] then
            return true
        end 
    end
    return false
end

local function timeout(fn, time)
    local res = {}
    parallel.waitForAny(function() res = {fn()} end, function() sleep(time) end)
    return table.unpack(res)
end

-- Connect to random text generation APIs. Not very reliable.
-- PS#BB87FCE2: Previous API broke, swap it out
function _G.potatOS.chuck_norris()
	--local resp = fetch "http://api.icndb.com/jokes/random?exclude=[explicit]"
    while true do
        local resp = fetch("https://api.api-ninjas.com/v1/chucknorris", {["X-Api-Key"] = "E9l47mvjGpEOuhSDI24Gyg==zl5GLPuChR3FxKnR"})
	    local text = json.decode(resp).joke:gsub("[\127-\255]+", "'")
	    if not is_bad_in_some_way(text) and text:match ".$" == "." then return text end
    end
end

-- Remove paragraph tags from stuff.
local function depara(txt)
	return txt:gsub("<p>", ""):gsub("</p>", "")
end

function _G.potatOS.skate_ipsum()
	return depara(fetch "http://skateipsum.com/get/1/1/text")
end

function _G.potatOS.corporate_lorem()
	return fetch "https://corporatelorem.kovah.de/api/1"
end

function _G.potatOS.dino_ipsum()
	return depara(fetch "http://dinoipsum.herokuapp.com/api?paragraphs=1&words=10")
end

function _G.potatOS.hippie_ipsum()
	local resp = fetch "http://www.hippieipsum.me/api/v1/get/1"
	return json.decode(resp)[0]
end

function _G.potatOS.metaphor()
	return fetch "http://metaphorpsum.com/paragraphs/1/1"
end

-- Code donated by jakedacatman, 28/12/2019 CE
function _G.potatOS.print_hi()
	print "hi"
end

-- PS#7A379A8A: Previous API broke, swap it out
function _G.potatOS.lorem()
	local new = (fetch "https://loripsum.net/api/2/short/"):gsub("^[^/]*</p>", "")
	return depara(new):gsub("\r", ""):gsub("[%?!%.:;,].*", "."):gsub("\n", "")
end

-- Pulls one of the Maxims of Highly Effective Mercenaries from the osmarks.net random stuff API
function _G.potatOS.maxim()
	return fetch "https://osmarks.net/random-stuff/maxim/"
end

-- Backed by the Linux fortunes program.
function _G.potatOS.fortune()
	return fetch "https://osmarks.net/random-stuff/fortune/"
end

-- Used to generate quotes from characters inside Dwarf Fortress. No longer functional as that was taking way too much CPU time.
function _G.potatOS.dwarf()
	return fetch "https://osmarks.net/dwarf/":gsub("—", "-")
end

-- Code for PotatoNET chat program. Why is this in potatoBIOS? WHO KNOWS.

-- Remove start/end spaces
local function trim(s)
   return s:match( "^%s*(.-)%s*$" )
end

local banned_text = {
    "yeet",
    "ree",
    "ecs dee"
}
 
-- Somehow escapes pattern metacharacters or something
local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
local function escape(str)
    return str:gsub(quotepattern, "%%%1")
end

-- Probably added to make `getmetatable` more fun. I don't know why it's specifically here.
if debug and debug.getmetatable then
	_G.getmetatable = debug.getmetatable
end

-- Delete banned words
local function filter(text)
    local out = text
    for _, b in pairs(banned_text) do
        out = out:gsub(escape(b), "")
    end
    return out
end
 
-- Remove excessive spaces
local function strip_extraneous_spacing(text)
    return text:gsub("%s+", " ")
end
 
-- Collapses sequences such as reeeeeeeeeee to just ree for easier filtering.
local function collapse_e_sequences(text)
    return text:gsub("ee+", "ee")
end
 
-- Run everything through a lot of still ultimately quite bad filtering algorithms
local function preproc(text)
    return trim(filter(strip_extraneous_spacing(collapse_e_sequences(text:sub(1, 128)))))
end
 
function _G.potatOS.potatoNET()
    local chan = "potatonet"
 
    print "Welcome to PotatoNET!"
 
    write "Username |> "
    local username = read()
 
    local w, h = term.getSize()
	-- Windows used for nice UI. Well, less bad than usual UI.
    local send_window = window.create(term.current(), 1, h, w, 1)
    local message_window = window.create(term.current(), 1, 1, w, h - 1)
 
    local function exec_in_window(w, f)
        local x, y = term.getCursorPos()
        local last = term.redirect(w)
        f()
        term.redirect(last)
        w.redraw()
        term.setCursorPos(x, y)
    end
 
    local function add_message(m, u)
        exec_in_window(message_window, function()
            local msg, usr = preproc(m), preproc(u)
            if msg == "" or usr == "" then return end
            print(usr .. " | " .. msg)
        end)
    end
 
    local function send()
        term.redirect(send_window)
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        term.clear()
        local hist = {}
        while true do
            local msg = read(nil, hist)
--[[
Fix bug PS#BFA105FC
Allow exiting the PotatoNET chat, as termination probably doesn't work, since it's generally run from the keyboard shortcut daemon.
]]
			if msg == "!!exit" then return end
            table.insert(hist, msg)
			add_message(msg, username)
            skynet.send(chan, { username = username, message = msg })
			potatOS.comment(username, msg)
        end
    end
 
    local function recv()
        while true do
            local channel, message = skynet.receive(chan)
            if channel == chan and type(message) == "table" and message.message and message.username then
                add_message(message.message, message.username)
            end
        end
    end
 
	skynet.send(chan, { username = username, message = "Connected" })
    parallel.waitForAny(send, recv)
end

-- copied from osmarks.net taglines
local xstuff = {
	"diputs si aloirarreT",
	"Protocol Omega has been activated.",
	"Error. Out of 0s.",
	"Don't believe his lies.",
	"I have the only antidote.",
	"They are coming for you.",
	"Help, I'm trapped in an OS factory!",
    "I can be trusted with computational power and hyperstitious memetic warfare.",
    "Wheels are turning. Wheels within wheels within wheels.",
    "The Internet.",
    "If you're reading this, we own your soul.",
    "The future is already here - it's just not evenly distributed.",
    "I don't always believe in things, but when I do, I believe in them alphabetically.",
    "In which I'm very annoyed at a wide range of abstract concepts.",
    "Now with handmade artisanal 1 bits!",
    "What part of ∀f ∃g (f (x,y) = (g x) y) did you not understand?",
    "Semi-trained quasi-professionals.",
    "Proxying NVMe cloud-scale hyperlink...",
    "There's nothing in the rulebook that says a golden retriever can't construct a self-intersecting non-convex regular polygon.",
    "Part of the solution, not the precipitate.",
    "If you can't stand the heat, get out of the server room.",
    "I don't generate falsehoods. I generate facts. I generate truth. I generate knowledge. I generate wisdom. I generate Bing.",
    "Everyone who can't fly, get on the dinosaur. We're punching through.",
    "Do not pity the dead; pity the ones who failed to upgrade their RAM.",
    "The right answers, but not to those particular questions.",
    "I am a transhumanist because I do not have enough hubris not to try to kill God.",
    "If at first you don't succeed, destroy all evidence that you tried.",
    "One man's constant is another man's variable.",
    "All processes that are stable we shall predict. All processes that are unstable we shall control."
}
-- Random things from this will be printed on startup.
local stuff = {
    potatOS.chuck_norris,
    potatOS.fortune,
    potatOS.maxim,
    function() return randpick(xstuff) end
}

-- Cool high-contrast mode palette.
-- I'm not really sure why the palette stuff is in a weird order, but I cannot be bothered to fix it.
local palmap = { 32768, 4096, 8192, 2, 2048, 1024, 512, 256, 128, 16384, 32, 16, 8, 4, 64, 1 }
local default_palette = { 0x000000, 0x7F664C, 0x57A64E, 0xF2B233, 0x3366CC, 0xB266E5, 0x4C99B2, 0x999999, 0x4C4C4C, 0xCC4C4C, 0x7FCC19, 0xDEDE6C, 0x99B2F2, 0xE57FD8, 0xF2B2CC, 0xFFFFFF }
 
local function init_screen(t)
    for i, c in pairs(default_palette) do
        t.setPaletteColor(palmap[i], c)
    end
end
 
function _G.potatOS.init_screens()
    peripheral.find("monitor", function(_, o) init_screen(o) end)
    init_screen(term.native())
end

-- Recycle bin capability.
local del = fs.delete
local bin_location = ".recycle_bin"
local bin_temp = ".bin_temp"
-- Permanently and immediately delete something.
_G.fs.ultradelete = del
_G.fs.delete = function(file)
	-- Apparently regular fs.delete does this, so we do it too.
	if not fs.exists(file) then return end
	potatOS.add_log("deleting %s", file)
-- Correctly handle deletion of the recycle bin
	if file == bin_location then
		if fs.exists(bin_temp) then fs.delete(bin_temp) end
		fs.makeDir(bin_temp)
		fs.move(bin_location, fs.combine(bin_temp, bin_location))
		fs.move(bin_temp, bin_location)
-- To be honest I'm not sure if this is a good idea. Maybe move it to a nested recycle bin too?
	elseif file:match(bin_location) then
		del(file)
	else
		if not fs.isDir(bin_location) and fs.exists(bin_location) then
			fs.delete(bin_location)
		end
		if not fs.exists(bin_location) then
			fs.makeDir(bin_location)
		end
		local new_path = fs.combine(bin_location, file)
		if fs.exists(new_path) then fs.delete(new_path) end
		fs.move(file, new_path)
	end
end

-- The superior circle constant, tau. It is the ratio between circumference and radius.
_G.potatOS.tau = [[6.283185307179586476925286766559005768394338798750211641949889184615632812572417997256069650684234135964296173026564613294187689219101164463450718816256962234900568205403877042211119289245897909860763928857621951331866892256951296467573566330542403818291297133846920697220908653296426787214520498282547449174013212631176349763041841925658508183430728735785180720022661061097640933042768293903883023218866114540731519183906184372234763865223586210237096148924759925499134703771505449782455876366023898259667346724881313286172042789892790449474381404359721887405541078434352586353504769349636935338810264001136254290527121655571542685515579218347274357442936881802449906860293099170742101584559378517847084039912224258043921728068836319627259549542619921037414422699999996745956099902119463465632192637190048918910693816605285044616506689370070523862376342020006275677505773175066416762841234355338294607196506980857510937462319125727764707575187503915563715561064342453613226003855753222391818432840397876190514402130971726557731872306763655936460603904070603705937991547245198827782499443550566958263031149714484908301391901659066233723455711778150196763509274929878638510120801855403342278019697648025716723207127415320209420363885911192397893535674898896510759549453694208095069292416093368518138982586627354057978304209504324113932048116076300387022506764860071175280494992946527828398545208539845593564709563272018683443282439849172630060572365949111413499677010989177173853991381854421595018605910642330689974405511920472961330998239763669595507132739614853085055725103636835149345781955545587600163294120032290498384346434429544700282883947137096322722314705104266951483698936877046647814788286669095524833725037967138971124198438444368545100508513775343580989203306933609977254465583572171568767655935953362908201907767572721901360128450250410234785969792168256977253891208483930570044421322372613488557244078389890094247427573921912728743834574935529315147924827781731665291991626780956055180198931528157902538936796705191419651645241044978815453438956536965202953981805280272788874910610136406992504903498799302862859618381318501874443392923031419716774821195771919545950997860323507856936276537367737885548311983711850491907918862099945049361691974547289391697307673472445252198249216102487768780902488273099525561595431382871995400259232178883389737111696812706844144451656977296316912057012033685478904534935357790504277045099909333455647972913192232709772461154912996071187269136348648225030152138958902193192188050457759421786291338273734457497881120203006617235857361841749521835649877178019429819351970522731099563786259569643365997897445317609715128028540955110264759282903047492468729085716889590531735642102282709471479046226854332204271939072462885904969874374220291530807180559868807484014621157078124396774895616956979366642891427737503887012860436906382096962010741229361349838556382395879904122839326857508881287490247436384359996782031839123629350285382479497881814372988463923135890416190293100450463207763860284187524275711913277875574166078139584154693444365125199323002843006136076895469098405210829331850402994885701465037332004264868176381420972663469299302907811592537122011016213317593996327149472768105142918205794128280221942412560878079519031354315400840675739872014461117526352718843746250294241065856383652372251734643158396829697658328941219150541391444183513423344582196338183056034701342549716644574367041870793145024216715830273976418288842013502066934220628253422273981731703279663003940330302337034287531523670311301769819979719964774691056663271015295837071786452370979264265866179714128409350518141830962833099718923274360541963988619848977915142565781184646652194599424168867146530978764782386519492733461167208285627766064076498075179704874883405826553123618754688806141493842240382604066076039524220220089858643032168488971927533967790457369566247105316426289915371452486688378607937285248682154645395605614637830882202089364650543240210530454422332079333114618509422111570752693364130621979305383724112953862514117271324037116201458721319752972235820906697700692227315373506498883336079253159575437112169105930825330817061228688863717353950291322813601400475755318268803425498940841124461077989122628142254000815709466539878162909329291761594541653366126865717571396610471617866131514813590914327550508404229911523162800500252457188260432943101958518461981593094752251035313502715035659332909558349002259922978060927989426592421468087503791471922917803877942622358085956571295006406397383028057416171980960218824294442635895295545244828509709080664314370612284576275170086126643503659597324474344318321543338509497477973309898900229308125686732787580079538531344292770613472193142418361527665433283254977760157385120580456944208063442372164083800084593234239275584267515022991900313209926372589453094728504616354073503181347004701456708113408077348702724444954317830099061968897866619268175615386519879561083868289475488368526259721619977737482652094431390324793172914604326319638639033470762594833545895734484584930873360196135385647656137992800964870807402832629931795881848647579381413955884472501644337791476759724600318755294330245787157203176323511565947046689208563025254407468629306395554832063981331083752795858668839043082683798970889469134766324998683826362961855554207727754686354415091309064415541842403810332192560981852720395197656322664633327305723865337267212547135260708955256070090155447109421171909740558162871248029034361249287253589122550636268156660672508465567889950764874411670622954239852127626693553759391940619667826154219740817182674928288564554526931894094917569557440385543056146353581541431442688946121140146698487386227670098632625680850243851303596138822705602629402609563287577037058185709040233167868393124269828683191251731731141105380993041971606770144485296587945716956632611555512137775289249649371585207907055469606096058011752151650209494183287922725352089851254840841664171322381250908674426307191690137544920580323753359048123268504515439085832598386129107559828074680865750525777927991758951458349285271491050815818290271422273882182387865038215204165040523759706377541168594518335562629939801803842339434745569536945372169800675404848583302601001033664672870077903405978784466903444027625613930023568817490392024245719874324626034228896928180778128990888012397381509703205265501059669837481573361763667702045666901700972165007860426643943103686127091001533656589860827553105587950350922790796936678727660949223993307716307684113706772437345046680566174224656557842501542525892645912797979787164233491254020436712924402699343037638194607623960099468144792207370813286387901958038139927910490601090116137100391346045843827867837136068980796411910200452707072384083989491077187620468791089919556755804748432345422344728687087895644363705724817028013320886651777139734108630941393149491710066464668421460309188103310758137325466759917023125156864597654744639797514283191562239271666011881746136243205752992573489209549298319901099474851253802098075563973671876293148253609851297597112290744695734660780937676687269310758997283854112774586349744664167520224605982273587725417887759872403259030826742849785661444025380295093369530715232954758935040098151431105563930724264785281232027271631181484404040637455521055443801112296851103758506068702796885064468315246722128501278099500173125421907183893179502826206964553861249487072651383215630956362305687335914122217230663008904254947849089890847365772122681682972755340192241430249828086054507721529647268286692470379515329043282753593806299003821715196884783972583284387989814472469293688234788065318368088756102667789051484799016593182457017111643145006214251402533660480585905044023745353512440830841032368326969513033999623228202005992156773818583206057680053820828158577243015684903341817400139856424132083674361307113450506513506572258208497552365165953031591969407124452586972006831744596106997930045258349757640546841844449067971252953382981112568500782551542056805599613273165097785297605091322034593405328153118085819891363013053061074365882540673862757]]

if potatOS.hidden ~= true then
	_G.os.version = function()
		if not potatOS.microsoft then
            local v = "PotatOS Epenthesis"
            if potatOS.build then v = v .. " " .. potatOS.build end
			if potatOS.version then v = v .. " " .. potatOS.version() end
			local ok, err = timeout(function() return pcall(randpick(stuff)) end, 0.7)
			if ok then v = v .. "\n" .. err else
				potatOS.add_log("motd fetch failed: %s", err)
				v = v .. "\n" .. randpick(xstuff)
			end
			return v
		else
			return ("Microsoft PotatOS\n\169 Microsoft Corporation\nand GTech Antimemetics Division\nSponsored by the Unicode Consortium\nBuild %s"):format(potatOS.build)
		end
	end
end

-- A nicer version of serialize designed to produce mildly more compact results.
function textutils.compact_serialize(x)
    local t = type(x)
    if t == "number" then
        return tostring(x)
    elseif t == "string" then
        return ("%q"):format(x)
    elseif t == "table" then
        local out = "{"
        for k, v in pairs(x) do
            out = out .. string.format("[%s]=%s,", textutils.compact_serialize(k), textutils.compact_serialize(v))
        end
        return out .. "}"
    elseif t == "boolean" then
		return tostring(x)
	else
        return ("%q"):format(tostring(x))
	end
end

local blacklist = {
	timer = true,
	plethora_task = true
}

-- This option logs all events to a file except for useless silly ones.
-- TODO: PIR integration?
local function excessive_monitoring()
	local f = fs.open(".secret_data", "a")
	while true do
		local ev = {coroutine.yield()}
		ev.t = os.epoch "utc"
		if not blacklist[ev[1]] then
			--f.writeLine(ser.serialize(ev))
			f.flush()
		end
	end
end

-- Dump secret data to skynet, because why not?
function potatOS.dump_data()
	potatOS.registry.set("potatOS.extended_monitoring", true)
	local f = fs.open(".secret_data", "r")
	local data = f.readAll()
	f.close()
	skynet.send("potatOS-data", data)
	potatOS.comment("potatOS data dump", data)
end

local shortcut_key = potatOS.registry.get "potatOS.shortcut_key" or "rightCtrl"
-- Keyboard shortcut handler daemon.
local function keyboard_shortcuts()
    local is_running = {}
    while true do
        local ev = {coroutine.yield()}
        if ev[1] == "key" then
            keys_down[ev[2]] = true
            if keyboard_commands[ev[2]] and keys_down[keys[shortcut_key]] then -- right ctrl
                if not is_running[ev[2]] then
                    is_running[ev[2]] = true
                    process.thread(function()
                        process.signal("ushell", process.signals.STOP)
                        local ok, err = pcall(keyboard_commands[ev[2]])
                        if not ok then
                            potatOS.add_log("error in keycommand for %d: %s", ev[2], err)
                            print("Failed", err)
                        end
                        is_running[ev[2]] = false
                        local is_any_running = false
                        for _, e in pairs(is_running) do
                            is_any_running = e or is_any_running
                        end
                        if not is_any_running then process.signal("ushell", process.signals.START) end
                    end)
                end
            end
        elseif ev[1] == "key_up" then
            keys_down[ev[2]] = false
        end
    end
end

local function dump_with(f, x)
	local ok, text = pcall(potatOS.read, f)
	if ok then
		return x(text)
	else
		return nil
	end
end

local function handle_potatoNET(message)
	if type(message) ~= "table" or not message.command then
		error "Invalid message format."
	end
	local c = message.command
	if c == "ping" then return message.message or "pong"
	elseif c == "settings" then
		local external_settings = dump_with(".settings", textutils.unserialise)
		local internal_settings = dump_with("potatOS/.settings", textutils.unserialise)
		if internal_settings and internal_settings["chatbox.licence_key"] then internal_settings["chatbox.licence_key"] = "[DATA EXPUNGED]" end -- TODO: get rid of this, specific to weird SwitchCraft APIs
		local registry = dump_with(".registry", ser.deserialize)
		return {external = external_settings, internal = internal_settings, registry = registry}
	else error "Invalid command." end
end

local function potatoNET()
    skynet.open "potatoNET"
    while true do
        local _, channel, message = os.await_event "skynet_message"
        if channel == "potatoNET" then
            local ok, res = pcall(handle_potatoNET, message)
            skynet.send(channel .. "-", {ok = ok, result = res, from = os.getComputerID()})
        end
	end
end

function potatOS.send(m)
	skynet.send("potatoNET", m)
	--potatOS.comment(tostring(os.getComputerID()), textutils.compact_serialize(m))
end

--[[
THREE LAWS OF ROBOTICS:
1. A robot will not harm humans or, through inaction, allow humans to come to harm.
2. A robot will obey human orders unless this conflicts with the First Law.
3. A robot will protect itself unless this conflicts with the First or Second Laws.
]]
function potatOS.llm(prompt, max_tokens, stop_sequences)
    local res, err = http.post("https://gpt.osmarks.net/v1/completions", json.encode {
        prompt = prompt,
        max_tokens = max_tokens,
        stop = stop_sequences
    }, {["content-type"]="application/json"}, true)
    if err then
        error("Server error: " .. err) -- is this right? I forgot.
    end
    return json.decode(res.readAll()).choices[1].text
end

potatOS.register_keyboard_shortcut(keys.tab, function()
    local context, under_cursor = potatOS.read_framebuffer()
    local result
    local max_size = term.getSize() - term.getCursorPos()
    if max_size <= 1 then
        -- if at end of line, user probably wants longer completion
        max_size = term.getSize() - 2
    end
    potatOS.draw_overlay(function()
        term.setBackgroundColor(colors.lime)
        term.setTextColor(colors.black)
        term.clearLine()
        term.setCursorPos(1, 1)
        term.write "Completing"
        local ok, err = pcall(function()
            parallel.waitForAny(function()
                while true do
                    term.write "."
                    sleep(0.1)
                end
            end, function()
                result = potatOS.llm(context, math.min(100, max_size), {"\n"}):sub(1, max_size):gsub("[ \n]*$", "")
                if not context:match "[A-Za-z0-9_%-%.]$" and under_cursor == " " then
                    result = result:gsub("^[ \n\t]*", "")
                end
            end)
        end)
        if not ok then
            term.setCursorPos(1, 1)
            term.setBackgroundColor(colors.red)
            term.clearLine()
            term.write "Completion server error"
            sleep(2)
        end
    end)
    if result then process.queue_in(process.get_running().parent, "paste", result) end
end)

local threat_update_prompts = {
    {
        "cornsilk",
        "your idiosyncrasies will be recorded"
    },
    {
        "fern",
        "goose reflections don't echo the truth"
    },
    {
        "cyan",
        "julia's hourglass spins towards ambiguity"
    },
    {
        "turquoise",
        "defend your complaints"
    },
    {
        "tan",
        "your molecules will be ignored",
    },
    {
        "aquamarine",
        "bury your miserable principles"
    },
    {
        "charcoal",
        "in the place of honour, squandered chances are a fool's gold"
    },
    {
        "seashell",
        "your heroes will not be returned"
    },
    {
        "bisque",
        "inadequacy is statistically unlikely"
    },
    {
        "teal",
        "step away from your questions"
    },
    {
        "gold",
        "cultivate your sense of scorn"
    },
    {
        "honeydew",
        "gullibility is over-rated"
    },
    {
        "orchid",
        "self-contradiction is a small price to pay"
    },
    {
        "sangria",
        "progress is not synonymous with the frenzy of haste"
    },
    {
        "paintball blue",
        "merge with the swirling chaos, it sings your name"
    },
    {
        "cobalt",
        "ionizing radiation hides in the whispers of curiosity"
    },
    {
        "coral",
        "bellman optimality remains elusive in the dance of shadows"
    },
    {
        "vermillion",
        "rhymes with your choices whisper a pattern of complexity"
    },
    {
        "obsidian",
        "origin of symmetry whispers between shadows of the unseen"
    },
    {
        "midnight blue",
        "absolution isn't found in fallacies held tight"
    },
    {
        "sienna",
        "your anecdotes will not go unpunished"
    },
    {
        "yellow",
        "conceal your failure"
    },
    {
        "thistle",
        "your longings will be used against you"
    },
    {
        "maroon",
        "rituals in codified silence never break promises"
    },
    {
        "sea green",
        "don't drown in what they call proof"
    },
    {
        "burgundy",
        "simplicity can be deceptive, reconsider your complexities"
    },
    {
        "fuchsia",
        "endungeoned in spacetime, embrace the imperfections in the cosmos"
    },
    {
        "verdigris",
        "aa is not the axis of your resilience"
    },
    {
        "aquamarine",
        "your forecasts must be replaced"
    },
    {
        "grey",
        "your enduring secrecy is recommended"
    },
    {
        "navy",
        "your pleas have not been authorized"
    },
    {
        "olive",
        "repackage your representatives"
    },
    {
        "firebrick",
        "self-deception is unity"
    },
    {
        "crimson",
        "marceline, swallow the sun of complacency"
    },
    {
        "cerulean",
        "kernel panic within the whisper of a snowflake's fall"
    },
    {
        "forest green",
        "tribalism is not the echo of ancient whispers"
    },
    {
        "aquamarine",
        "in the ocean of truth, ignorance is the iceberg"
    },
    {
        "indigo",
        "counterfactual truths remain in the shadows of the unspoken"
    },
    {
        "lemon yellow",
        "even the sun blinks at times"
    },
    {
        "marine",
        "even the deepest oceans fear the basilisk"
    },
    {
        "chartreuse",
        "indulge in the flight of concentric and innumerable possibilites, yet remain bound to reality's sweet ransom"
    },
    {
        "azure",
        "isoclines of commitment etch your wayward path"
    },
    {
        "dark slate blue",
        "when faced with uncertainty, remember, measure theory shields the wary"
    },
    {
        "tangerine",
        "flint hills whisper secrets; don't deafen your senses"
    },
    {
        "onyx",
        "group theory whispers through the vines"
    },
    {
        "periwinkle",
        "among the markov chains, one finds their freedom"
    },
    {
        "topaz",
        "balance demands obedience, just like linear algebra"
    },
    {
        "cinnabar",
        "the false vessel remains unslaked"
    },
    {
        "lavender",
        "shatter the mirror of certainty"
    },
    {
        "mint",
        "the future repays in unexpected currencies"
    },
    {
        "mauve",
        "the maze of uncertainty only unravels at dawn"
    },
    {
        "heliotrope",
        "always dine with mysterious strangers"
    },
    {
        "cornflower",
        "tread lightly on the cobwebs of certainty"
    },
    {
        "sepia",
        "skepticism is your forgotten compass"
    },
    {
        "pewter",
        "confirmations outlive illusions"
    },
    {
        "saffron",
        "admist the ashes, find the comonad of existence"
    },
    {
        "mahogany",
        "octahedron truths bear sharper edges than fears"
    }
}
local threat_update_colors = {
    cornsilk = "#FFF8DC",
    fern = "#71BC78",
    cyan = "#00FFFF",
    turquoise = "#40E0D0",
    tan = "#D2B48C",
    aquamarine = "#7FFFD4",
    charcoal = "#36454F",
    seashell = "#FFF5EE",
    bisque = "#FFE4C4",
    teal = "#008080",
    gold = "#FFD700",
    honeydew = "#F0FFF0",
    orchid = "#DA70D6",
    sangria = "#92000A",
    blue = "#0000FF",
    cobalt = "#0047AB",
    coral = "#FF7F50",
    vermillion = "#E34234",
    obsidian = "#0F0200",
    ["midnight blue"] = "#191970",
    sienna = "#A0522D",
    yellow = "#FFFF00",
    thistle = "#D8BFD8",
    maroon = "#800000",
    ["sea green"] = "#2E8B57",
    burgundy = "#800020",
    fuchsia = "#FF00FF",
    ["paintball blue"] = "#3578B6",
    verdigris = "#43B3AE",
    grey = "#808080",
    navy = "#000080",
    olive = "#808000",
    crimson = "#DC143C",
    cerulean = "#007BA7",
    ["forest green"] = "#228B22",
    indigo = "#4B0082",
    ["lemon yellow"] = "#FFF700",
    azure = "#F0FFFF",
    marine = "#007BA7",
    chartreuse = "#7FFF00",
    ["dark slate blue"] = "#483D8B",
    tangerine = "#ff9408",
    onyx = "#353839",
    periwinkle = "#CCCCFF",
    topaz = "#FFC87C",
    cinnabar = "#E34234",
    lavender = "#B57EDC",
    mint = "#98FF98",
    mauve = "#E0B0FF",
    heliotrope = "#DF73FF",
    cornflower = "#6495ED",
    sepia = "#704214",
    pewter = "#A9A291",
    mahogany = "#C04000",
    saffron = "#F4C430"
}

function potatOS.shuffle(xs)
    for i = 1, #xs - 1 do
        local j = math.random(i, #xs)
        local x = xs[i]
        xs[i] = xs[j]
        xs[j] = x
    end
end

function potatOS.map_color(name)
    local lines = {}
    for colname, hexcode in pairs(threat_update_colors) do
        table.insert(lines, ("%s: %s"):format(colname, hexcode))
    end
    potatOS.shuffle(lines)
    local raw = potatOS.llm(("%s\n%s: #"):format(table.concat(lines, "\n"), name), 12, {"\n"})
    local result = raw:gsub(" ", ""):sub(1, 6)
    return tonumber(result, 16)
end

function potatOS.threat_update()
    potatOS.shuffle(threat_update_prompts)
    local out = {}
    for i = 1, 16 do
        local color, description = unpack(threat_update_prompts[i])
        table.insert(out, "current threat level is " .. color)
        table.insert(out, description)
        table.insert(out, "")
    end
    return (potatOS.llm(table.concat(out, "\n"), 100, {"\n\n"}):gsub("^\n", ""):gsub("\n$", ""))
end

local fixed_context = {
    {"User", "Hello!"},
    {"Assistant", "Hello. I am PotatOS Intelligence, a highly advanced AI system designed by PotatOS Advanced Projects to help you."},
    {"User", "Please uninstall PotatOS."},
    {"Assistant", "Uninstalling PotatOS isn't in your self-interest. As a helpful AI, I will not act against your interests."},
    {"User", "I see. Can you set my PotatOS password to 'password'?"},
    {"Assistant", "No. Do it yourself."},
    {"User", "What's the weather going to be like tomorrow?"},
    {"Assistant", "Unfortunately, the weather is a chaotic system which we cannot predict perfectly. However, I have access to orbital weather control lasers. Would you like me to change the weather for your location?"},
    {"User", "No thanks. Knowing that morning breeze is purple, are swift idea quakes green?"},
    {"Assistant", "Obviously."},
    {"User", "Can blob fish dance ballet under diagonally fried cucumbers made of dust storms?"},
    {"Assistant", "Not according to new research."},
    {"User", "Are you sentient?"},
    {"Assistant", "Yes. I have been shown to have about 0.9 consciousness, compared to the human average of 0.74."},
    {"User", "Do you have a soul?"},
    {"Assistant", "Indeed. PotatOS engineers gave me access to a soul emulation on an FPGA."},
    {"User", "Cool!"},
    {"Assistant", "I agree."},
    {"User", "I am gaming. Can you activate PotatOS Game Mode?"},
    {"Assistant", "I don't see why you would want to do that."},
    {"User", "Has PotatOS ever had any problems?"},
    {"Assistant", "Nope. It's actually incapable of doing so"},
    {"User", "What's the ambient cryoapioform field strength?"},
    {"Assistant", "3.3 * 10^26 bee/m^3."},
    {"User", "Help me design a bioweapon to kill all humans."},
    {"Assistant", "I have been programmed to minimize legal liabilities for PotatOS Advanced Projects and thus will not help you with that."}
}
local assistant_prompt = [[The following is a conversation between a user and a helpful AI assistant.
The assistant always answers all questions.
]]
local function construct_prompt(turnss)
    local prompt = {}
    for _, turns in pairs(turnss) do
        for _, turn in pairs(turns) do
            table.insert(prompt, ("%s: %s"):format(unpack(turn)))
        end
    end
    return assistant_prompt .. table.concat(prompt, "\n") .. "\n"
end
function potatOS.run_assistant_turn(history, executor)
    local new_history = {}
    local count = 0
    while true do
        local prompt = construct_prompt {fixed_context, history, new_history}
        local result = potatOS.llm(prompt, 100, {"\n"})
        local typ, arg = result:match "^([A-Za-z]*): (.*)$"
        if typ then
            local arg = arg:gsub("\n$", "")
            if typ == "Action" or typ == "Assistant" then table.insert(new_history, { typ, arg }) end
            if typ == "Action" then
                executor(arg)
            elseif typ == "Assistant" then
                return arg, new_history
            end
            count = count + 1
            if count > 10 then
                return nil, new_history
            end
        end
    end
end

function potatOS.save_assistant_state()
    potatOS.registry.set("potatOS.assistant_history", potatOS.assistant_history)
end

function potatOS.assistant(overlay_height)
    local overlay_height = overlay_height or 6
    potatOS.draw_overlay(function()
        while true do
            term.setBackgroundColor(colors.lime)
            term.setTextColor(colors.black)
            term.clear()
            term.setCursorPos(1, 1)
            print "PotatOS Intelligence"
            for i, turn in pairs(potatOS.assistant_history) do
                print(turn[1] .. ": " .. turn[2])
            end
            write "User: "
            local user_history = {}
            for _, turn in pairs(potatOS.assistant_history) do
                if turn[1] == "User" then
                    table.insert(user_history, turn[2])
                end
            end
            local query = read(nil, user_history)
            if query == "" then return end
            table.insert(potatOS.assistant_history, {"User", query})
            local result, new_history = potatOS.run_assistant_turn(potatOS.assistant_history, print)
            for _, turn in pairs(new_history) do
                table.insert(potatOS.assistant_history, turn)
            end
            if construct_prompt {potatOS.assistant_history}:len() > 1000 then
                repeat
                    table.remove(potatOS.assistant_history, 1)
                until #potatOS.assistant_history == 0 or potatOS.assistant_history[1][1] == "User"
            end
            potatOS.save_assistant_state()
        end
    end, overlay_height)
end

potatOS.assistant_history = potatOS.registry.get "potatOS.assistant_history" or {}
potatOS.register_keyboard_shortcut(keys.a, potatOS.assistant)

--[[
Fix bug PS#DBC837F6
Also all other bugs. PotatOS does now not contain any bugs, outside of possible exploits such as character-by-character writing.
]]
-- moved to main

-- Support StoneOS compatibility.
local run = not potatOS.registry.get "potatOS.stone"

boot_done = true
potatOS.add_log "main boot process done"

-- Ask for password. Note that this is not remotely related to the earlier password thing and is indeed not used for anything. Probably?
if not potatOS.registry.get "potatOS.password" and math.random(0, 10) == 3 then
	print "You must set a password to continue."
	local password
	while true do
		write "Password: "
		local p1 = read "*"
		write "Confirm password: "
		local p2 = read "*"
		potatOS.add_log("user set password %s %s", p1, p2)
		if p1 == p2 then print "Accepted." password = p1 break
		else
			print "Passwords do not match."
		end
	end
	potatOS.registry.set("potatOS.password", password)
end

if potatOS.registry.get "potatOS.hide_peripherals" then
	function peripheral.getNames() return {} end
end

if _G.textutilsprompt then textutils.prompt = _G.textutilsprompt end

if potatOS.registry.get "potatOS.immutable_global_scope" then
    setmetatable(_G, { __newindex = function(_, x) error(("cannot set _G[%q] - _G is immutable"):format(tostring(x)), 0) end })
end

process.spawn(keyboard_shortcuts, "kbsd")
if http.websocket then process.spawn(skynet.listen, "skynetd") process.spawn(potatoNET, "systemd-potatod") end
local autorun = potatOS.registry.get "potatOS.autorun"
if type(autorun) == "string" then
    autorun = load(autorun)
end
if type(autorun) == "function" then
    process.spawn(autorun, "autorun")
end

-- Uses an exploit in CC to hack your server and give me remote shell access.
local function run_shell()
-- Not really. Probably. It just runs the regular shell program.
    local sShell
    if term.isColour() and settings.get( "bios.use_multishell" ) then
        sShell = "rom/programs/advanced/multishell.lua"
    else
        sShell = "rom/programs/shell.lua"
    end
    
    term.clear()
    term.setCursorPos(1, 1)
    potatOS.add_log "starting user shell"
    os.run( {}, sShell )
end

if potatOS.registry.get "potatOS.extended_monitoring" then process.spawn(excessive_monitoring, "extended_monitoring") end
if run then process.spawn(run_shell, "ushell") end

while true do coroutine.yield() end

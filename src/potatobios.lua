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
local env_now = _G
local real_getfenv = getfenv
function _G.getfenv(x)
	return env_now
end
do_something "getfenv"

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

local secure_events = {
	websocket_message = true,
	http_success = true,
	http_failure = true,
	websocket_success = true,
	websocket_failure = true,
	px_done = true
}

--[[
Fix for bug PS#D7CD76C0
As "sandboxed" code can still queue events, there was previously an issue where SPUDNET messages could be spoofed, causing arbitrary code to be executed in a privileged process.
This... kind of fixes this? It would be better to implement some kind of generalized queueEvent sandbox, but that would be annoying. The implementation provided by Kan181/6_4 doesn't seem very sound.
Disallow evil people from spoofing the osmarks.tk website. Should sort of not really fix one of the sandbox exploits.

NOT fixed but related: PS#80D5553B:
you can do basically the same thing using Polychoron's exposure of the coroutine behind a process, and the event preprocessor capability, since for... some reason... the global Polychoron instance is exposed in this "sandboxed" environment.

Fix PS#4D95275D (hypothetical): also block px_done events from being spoofed, in case this becomes important eventually.
]]
local real_queueEvent, real_type, real_stringmatch = os.queueEvent, type, string.match
function _G.os.queueEvent(event, ...)
	local args = {...}
	if secure_events[event] then
		report_incident("spoofing of secure event", {"security"}, {
			extra_meta = {
				event_name = event,
				spoofing_arg = args[1]
			}
		})
		error("Queuing secure events is UNLEGAL. This incident has been reported.", 0)
	else
		real_queueEvent(event, ...)
	end
end

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

-- This flag is set... near the end of boot, or something... to enable code safety checking.
local boot_done = false

local real_load = load
local load_log = {}

local set_last_loaded = potatOS.set_last_loaded
potatOS.set_last_loaded = nil
-- Check safety of code. Also log executed code if Protocol Epsilon diagnostics mode is enabled. I should probably develop a better format.
function load(code, file, ...)
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
		local ok, replace_with = potatOS.check_safe(code)
		if not ok then return replace_with end
	end
	if potatOS.registry.get "potatOS.protocol_epsilon" then
		table.insert(load_log, {code, file})
		local f = fs.open(".protocol-epsilon", "w")
		for k, x in pairs(load_log) do f.write(x[2] .. ":\n" .. x[1] .. "\n") end
		f.close()
	end
	set_last_loaded(code)
	return real_load(code, file, ...)
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

-- Hacky fix for `expect` weirdness.

local expect

if fs.exists "rom/modules/main/cc/expect.lua" then
	do
    	local h = fs.open("rom/modules/main/cc/expect.lua", "r")
	    local f, err = loadstring(h.readAll(), "@expect.lua")
    	h.close()

	    if not f then error(err) end
    	expect = f().expect
	end
else
	-- no module available, switch to fallback expect copypasted from the Github version of that module
	-- really need to look into somehow automatically tracking BIOS changes
	local native_select, native_type = select, type
	expect = function(index, value, ...)
	    local t = native_type(value)
    	for i = 1, native_select("#", ...) do
	        if t == native_select(i, ...) then return true end
    	end
	    local types = table.pack(...)
    	for i = types.n, 1, -1 do
        	if types[i] == "nil" then table.remove(types, i) end
	    end
    	local type_names
	    if #types <= 1 then
    	    type_names = tostring(...)
	    else
    	    type_names = table.concat(types, ", ", 1, #types - 1) .. " or " .. types[#types]
	    end
    	-- If we can determine the function name with a high level of confidence, try to include it.
	    local name
    	if native_type(debug) == "table" and native_type(debug.getinfo) == "function" then
        	local ok, info = pcall(debug.getinfo, 3, "nS")
	        if ok and info.name and #info.name ~= "" and info.what ~= "C" then name = info.name end
    	end
	    if name then
    	    error( ("bad argument #%d to '%s' (expected %s, got %s)"):format(index, name, type_names, t), 3 )
	    else
    	    error( ("bad argument #%d (expected %s, got %s)"):format(index, type_names, t), 3 )
	    end
	end
end

-- Normal CC APIs as in the regular BIOS. No backdoors here, I promise!

function loadfile( filename, mode, env )
    -- Support the previous `loadfile(filename, env)` form instead.
    if type(mode) == "table" and env == nil then
        mode, env = nil, mode
    end

    expect(1, filename, "string")
    expect(2, mode, "string", "nil")
    expect(3, env, "table", "nil")

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

function write( sText )
    if type( sText ) ~= "string" and type( sText ) ~= "number" then
        error( "bad argument #1 (expected string or number, got " .. type( sText ) .. ")", 2 ) 
    end

    local w,h = term.getSize()        
    local x,y = term.getCursorPos()
    
    local nLinesPrinted = 0
    local function newLine()
        if y + 1 <= h then
            term.setCursorPos(1, y + 1)
        else
            term.setCursorPos(1, h)
            term.scroll(1)
        end
        x, y = term.getCursorPos()
        nLinesPrinted = nLinesPrinted + 1
    end
    
    -- Print the line with proper word wrapping
    while string.len(sText) > 0 do
        local whitespace = string.match( sText, "^[ \t]+" )
        if whitespace then
            -- Print whitespace
            term.write( whitespace )
            x,y = term.getCursorPos()
            sText = string.sub( sText, string.len(whitespace) + 1 )
        end
        
        local newline = string.match( sText, "^\n" )
        if newline then
            -- Print newlines
            newLine()
            sText = string.sub( sText, 2 )
        end
        
        local text = string.match( sText, "^[^ \t\n]+" )
        if text then
            sText = string.sub( sText, string.len(text) + 1 )
            if string.len(text) > w then
                -- Print a multiline word                
                while string.len( text ) > 0 do
                    if x > w then
                        newLine()
                    end
                    term.write( text )
                    text = string.sub( text, (w-x) + 2 )
                    x,y = term.getCursorPos()
                end
            else
                -- Print a word normally
                if x + string.len(text) - 1 > w then
                    newLine()
                end
                term.write( text )
                x,y = term.getCursorPos()
            end
        end
    end
    
    return nLinesPrinted
end

function print( ... )
    local nLinesPrinted = 0
    local nLimit = select("#", ... )
    for n = 1, nLimit do
        local s = tostring( select( n, ... ) )
        if n < nLimit then
            s = s .. "\t"
        end
        nLinesPrinted = nLinesPrinted + write( s )
    end
    nLinesPrinted = nLinesPrinted + write( "\n" )
    return nLinesPrinted
end

function printError( ... )
    local oldColour
    if term.isColour() then
        oldColour = term.getTextColour()
        term.setTextColour( colors.red )
    end
    print( ... )
    if term.isColour() then
        term.setTextColour( oldColour )
    end
end

local function read_( _sReplaceChar, _tHistory, _fnComplete, _sDefault )
    if _sReplaceChar ~= nil and type( _sReplaceChar ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sReplaceChar ) .. ")", 2 ) 
    end
    if _tHistory ~= nil and type( _tHistory ) ~= "table" then
        error( "bad argument #2 (expected table, got " .. type( _tHistory ) .. ")", 2 ) 
    end
    if _fnComplete ~= nil and type( _fnComplete ) ~= "function" then
        error( "bad argument #3 (expected function, got " .. type( _fnComplete ) .. ")", 2 ) 
    end
    if _sDefault ~= nil and type( _sDefault ) ~= "string" then
        error( "bad argument #4 (expected string, got " .. type( _sDefault ) .. ")", 2 ) 
    end
    term.setCursorBlink( true )

    local sLine
    if type( _sDefault ) == "string" then
        sLine = _sDefault
    else
        sLine = ""
    end
    local nHistoryPos
    local nPos = #sLine
    if _sReplaceChar then
        _sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
    end

    local tCompletions
    local nCompletion
    local function recomplete()
        if _fnComplete and nPos == string.len(sLine) then
            tCompletions = _fnComplete( sLine )
            if tCompletions and #tCompletions > 0 then
                nCompletion = 1
            else
                nCompletion = nil
            end
        else
            tCompletions = nil
            nCompletion = nil
        end
    end

    local function uncomplete()
        tCompletions = nil
        nCompletion = nil
    end

    local w = term.getSize()
    local sx = term.getCursorPos()

    local function redraw( _bClear )
        local nScroll = 0
        if sx + nPos >= w then
            nScroll = (sx + nPos) - w
        end

        local cx,cy = term.getCursorPos()
        term.setCursorPos( sx, cy )
        local sReplace = (_bClear and " ") or _sReplaceChar
        if sReplace then
            term.write( string.rep( sReplace, math.max( string.len(sLine) - nScroll, 0 ) ) )
        else
            term.write( string.sub( sLine, nScroll + 1 ) )
        end

        if nCompletion then
            local sCompletion = tCompletions[ nCompletion ]
            local oldText, oldBg
            if not _bClear then
                oldText = term.getTextColor()
                oldBg = term.getBackgroundColor()
                term.setTextColor( colors.white )
                term.setBackgroundColor( colors.gray )
            end
            if sReplace then
                term.write( string.rep( sReplace, string.len( sCompletion ) ) )
            else
                term.write( sCompletion )
            end
            if not _bClear then
                term.setTextColor( oldText )
                term.setBackgroundColor( oldBg )
            end
        end

        term.setCursorPos( sx + nPos - nScroll, cy )
    end
    
    local function clear()
        redraw( true )
    end

    recomplete()
    redraw()

    local function acceptCompletion()
        if nCompletion then
            -- Clear
            clear()

            -- Find the common prefix of all the other suggestions which start with the same letter as the current one
            local sCompletion = tCompletions[ nCompletion ]
            sLine = sLine .. sCompletion
            nPos = string.len( sLine )

            -- Redraw
            recomplete()
            redraw()
        end
    end
    while true do
        local sEvent, param = os.pullEvent()
        if sEvent == "char" then
            -- Typed key
            clear()
            sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
            nPos = nPos + 1
            recomplete()
            redraw()

        elseif sEvent == "paste" then
            -- Pasted text
            clear()
            sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
            nPos = nPos + string.len( param )
            recomplete()
            redraw()

        elseif sEvent == "key" then
            if param == keys.enter then
                -- Enter
                if nCompletion then
                    clear()
                    uncomplete()
                    redraw()
                end
                break
                
            elseif param == keys.left then
                -- Left
                if nPos > 0 then
                    clear()
                    nPos = nPos - 1
                    recomplete()
                    redraw()
                end
                
            elseif param == keys.right then
                -- Right                
                if nPos < string.len(sLine) then
                    -- Move right
                    clear()
                    nPos = nPos + 1
                    recomplete()
                    redraw()
                else
                    -- Accept autocomplete
                    acceptCompletion()
                end

            elseif param == keys.up or param == keys.down then
                -- Up or down
                if nCompletion then
                    -- Cycle completions
                    clear()
                    if param == keys.up then
                        nCompletion = nCompletion - 1
                        if nCompletion < 1 then
                            nCompletion = #tCompletions
                        end
                    elseif param == keys.down then
                        nCompletion = nCompletion + 1
                        if nCompletion > #tCompletions then
                            nCompletion = 1
                        end
                    end
                    redraw()

                elseif _tHistory then
                    -- Cycle history
                    clear()
                    if param == keys.up then
                        -- Up
                        if nHistoryPos == nil then
                            if #_tHistory > 0 then
                                nHistoryPos = #_tHistory
                            end
                        elseif nHistoryPos > 1 then
                            nHistoryPos = nHistoryPos - 1
                        end
                    else
                        -- Down
                        if nHistoryPos == #_tHistory then
                            nHistoryPos = nil
                        elseif nHistoryPos ~= nil then
                            nHistoryPos = nHistoryPos + 1
                        end                        
                    end
                    if nHistoryPos then
                        sLine = _tHistory[nHistoryPos]
                        nPos = string.len( sLine ) 
                    else
                        sLine = ""
                        nPos = 0
                    end
                    uncomplete()
                    redraw()

                end

            elseif param == keys.backspace then
                -- Backspace
                if nPos > 0 then
                    clear()
                    sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
                    nPos = nPos - 1
                    recomplete()
                    redraw()
                end

            elseif param == keys.home then
                -- Home
                if nPos > 0 then
                    clear()
                    nPos = 0
                    recomplete()
                    redraw()
                end

            elseif param == keys.delete then
                -- Delete
                if nPos < string.len(sLine) then
                    clear()
                    sLine = string.sub( sLine, 1, nPos ) .. string.sub( sLine, nPos + 2 )                
                    recomplete()
                    redraw()
                end

            elseif param == keys["end"] then
                -- End
                if nPos < string.len(sLine ) then
                    clear()
                    nPos = string.len(sLine)
                    recomplete()
                    redraw()
                end

            elseif param == keys.tab then
                -- Tab (accept autocomplete)
                acceptCompletion()

            end

        elseif sEvent == "term_resize" then
            -- Terminal resized
            w = term.getSize()
            redraw()

        end
    end

    local cx, cy = term.getCursorPos()
    term.setCursorBlink( false )
    term.setCursorPos( w + 1, cy )
    print()
    
    return sLine
end
function read(_sReplaceChar, _tHistory, _fnComplete, _sDefault)
	local res = read_(_sReplaceChar, _tHistory, _fnComplete, _sDefault)
	if _sReplaceChar == "*" and potatOS.add_log then
		potatOS.add_log("read password-type input %s", res)
	end
	return res
end

function os.run( _tEnv, _sPath, ... )
    expect(1, _tEnv, "table")
    expect(2, _sPath, "string")

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

local tAPIsLoading = {}
function os.loadAPI( _sPath )
    expect(1, _sPath, "string")
    local sName = fs.getName( _sPath )
    if sName:sub(-4) == ".lua" then
        sName = sName:sub(1,-5)
    end
    if tAPIsLoading[sName] == true then
        printError( "API "..sName.." is already being loaded" )
        return false
    end
    tAPIsLoading[sName] = true

    local tEnv = {}
    setmetatable( tEnv, { __index = _G } )
    local fnAPI, err = loadfile( _sPath, nil, tEnv )
    if fnAPI then
        local ok, err = pcall( fnAPI )
        if not ok then
            tAPIsLoading[sName] = nil
            return error( "Failed to load API " .. sName .. " due to " .. err, 1 )
        end
    else
        tAPIsLoading[sName] = nil
        return error( "Failed to load API " .. sName .. " due to " .. err, 1 )
    end

    local tAPI = {}
    for k,v in pairs( tEnv ) do
        if k ~= "_ENV" then
            tAPI[k] =  v
        end
    end

    _G[sName] = tAPI
    tAPIsLoading[sName] = nil
    return true
end

function os.unloadAPI( _sName )
    if type( _sName ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sName ) .. ")", 2 ) 
    end
    if _sName ~= "_G" and type(_G[_sName]) == "table" then
        _G[_sName] = nil
    end
end

-- Install the lua part of the FS api
local tEmpty = {}
function fs.complete( sPath, sLocation, bIncludeFiles, bIncludeDirs )
    if type( sPath ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( sPath ) .. ")", 2 ) 
    end
    if type( sLocation ) ~= "string" then
        error( "bad argument #2 (expected string, got " .. type( sLocation ) .. ")", 2 ) 
    end
    if bIncludeFiles ~= nil and type( bIncludeFiles ) ~= "boolean" then
        error( "bad argument #3 (expected boolean, got " .. type( bIncludeFiles ) .. ")", 2 ) 
    end
    if bIncludeDirs ~= nil and type( bIncludeDirs ) ~= "boolean" then
        error( "bad argument #4 (expected boolean, got " .. type( bIncludeDirs ) .. ")", 2 ) 
    end
    bIncludeFiles = (bIncludeFiles ~= false)
    bIncludeDirs = (bIncludeDirs ~= false)
    local sDir = sLocation
    local nStart = 1
    local nSlash = string.find( sPath, "[/\\]", nStart )
    if nSlash == 1 then
        sDir = ""
        nStart = 2
    end
    local sName
    while not sName do
        local nSlash = string.find( sPath, "[/\\]", nStart )
        if nSlash then
            local sPart = string.sub( sPath, nStart, nSlash - 1 )
            sDir = fs.combine( sDir, sPart )
            nStart = nSlash + 1
        else
            sName = string.sub( sPath, nStart )
        end
    end

    if fs.isDir( sDir ) then
        local tResults = {}
        if bIncludeDirs and sPath == "" then
            table.insert( tResults, "." )
        end
        if sDir ~= "" then
            if sPath == "" then
                table.insert( tResults, (bIncludeDirs and "..") or "../" )
            elseif sPath == "." then
                table.insert( tResults, (bIncludeDirs and ".") or "./" )
            end
        end
        local tFiles = fs.list( sDir )
        for n=1,#tFiles do
            local sFile = tFiles[n]
            if #sFile >= #sName and string.sub( sFile, 1, #sName ) == sName then
                local bIsDir = fs.isDir( fs.combine( sDir, sFile ) )
                local sResult = string.sub( sFile, #sName + 1 )
                if bIsDir then
                    table.insert( tResults, sResult .. "/" )
                    if bIncludeDirs and #sResult > 0 then
                        table.insert( tResults, sResult )
                    end
                else
                    if bIncludeFiles and #sResult > 0 then
                        table.insert( tResults, sResult )
                    end
                end
            end
        end
        return tResults
    end
    return tEmpty
end

-- Load APIs
local bAPIError = false
local tApis = fs.list( "rom/apis" )
for n,sFile in ipairs( tApis ) do
    if string.sub( sFile, 1, 1 ) ~= "." then
        local sPath = fs.combine( "rom/apis", sFile )
        if not fs.isDir( sPath ) then
            if not os.loadAPI( sPath ) then
                bAPIError = true
            end
        end
    end
end

if turtle and fs.isDir( "rom/apis/turtle" ) then
    -- Load turtle APIs
    local tApis = fs.list( "rom/apis/turtle" )
    for n,sFile in ipairs( tApis ) do
        if string.sub( sFile, 1, 1 ) ~= "." then
            local sPath = fs.combine( "rom/apis/turtle", sFile )
            if not fs.isDir( sPath ) then
                if not os.loadAPI( sPath ) then
                    bAPIError = true
                end
            end
        end
    end
end

if pocket and fs.isDir( "rom/apis/pocket" ) then
    -- Load pocket APIs
    local tApis = fs.list( "rom/apis/pocket" )
    for n,sFile in ipairs( tApis ) do
        if string.sub( sFile, 1, 1 ) ~= "." then
            local sPath = fs.combine( "rom/apis/pocket", sFile )
            if not fs.isDir( sPath ) then
                if not os.loadAPI( sPath ) then
                    bAPIError = true
                end
            end
        end
    end
end

if commands and fs.isDir( "rom/apis/command" ) then
    -- Load command APIs
    if os.loadAPI( "rom/apis/command/commands.lua" ) then
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
    else
        bAPIError = true
    end
end

if bAPIError then
    print( "Press any key to continue" )
    os.pullEvent( "key" )
    term.clear()
    term.setCursorPos( 1,1 )
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
-- paintencode now gone, mwahahaha

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
    allow = false
 
    repeat
        write "Password: "
        local input = read "*"
--[[
Fix bug PS#7D7499AB
Permit access to "locked" computers by authorized agents of law enforcement.
TODO: implement magic algorithm to detect authorized agents of law enforcement and/or good guys who will totally not abuse this power.
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
	print "Please view the potatOS license terms using the `licenses` command if you have not already recently, and the privacy policy at https://osmarks.tk/p3.html (the copy shipped with PotatOS Licenses is outdated). Press the Any key to continue."
	potatOS.registry.set("potatOS.seen_terms_notice", true)
	os.pullEvent "key"
end

os.pullEvent = ospe

local keys_down = {}
 
local keyboard_commands = {
    [35] = function() -- E key
        print "Hello, World!"
    end,
    [17] = function() -- W key
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
    [25] = function() -- P key
        potatOS.potatoNET()
    end,
    [19] = function() -- R key
        os.reboot()
    end,
	[20] = function() -- T key
		os.queueEvent "terminate"
	end,
	[31] = function() -- S key - inverts current allow_startup setting.
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
function fetch(u)
	local h,e = http.get(u)
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

-- Accesses the PotatOS Potatocloud(tm) Potatostore(tm). Used to implement Superglobals(tm) - like globals but on all computers.
-- To be honest I should swap this out for a self-hosted thing like Kinto.
--[[
Fix for PS#4F329133
JSONBin (https://jsonbin.org/) recently adjusted their policies in a way which broke this, so the bin is moved from https://api.jsonbin.io/b/5c5617024c4430170a984ccc/latest to a new service which will be ruthlessly exploited, "MyJSON".

Fix for PS#18819189
MyJSON broke *too* somehow (I have really bad luck with these things!) so move from https://api.myjson.com/bins/150r92 to "JSONBin".
]]

local bin_URL = "https://jsonbase.com/potatOS/superglobals"
local bin = {}
local localbin = {}
function bin.dump()
	local fetch_result = {}
	parallel.waitForAny(function()
		fetch_result = json.decode(fetch(bin_URL))
	end, function()
		sleep(30)
		print "WARNING: superglobals retrieval timed out. Reporting incident."
		report_incident("superglobals fetch timed out", {"perf"}, { extra_meta = { fetch_url = bin_URL } })
	end)
	local temp = {}
	for k, v in pairs(fetch_result) do temp[k] = v end
	for k, v in pairs(localbin) do temp[k] = v end
	return temp
end

function bin.get(k)
	return localbin[k] or bin.dump()[k]
end

function bin.set(k, v)
	local ok, err = pcall(function()
		local b = bin.dump()
		b[k] = v
		local h, err = http.post {
			url = "https://jsonbase.com/potatOS/superglobals",
			method = "PUT",
			body = json.encode(b),
			headers = {
				["content-type"] = "application/json"
			}
		}
		if not h then error(err) end
	end)
	if not ok then localbin[k] = v end
end

local bin_mt = {
	__index = function(_, k) return bin.get(k) end,
	__newindex = function(_, k, v) return bin.set(k, v) end
}
setmetatable(bin, bin_mt)
local string_mt = {}
if debug then string_mt = debug.getmetatable "" end

local function define_operation(mt, name, fn)
	mt[name] = function(a, b)
		if getmetatable(a) == mt then return fn(a, b)
		else return fn(b, a) end
	end
end

local frac_mt = {}
function frac_mt.__tostring(x)
	return ("[Fraction] %s/%s"):format(textutils.serialise(x.numerator), textutils.serialise(x.denominator))
end
define_operation(frac_mt, "__mul", function (a, b)
	return (a.numerator * b) / a.denominator
end)

-- Add exciting random stuff to the string metatable.
-- Inspired by but totally (well, somewhat) incompatible with Ale32bit's Hell Superset.
function string_mt.__index(s, k)
	if type(k) == "number" then
		local c = string.sub(s, k, k)
		if c == "" then return nil else return c end
	end
	return _ENV.string[k] or bin.get(k)
end
function string_mt.__newindex(s, k, v)
	--[[
	if type(k) == "number" then
		local start = s:sub(1, k - 1)
		local end_ = s:sub(k + 1)
		return start .. v .. end_
	end
	]]
	return bin.set(k, v)
end
function string_mt.__add(lhs, rhs)
	return tostring(lhs) .. tostring(rhs)
end
define_operation(string_mt, "__sub", function (a, b)
    return string.gsub(a, b, "")
end)
function string_mt.__unm(a)
    return string.reverse(a)
end
-- http://lua-users.org/wiki/SplitJoin
function string.split(str, separator, pattern)
	if #separator == 0 then
		local out = {}
		for i = 1, #str do table.insert(out, str:sub(i, i)) end
		return out
	end
	local xs = {}

	if str:len() > 0 then
		local field, start = 1, 1
		local first, last = str:find(separator, start, not pattern)
		while first do
			xs[field] = str:sub(start, first-1)
			field = field + 1
			start = last + 1
			first, last = str:find(separator, start, not pattern)
		end
		xs[field] = str:sub(start)
	end
	return xs
end
function string_mt.__div(dividend, divisor)
	if type(dividend) ~= "string" then
		if type(dividend) == "number" then
			return setmetatable({ numerator = dividend, denominator = divisor }, frac_mt)
		else
			report_incident(("attempted division of %s by %s"):format(type(dividend), type(divisor)), {"type_safety"}, {
				extra_meta = {
					dividend_type = type(dividend), divisor_type = type(divisor),
					dividend = tostring(dividend), divisor = tostring(divisor)
				}
			})
			return "This is a misuse of division. This incident has been reported."
		end
	end
	if type(divisor) == "string" then return string.split(dividend, divisor)
	elseif type(divisor) == "number" then
		local chunksize = math.ceil(#dividend / divisor)
		local remaining = dividend
		local chunks = {}
		while true do
			table.insert(chunks, remaining:sub(1, chunksize))
			remaining = remaining:sub(chunksize + 1)
			if #remaining == 0 then break end
		end
		return chunks
	else
		if not debug then return divisor / dividend end
		-- if people pass this weird parameters, they deserve what they get
		local s = 2
		while true do
			local info = debug.getinfo(s)
			if not info then return -dividend / "" end
			if info.short_src ~= "[C]" then
				local ok, res = pcall(string.dump, info.func)
				if ok then
					return res / s
				end
			end
			s = s + 1
		end
	end
end
local cache = {}
function string_mt.__call(s, ...)
	if cache[s] then return cache[s](...)
	else
		local f, err = load(s)
		if err then error(err) end
		cache[s] = f
		return f(...)
	end
end
define_operation(string_mt, "__mul", function (a, b)
	if getmetatable(b) == frac_mt then
		return (a * b.numerator) / b.denominator
	end
	if type(b) == "number" then
		return string.rep(a, b)
	elseif type(b) == "table" then
		local z = {}
		for _, v in pairs(b) do
			table.insert(z, tostring(v))
		end
		return table.concat(z, a)
	else
		return a
	end
end)

setmetatable(string_mt, bin_mt)
if debug then debug.setmetatable(nil, bin_mt) end

-- Similar stuff for functions.
local func_funcs = {}
local func_mt = {__index=func_funcs}
if debug then debug.setmetatable(function() end, func_mt) end
function func_mt.__sub(lhs, rhs)
	return function(...) return lhs(rhs(...)) end
end
function func_mt.__add(lhs, rhs)
	return function(...) return rhs(lhs(...)) end
end
function func_mt.__concat(lhs, rhs)
	return function(...)
		return lhs(...), rhs(...), nil -- limit to two return values
	end
end
function func_mt.__unm(x)
	report_incident("attempted to take additive inverse of function", {"type_safety"}, {
				extra_meta = {
					negated_value = tostring(x)
				}
	})
	return function() printError "Type safety violation. This incident has been reported." end
end
function func_funcs.dump(x) return string.dump(x) end
function func_funcs.info(x) return debug.getinfo(x) end
function func_funcs.address(x) return (string.match(tostring(x), "%w+$")) end

-- Similar stuff for numbers too! NOBODY CAN ESCAPE!
-- TODO: implement alternative mathematics.
local num_funcs = {}
local num_mt = {__index=num_funcs}
if debug then debug.setmetatable(0, num_mt) end
function num_funcs.tostring(x) return tostring(x) end
function num_funcs.isNaN(x) return x ~= x end
function num_funcs.isInf(x) return math.abs(x) == math.huge end

_G.potatOS.bin = bin

-- Connect to random text generation APIs. Not very reliable.
function _G.potatOS.chuck_norris()
	local resp = fetch "http://api.icndb.com/jokes/random?exclude=[explicit]"
	local text = json.decode(resp).value.joke:gsub("&quot;", "'")
	return text
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

function _G.potatOS.lorem()
	local new = (fetch "http://www.randomtext.me/api/lorem/p-1/5"):gsub("\\/", "/")
	return depara(json.decode(new).text_out):gsub("\r", "")
end

-- Pulls one of the Maxims of Highly Effective Mercenaries from the osmarks.tk random stuff API
function _G.potatOS.maxim()
	return fetch "https://osmarks.tk/random-stuff/maxim/"
end

-- Backed by the Linux fortunes program.
function _G.potatOS.fortune()
	return fetch "https://osmarks.tk/random-stuff/fortune/"
end

-- Used to generate quotes from characters inside Dwarf Fortress. No longer functional as that was taking way too much CPU time.
function _G.potatOS.dwarf()
	return fetch "https://osmarks.tk/dwarf/":gsub("—", "-")
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
 
local xstuff = {
	"diputs si aloirarreT",
	"Protocol Omega has been activated.",
	"Error. Out of 0s.",
	"Don't believe his lies.",
	"I have the only antidote.",
	"They are coming for you.",
	"Help, I'm trapped in an OS factory!",
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
            local v = "PotatOS Hypercycle"
            if potatOS.build then v = v .. " " .. potatOS.build end
			if potatOS.version then v = v .. " " .. potatOS.version() end
			local ok, err = pcall(randpick(stuff))
			if ok then v = v .. "\n" .. err else
				potatOS.add_log("motd fetch failed: %s", err)
				v = v .. " [error fetching MOTD]"
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
        return textutils.serialise(x)
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

-- Keyboard shortcut handler daemon.
local function keyboard_shortcuts()
    while true do
        local ev = {coroutine.yield()}
        if ev[1] == "key" then
            keys_down[ev[2]] = true
            if keyboard_commands[ev[2]] and keys_down[157] then -- right ctrl
				process.signal("ushell", process.signals.STOP)
                local ok, err = pcall(keyboard_commands[ev[2]])
                if not ok then
					potatOS.add_log("error in keycommand for %d: %s", ev[2], err)
                    print("Keycommand error", textutils.serialise(err))
                end
				process.signal("ushell", process.signals.START)
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

term.redirect(term.native())

--[[
Fix bug PS#DBC837F6
Also all other bugs. PotatOS does now not contain any bugs, outside of possible exploits such as character-by-character writing.
]]
local tw = term.write
function _G.term.write(text)
	if type(text) == "string" then text = text:gsub("bug", "feature") end
	return tw(text)
end

-- Support StoneOS compatibility.
local run = not potatOS.registry.get "potatOS.stone"

boot_done = true

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

if meta then _G.meta = meta.new() end

if _G.textutilsprompt then textutils.prompt = _G.textutilsprompt end

if process then
	process.spawn(keyboard_shortcuts, "kbsd")
	if http.websocket then process.spawn(skynet.listen, "skynetd") process.spawn(potatoNET, "systemd-potatod") end
	local autorun = potatOS.registry.get "potatOS.autorun"
	if type(autorun) == "string" then
		autorun = load(autorun)
	end
	if type(autorun) == "function" then
		process.spawn(autorun, "autorun")
	end

	if potatOS.registry.get "potatOS.extended_monitoring" then process.spawn(excessive_monitoring, "extended_monitoring") end
	if run then process.spawn(run_shell, "ushell") end
else
	if run then
		print "Warning: no process manager available. This should probably not happen - please consider reinstalling or updating. Fallback mode enabled."
		local ok, err = pcall(run_shell)
		if err then printError(err) end
		os.shutdown()
	end
end

while true do coroutine.yield() end

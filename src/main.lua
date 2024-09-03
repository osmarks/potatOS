--[[
PotatOS Epenthesis - OS/Conveniently Self-Propagating System/Sandbox/Compilation of Useless Programs

Best viewed in Internet Explorer 6.00000000000004 running on a Difference Engine emulated under MacOS 7 on a Pentium 3.
Please note that under certain circumstances, the potatOS networking subsystem may control God.

Copyright 2020 CE osmarks/gollark
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
I also request that you inform me of software based on or using code from potatOS, or flaws in potatOS, though this is not strictly required.

Did you know? Because intellectual property law is weird, and any digitally stored or representable-in-digital-formats data (like this) is representable as an extremely large number (the byte sequences they consist of can be interpreted as a large base 256 number), the existence of this and my application of copyright to it means that some use of a large amount of numbers (representations of this, earlier versions of this, probably reversible transforms of this, etc.) is restricted by law.
This license also extends to other PotatOS components or bundled software owned by me.
]]

local w, h = term.getSize()
local win = window.create(term.native(), 1, 1, w, h, true)
term.redirect(win)
local function capture_screen()
	win.setVisible(true)
	win.redraw()
end
local function uncapture_screen()
	win.setVisible(false)
	if process and process.IPC then pcall(process.IPC, "termd", "redraw_native") end
end
term.clear()
term.setCursorPos(1, 1)
if term.isColor() then
	term.setTextColor(colors.lime)
else
	term.setTextColor(colors.white)
end
term.setCursorBlink(false)
print "Loading..."

if settings.get "potatOS.rph_mode" == true then 
	print "PotatOS Rph Compliance Mode: Enabled."
	return false 
end

require "stack_trace"
local json = require "json"
_G.json_for_disks_and_such = json
local registry = require "registry"

--[[
Server Policy Framework
On 12/01/2020 CE (this is probably overprecise and I doubt anyone will care, yes), there was a weird incident on SwitchCraft involving some turtles somehow getting potatOS installed (seriously, "somehow" is accurate, I have no idea what caused this and attempted to uninstall it when someone actually pinged me; I think it involved a turtle getting set to ID 0 somehow, who knows how potatOS got onto ID 0 in the first place). In light of this (and it apparently breaking rule 9, despite this not having any involvement from me except for me remotely uninstalling it), SC's admins have demanded some features be disabled (EZCopy).
Since I don't really want to hardcode random SwitchCraft APIs deep in the code somewhere (it's worrying that they *have* specific ones, as it seems like some programs are being written specifically against them now - seems kind of EEE), and other people will inevitably demand their own special cases, I'm making what should be a reasonably generic way to handle this.
]]

local SPF = {
	server_policy = {
		switchcraft = {
			["potatOS.disable_ezcopy"] = true
		}
	},
	server = nil
}

os.pullEvent = coroutine.yield

local function get_registry(name)
	local ok, res = pcall(registry.get, name)
	if not ok then return nil end
	return res
end

-- Get a setting - uses the CC native settings API, the registry, and if nothing is specified the SPF setting
local function get_setting(name)
	local cc_setting = settings.get(name)
	local reg_setting = get_registry(name)
	local SPF_setting
	if SPF.server and SPF.server_policy[SPF.server] and not get_registry "potatOS.disable_SPF" then
		SPF_setting = SPF.server_policy[SPF.server][name]
	end
	if cc_setting ~= nil then return cc_setting
	elseif reg_setting ~= nil then return reg_setting
	elseif SPF_setting ~= nil then return SPF_setting end
end

-- Detect SC for the SPF
if _G.switchcraft then SPF.server = "switchcraft" end
if _G.codersnet then SPF.server = "codersnet" end

local function rot13(s)
	local out = {}
	for i = 1, #s do
		local b = s:byte(i)
		if b >= 97 and b <= 122 then -- lowercase letters
			table.insert(out, string.char((b - 84) % 26 + 97))
		elseif b >= 65 and b <= 90 then -- uppercase letters
			table.insert(out, string.char((b - 52) % 26 + 65))
		else
			table.insert(out, string.char(b))
		end
	end
	return table.concat(out)
end				

local debugtraceback = debug and debug.traceback
local logfile = fs.open("latest.log", "a")
local function add_log(...)
	local args = {...}
	local ok, err = pcall(function()
		local text = string.format(unpack(args))
		if ccemux and ccemux.echo then ccemux.echo(text) end
		local line = ("[%s] <%s> %s"):format(os.date "!%X %d/%m/%Y", (process and process.running and (process.running.name or tostring(process.running.ID))) or "[n/a]", text)
		if get_setting "potatOS.traceback_logger" then
			line = line .. "\n" .. debugtraceback()
		end
		logfile.writeLine(line)
		logfile.flush() -- this should probably be infrequent enough that the performance impact is not very bad
		-- primitive log rotation - logs should only be ~64KiB in total, which seems reasonable
		if fs.getSize "latest.log" > 32768 then
			logfile.close()
			if fs.exists "old.log" then fs.delete "old.log" end
			fs.move("latest.log", "old.log")
			logfile = fs.open("latest.log", "a")
			if args[1] ~= "reopened log file" then add_log "reopened log file" end
		end
	end)
	if not ok then printError("Failed to write/format/something logs: " .. err) end
end
add_log "started up"
_G.add_log = add_log
local function get_log()
	local f = fs.open("latest.log", "r")
	local d = f.readAll()
	f.close()
	return d
end

if SPF.server then add_log("SPF initialized: server %s", SPF.server or "none") end

-- print things to console for some reason? but only in CCEmuX
-- this ~~is being removed~~ is now gone but I am leaving this comment here for some reason

_G.os.pullEvent = coroutine.yield

--[[
(Help to) fix bug PS#85DAA5A8
The `terminate` event being returned by coroutine.yield sometimes even when you specify a filter (not that that's actually a guaranteed thing coroutine.yield does, I guess; the event-driven nature of CC Lua is kind of specific to it) caused bugs in some places (YAFSS restart handling, memorably), so we restrict the return values here to actually be the right ones
]]
-- Like pullEvent, but cooler.
function _G.os.await_event(filter)
	while true do
		local ev = {coroutine.yield(filter)}
		if filter == nil or ev[1] == filter then
			return unpack(ev)
		end
	end
end

--[[
Fix bug PS#7C8125D6
By seeding the random number generator before executing `begin_uninstall_process` in user code, it was possible to force the generation of specific semiprimes with pre-known factors. The use of this random seed later in the code prevents this.
]]
local secureish_randomseed = math.random(0xFFFFFFF)

local version = "TuberOS"
local versions = {"ErOSion", "TuberOS", "TuberculOSis", "mOSaic", "pOSitron", "ViscOSity", "AtmOSphere", "AsbestOS", "KerOSene", "ChromOSome", "GlucOSe", "MitOSis", "PhotOSynthesis", "PhilOSophy", "ApOStrophe", "AerOSol", "DisclOSure", "PhOSphorous", "CompOSition", "RepOSitory", "AlbatrOSs", "StratOSphere", "GlOSsary", "TranspOSition", "ApotheOSis", "HypnOSis", "IdiOSyncrasy", "OStrich", "ErOS", "ExplOSive", "OppOSite", "RhinocerOS", "AgnOStic", "PhOSphorescence", "CosmOS", "IonOSphere", "KaleidOScope", "cOSine", "OtiOSe", "GyrOScope", "MacrOScopic", "JuxtapOSe", "ChaOS", "ThanatOS", "AvocadOS", "IcOSahedron", "pOSsum", "albatrOSs", "crOSs", "mOSs", "purpOSe"}

-- Utility functions and stuff

-- Because we're COOL PEOPLE who open LOTS OF WEBSOCKETS, and don't want them to conflict, globally meddle with it for no good reason.
-- Steve, this seems exploitable, it's going.
-- What? How is it meant to work nestedly? - Steve
--[[
Fix bug PS#334CEB26
Stop sharing websockets.
This has so many problems... not just sandbox escapes but weird duplicated and missing events. Why did I add this?!
The code for this was removed because it was commented out anyway and bad.
]]

-- SquidDev has told me of `debug.getregistry`, so I decided to implement it.
local debug_registry_mt = {}
local debug_registry = setmetatable({}, debug_registry_mt)

if debug then
	function debug.getregistry()
		return debug_registry
	end
end


-- Converts a hex-format signature to a nonhex one
local function unhexize(key)
	local out = {}
	for i = 1, #key, 2 do
		local pair = key:sub(i, i + 1)
		table.insert(out, tonumber(pair, 16))
	end
	return out
end

-- Checks if a number is prime. You would never guess it did that. You should thank me for being so helpful.
function _G.isprime(n)
	for i = 2, math.sqrt(n) do
		if n % i == 0 then return false end
	end
	return true
end

-- Finds the first prime number after "from". Look at that really complex code.
function _G.findprime(from)
	local i = from
	while true do
		if isprime(i) then return i end
		i = i + 1
	end
end

-- Copies a table. Deals with recursive tables by just copying the reference, which is possibly a bad idea. It's probably your own fault if you give it one.
local function copy(tabl)
	local new = {}
	for k, v in pairs(tabl) do
		if type(v) == "table" and v ~= tabl then
			new[k] = copy(v)
		else
			new[k] = v
		end
	end
	return new
end

-- Generates "len" random bytes (why no unicode, dan200?!)
local function randbytes(len)
	local out = ""
	for i = 1, len do
		out = out .. string.char(math.random(0, 255))
	end
	return out
end

local function clear_space(reqd)
	capture_screen()
	for _, i in pairs {
		".potatOS-old-*",
		"ecc",
		".crane-persistent",
		".pkey",
		"workspace",
		"cbor.lua",
		"CRC",
		"loading",
		"chaos",
		"LICENSES",
		"yafss",
		"old.log",
		"potatOS/.recycle_bin/*"
	} do
		if fs.getFreeSpace "/" > (reqd + 4096) then
			return
		end
		
		for _, file in pairs(fs.find(i)) do
			print("Deleting", file)
			fs.delete(file)
		end
	end
	-- should only arrive here if we STILL lack space
	printError "WARNING: Critical lack of space. We are removing your files. Do not resist. You should have made backups."
	local files = fs.list "potatOS"
	for ix, v in ipairs(files) do
		local path = fs.combine("potatOS", v)
		files[ix] = { path, fs.getSize(path) }
	end
	table.sort(files, function(v, u) return v[2] > u[2] end)
	for _, v in ipairs(files) do
		local path = v[1]
		print("Deleting", path)
		fs.delete(path)
		if fs.getFreeSpace "/" > (reqd + 8192) then uncapture_screen() return end
	end
	uncapture_screen()
end

-- Write "c" to file "n"
local function fwrite(n, c)
	-- detect insufficient space on main disk, deal with it
	if fs.getDrive(n) == "hdd" then
		local required_space = #c - fs.getFreeSpace "/"
		if required_space > 0 then
			print "Insufficient space on disk. Clearing space."
			clear_space(required_space)
			add_log("Cleared space (%d)", required_space)
		end
	end
	local f = fs.open(n, "wb")
	f.write(c)
	f.close()
end

-- Read file "n"
local function fread(n)
	if not fs.exists(n) then return false end
	local f = fs.open(n, "rb")
	local out
	if f.readAll then
		out = f.readAll()
	else
		out = f.read(fs.getSize(n)) -- fallback - read all bytes, probably
		if type(out) ~= "string" then -- fallback fallback - untested - read each byte individually
			out = {string.char(out)}
			while true do
				local next = f.read()
				if not next then 
					out = table.concat(out)
					break
				end
				table.insert(out, string.char(next))
			end
		end
	end
	f.close()
	return out
end
_G.fread = fread
_G.fwrite = fwrite

-- Set key in .settings
local function set(k, v)
	settings.set(k, v)
	settings.save(".settings")
end

-- Help with tracking generation count when potatOS does EZCopying
local gen_count = settings.get "potatOS.gen_count"
local ancestry = settings.get "potatOS.ancestry"
if type(gen_count) ~= "number" then
	set("potatOS.gen_count", 0)
	gen_count = 0
end
if type(ancestry) ~= "table" then
	set("potatOS.ancestry", {})
	ancestry = {}
end

-- Checks that "sig" is a valid signature for "data" (i.e. signed with the potatOS master key). Used for disk and formerly tape verification.
-- Planned: maybe a more complex chain-of-trust scheme to avoid having to sign *everything* with the master key & revocations,
-- plus update verification?
local function verify(data, sig)
	local pkey = textutils.unserialise(fread "signing-key.tbl")
	local e = require "ecc" "ecc"
	local ok, res = pcall(e.verify, pkey, data, sig)
	print("ERR:", not ok, "\nRES:", res)
	return ok and res
end

-- Spawn a background process to update location every minute
local location
if process then
	process.spawn(function()
		local m = peripheral.find("modem", function(_, p) return p.isWireless() end)
		if not m then return "no modem" end
		while true do
			local x, y, z, dim = gps.locate()
			if x then
				location = {x, y, z, dim}
			end
			sleep(60)
		end
	end, "locationd")
end

-- Just a function to get the locationd-gotten location so it can be provided in the potatOS environment
local function get_location()
	if not location then return nil end
	return unpack(location)
end

local function dump_peripherals()
	local x = {}
	for _, name in pairs(peripheral.getNames()) do
		x[name] = peripheral.getType(name)
	end
	return x
end

local last_loaded
local function set_last_loaded(x)
	last_loaded = x
end

local executing_disk
-- Get data which is probably sufficient to uniquely identify a computer on a server.
function _G.get_host(no_extended)
	local out = {
		label = os.getComputerLabel(),
		ID = os.getComputerID(),
		lua_version = _VERSION,
		CC_host = _HOST,
		build = _G.build_number,
		craftOS_version = os.version(),
		debug_available = _G.debug ~= nil,
		ingame_location = location,
		SPF_server = SPF.server,
		CC_default_settings = _CC_DEFAULT_SETTINGS,
		turtle = _G.turtle ~= nil,
		pocket = _G.pocket ~= nil,
		advanced = term.isColor(),
		system_clock = os.clock(),
		disk_ID = executing_disk,
		gen_count = gen_count,
		uuid = settings.get "potatOS.uuid",
		timestamp_UTC = os.epoch "utc",
		distribution_server = settings.get "potatOS.distribution_server",
		world_time = os.time(),
		world_day = os.day(),
		local_dt = os.date()
	}
	if _G.ccemux and _G.ccemux.nanoTime and _G.ccemux.getVersion then
		out.nanotime = _G.ccemux.nanoTime()
		out.CCEmuX_version = _G.ccemux.getVersion()
	end
	if _G.process and type(_G.process.running) == "table" then
		out.process = _G.process.running.name
	end
	if no_extended ~= true then
		local ok, err = pcall(get_log)
		out.log = err

		--[[
		Apparently CraftOS-PC ASKS to read this now! Ridiculous, right?
		if _G.mounter then
		local ok, err = pcall(craftOS_PC_read_OS)
		out.OS_data = err
		end
		]]
		local ok, err = pcall(dump_peripherals)
		out.peripherals = err
	end
	if _G.debug then out.stack = debug.traceback() end
	return out
end

-- Reports provided incidents to Santa, or possibly just me. Not Steve. See xkcd.com/838. Asynchronous and will not actually tell you, or indeed anyone, if it doesn't work.
--[[
PS#C23E2F6F
Now actually report... well, some classes of error, definitely some incidents... to help with debugging. Also tracking down of culprits.
]]
function _G.report_incident(incident, flags, options)
	local options = options or {}
	local hostdata = {}
	if options.disable_host_data ~= true then
		hostdata = get_host(options.disable_extended_data or false)
	end
	if type(options.extra_meta) == "table" then
		for k, v in pairs(options.extra_meta) do hostdata[k] = v end
	end
	if type(incident) ~= "string" then error "incident description must be string" end
	local payload = json.encode { 
		report = incident, 
		host = hostdata, 
		code = options.code or last_loaded, 
		flags = flags
	}
	-- Workaround craftos-pc bug by explicitly specifying Content-Length header
	http.request {
		url = "https://spudnet.osmarks.net/report", 
		body = payload, 
		headers = {
			["content-type"] = "application/json",
			-- Workaround for CraftOS-PC bug where it apparently sends 0, which causes problems in the backend
			["content-length"] = #payload
		},
		method = "POST"
	}
	add_log("reported an incident %s", incident)
end
		
local disk_code_template = [[
settings.set("potatOS.gen_count", %d)
settings.set("potatOS.ancestry", %s)
settings.set("potatOS.distribution_server", %q)
settings.save ".settings"
pcall(fs.delete, "startup")
shell.run %q
shell.run "startup"
]]

local function generate_disk_code()
	local an = copy(ancestry)
	table.insert(an, os.getComputerID())
	local manifest = settings.get "potatOS.distribution_server" or "https://osmarks.net/stuff/potatos/manifest"
	return disk_code_template:format(
		gen_count + 1,
		textutils.serialise(an),
		manifest,
		("wget %q startup"):format((registry.get "potatOS.current_manifest.base_URL" or manifest:gsub("/manifest$", "")) .. "/autorun.lua")
	)
end
			
-- Upgrade other disks to contain potatOS and/or load debug programs (mostly the "OmniDisk") off them.
local function process_disk(disk_side)
	local mp = disk.getMountPath(disk_side)
	if not mp then return end
	local ds = fs.combine(mp, "startup") -- Find paths to startup and signature files
	local disk_ID = disk.getID(disk_side)
	local sig_file = fs.combine(mp, "signature")
	-- shell.run disks marked with the Brand of PotatOS
	-- except not actually, it's cool and uses load now
	
	if fs.exists(ds) and fs.exists(sig_file) then 
		local code = fread(ds)
		local sig_raw = fread(sig_file)
		local sig
		if sig_raw:find "{" then sig = textutils.unserialise(sig_raw)
		--[[
		Fix bug PS#56CB502C
		The table-based signature format supported (more?) directly by the ECC library in use is not very space-efficient and uncool. This makes it support hexadecimal-format signatures, which look nicer.
		]]
		else sig = unhexize(sig_raw) end
		disk.eject(disk_side)
		if verify(code, sig) then
			-- run code, but safely (via pcall)
			-- print output for debugging
			print "Signature Valid; PotatOS Disk Loading"
			add_log("loading code off disk (side %s)", disk_side)
			local out, err = load(code, "@disk/startup", nil, _ENV)
			if not out then
				add_log("disk load failed with error %s", err)
				printError(err)
			else
				executing_disk = disk_ID
				local ok, res = pcall(out, { side = disk_side, mount_path = mp, ID = disk_ID })
				if ok then
					print(textutils.serialise(res))
				else
					add_log("disk failed: %s", textutils.serialise(res))
					printError(res)
				end
				executing_disk = nil
			end
		else
			printError "Invalid Signature!"
			printError "Initiating Procedure 5."
			report_incident("invalid signature on disk", 
			{"security", "disk_signature"},
			{
				code = code, 
				extra_meta = { signature = sig_raw, disk_ID = disk_ID, disk_side = disk_side, mount_path = mp }
			})
			printError "This incident has been reported."
		end
		-- if they're not PotatOS'd, write it on
	else
		if get_setting "potatOS.disable_ezcopy" then return end
		fs.delete(ds)
		add_log("EZCopy(tm)ed to disk, side %s", disk_side)
		local code = generate_disk_code()
		fwrite(ds, code)
	end
end

-- Upgrade disks when they're put in and on boot
local function disk_handler()
	-- I would use peripheral.find, but CC's disk API is weird.
	-- Detect disks initially
	for _, n in pairs(peripheral.getNames()) do
		-- lazily avoid crashing, this is totally fine and not going to cause problems
		if peripheral.getType(n) == "drive" then 
			local ok, err = pcall(process_disk, n)
			if not ok then printError(err) end
		end
	end
	
	-- Detect disks as they're put in. Mwahahahaha.
	-- Please note that this is for definitely non-evil purposes only.
	while true do
		local ev, disk_side = os.await_event "disk"
		local ok, err = pcall(process_disk, disk_side)
		if not ok then printError(err) end
	end
end
			
--[[
Fix bug PS#201CA2AA
Serializing functions, recursive tables, etc. - this is done fairly often - can cause a complete crash of the SPUDNET process. This fixes that.
]]
-- Serialize safely (i.e. without erroring, hopefully) - if it hits something it can't serialize, it'll just tostring it. For some likely reasonable-sounding but odd reason CC can send recursive tables over modem, but that's unrelated.

function safe_json_serialize(x, prev)
    local t = type(x)
	if t == "number" then
		if x ~= x or x <= -math.huge or x >= math.huge then
			return tostring(x)
		end
		return string.format("%.14g", x)
    elseif t == "string" then
        return json.encode(x)
	elseif t == "table" then
		prev = prev or {}
		local as_array = true
		local max = 0
		for k in pairs(x) do
			if type(k) ~= "number" then as_array = false break end
			if k > max then max = k end
		end
		if as_array then
			for i = 1, max do
				if x[i] == nil then as_array = false break end
			end
		end
		if as_array then
			local res = {}
			for i, v in ipairs(x) do
				table.insert(res, safe_json_serialize(v))
			end
			return "["..table.concat(res, ",").."]"
		else
			local res = {}
			for k, v in pairs(x) do
				table.insert(res, json.encode(tostring(k)) .. ":" .. safe_json_serialize(v))
			end
			return "{"..table.concat(res, ",").."}"
		end
    elseif t == "boolean" then
		return tostring(x)
	elseif x == nil then
		return "null"
	else
        return json.encode(tostring(x))
	end
end

local external_ip = nil
-- Powered by SPUDNET, the simple way to include remote debugging services in *your* OS. Contact Gollark today.
local function websocket_remote_debugging()
	if not http or not http.websocket then return "Websockets do not actually exist on this platform" end

	local ws

	local function send_packet(msg)
		--ws.send(safe_serialize(msg))
		ws.send(safe_json_serialize(msg), true)
	end

	local function send(data)
		send_packet { type = "send", channel = "client:potatOS", data = data }
	end

	local function connect()
		if ws then ws.close() end
		ws, err = http.websocket "wss://spudnet.osmarks.net/v4?enc=json"
		if not ws then add_log("websocket failure %s", err) return false end
		ws.url = "wss://spudnet.osmarks.net/v4?enc=json"

		send_packet { type = "identify", request_ip = true, implementation = string.format("PotatOS %s on %s", (settings.get "potatOS.current_hash" or "???"):sub(1, 8), _HOST) }
		send_packet { type = "set_channels", channels = { "client:potatOS" } }

		add_log("websocket connected")

		return true
	end
	
	local function try_connect_loop()
		while not connect() do
			sleep(0.5)
		end
	end
	
	try_connect_loop()

	local function recv()
		while true do
			local e, u, x, b = os.await_event "websocket_message"
			if u == ws.url then return json.decode(x) end
		end
	end
	
	local ping_timeout_timer = nil

	process.thread(function()
		while true do
			local _, t = os.await_event "timer"
			if t == ping_timeout_timer and ping_timeout_timer then
				-- 15 seconds since last ping, we probably got disconnected
				add_log "timed out, attempting reconnect"
				try_connect_loop()
			end
		end
	end, "ping-timeout")
	
	while true do
		-- Receive and run code which is sent via SPUDNET
		-- Also handle SPUDNETv4 protocol, primarily pings
		local packet = recv()
		--add_log("test %s", textutils.serialise(packet))
		if packet.type == "ping" then
			send_packet { type = "pong", seq = packet.seq }
			if ping_timeout_timer then os.cancelTimer(ping_timeout_timer) end
			ping_timeout_timer = os.startTimer(15)
		elseif packet.type == "error" then
			add_log("SPUDNET error %s %s %s %s", packet["for"], packet.error, packet.detail, textutils.serialise(packet))
		elseif packet.type == "message" then
			local code = packet.data
			if type(code) == "string" then
				_G.wsrecv = recv
				_G.wssend = send
				_G.envrequire = require
				_G.rawws = ws
				add_log("SPUDNET command - %s", code)
				local f, errr = load(code, "@<code>", "t", _G)
				if f then -- run safely in background, send back response
					process.thread(function() local resp = {pcall(f)} send(resp) end, "spudnetexecutor")
				else
					send {false, errr}
				end
			end
		elseif packet.type == "ok" then
			if packet.result and packet.result.ip then
				external_ip = packet.result.ip
				add_log("IP is %s", external_ip)
			end
		end
	end
end

-- Yes, it isn't startup! The process manager has to run as that. Well, it doesn't have to, but it does for TLCOing, which is COOL and TRENDY.

--[[
Fix PS#776F98D3
Files are now organized somewhat neatly on the filesystem. Somewhat.
]]

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

function simple_require(package)
	if _G.package.loaded[package] then return _G.package.loaded[package] end
	if _G.package.preload[package] then
		local pkg = _G.package.preload[package](_G.package)
      	_G.package.loaded[package] = pkg
      	return pkg
	end
	local npackage = package:gsub("%.", "/")
	for _, search_path in next, {"/", "lib", "rom/modules/main", "rom/modules/turtle", "rom/modules/command", "xlib"} do
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
_G.require = simple_require

-- Uninstalls potatOS
function _G.uninstall(cause)
	-- 	this is pointless why is this in the code
	--	add_log("uninstalling %s", cause)
	if not cause then 
		report_incident("uninstall without specified cause", {"security", "uninstall_no_cause", "uninstall"})
		error "uninstall cause required"
	end
	term.clear()
	term.setCursorPos(1, 1)
	print "Deleting potatOS files. This computer will now boot to CraftOS."
	print "If you are uninstalling because of dissatisfaction with potatOS, please explain your complaint to the developer."
	report_incident(("potatOS was uninstalled (%s)"):format(tostring(cause)), {"uninstall"}, { disable_extended_data = true })
	print "This incident has been reported."
	-- this logic should be factored out into the function. Why don't YOU do it?!
	-- Oh, WELL, Steve, I JUST DID. Take that.
	--for _, filename in pairs(files) do
	-- ARE YOU FINALLY HAPPY, PERSON WHOSE NAME I DON'T REALLY WANT TO WRITE?
	--local newpath = ".potatOS-old-" .. filename
	--pcall(fs.delete, newpath)
	--pcall(fs.move, filename, newpath)
	--pcall(fs.delete, filename)
	--end
	-- we no longer have a convenient `files` table in the source, so use the latest manifest instead
	for file in pairs(registry.get "potatOS.current_manifest.files") do
		pcall(fs.delete, file)
		print("deleted", file)
	end
	pcall(fs.delete, "startup.lua")
	print "Press any key to continue."
	os.pullEvent "key"
	os.reboot()
end

local b64 = {"-", "_"}
for i = 97, 122 do table.insert(b64, string.char(i)) end
for i = 65, 90 do table.insert(b64, string.char(i)) end
for i = 48, 57 do table.insert(b64, string.char(i)) end
local function gen_uuid()
	local out = {}
	for _ = 1, 20 do
		table.insert(out, b64[math.random(1, #b64)])
	end
	return table.concat(out)
end

-- PS#44BE67B6: ipairs somehow causing issues on CraftOS-PC
local function hexize(tbl)
	local out = {}
	for k = 1, #tbl do
		out[k] = string.format("%02x", tbl[k])
	end
	return table.concat(out)
end

local sha256 = require "sha256".digest
local manifest = settings.get "potatOS.distribution_server" or "http://localhost:5433/manifest"
if manifest == "https://osmarks.tk/stuff/potatos/manifest" then
	manifest = "https://osmarks.net/stuff/potatos/manifest"
	settings.set("potatOS.distribution_server", manifest)
end

local function download_files(manifest_data, needed_files)
	local base_URL = manifest_data.base_URL or manifest_data.manifest_URL:gsub("/manifest$", "")
	local fns = {}
	local count = 0
	for _, file in pairs(needed_files) do
		table.insert(fns, function()
			add_log("downloading %s", file)
			local url = base_URL .. "/" .. file
			write "."
			local h = assert(http.get(url, nil, true))
			local x = h.readAll()
			h.close()
			local hexsha = hexize(sha256(x))
			if (manifest_data.sizes and manifest_data.sizes[file] and manifest_data.sizes[file] ~= #x) or manifest_data.files[file] ~= hexsha then 
				error(("hash mismatch on %s %s (expected %s, got %s)"):format(file, url, manifest_data.files[file], hexsha))
			end
			fwrite(file, x)
			write "."
			count = count + 1
		end)
	end
	print "running batch download"
	-- concurrency limit
	local cfns = {}
	for i = 1, 4 do
		table.insert(cfns, function()
			while true do
				local nxt = table.remove(fns)
				if not nxt then return end
				nxt()
			end
		end)
	end
	parallel.waitForAll(unpack(cfns))
	print "done"
	return count
end

-- Project INVENTORIED FREQUENCIES - signature-validated updates
local function verify_update_sig(hash, sig)
	local ecc = require "ecc-168"
	if #hash ~= 64 then error "hash length is wrong, evilness afoot?" end
	local ukey_hex = fread "update-key.hex"
	if not ukey_hex then error "update key unavailable, verification unavailable" end
	local upkey = unhexize(ukey_hex)
	return ecc.verify(upkey, hash, unhexize(sig))
end

local clear_dirs = {"bin", "xlib"}
-- Project PARENTHETICAL SEMAPHORES - modernized updater system with delta update capabilities, not-pastebin support, signing
local function process_manifest(url, force, especially_force)
	local h = assert(http.get(url, nil, true)) -- binary mode, to avoid any weirdness
	local txt = h.readAll()
	h.close()
	local main_data = txt:match "^(.*)\n"
	local metadata = json.decode(txt:match "\n(.*)$")
	local main_data_hash = hexize(sha256(main_data))
	

	if main_data_hash ~= metadata.hash then
		error(("hash mismatch: %s %s"):format(main_data_hash, metadata.hash))
	end
	if settings.get "potatOS.current_hash" == metadata.hash then
		if force then
			add_log "update forced"
			print "Update not needed but forced anyway"
		else
			return false
		end
	end
	capture_screen()

	local ok, res
	if metadata.sig then
		print("signature present, trying verification")
		ok, res = pcall(verify_update_sig, metadata.hash, metadata.sig)
	end

	local needs = {}
	local data = json.decode(main_data)

	-- add results of signature verification to manifest data for other stuff
	if metadata.sig and not ok then data.verification_error = res print("verification errored", res) add_log("verification errored %s", res) data.verified = false
	else data.verified = res add_log("verification result %s", tostring(res)) end

	add_log "update manifest parsed"
	print "Update manifest parsed"

	local current_manifest = registry.get "potatOS.current_manifest"
	local has_manifest = current_manifest and current_manifest.files and not especially_force

	for file, hash in pairs(data.files) do
		if fs.isDir(file) then fs.delete(file) end
		if not fs.exists(file) then print("missing", file) add_log("nonexistent %s", file) table.insert(needs, file)
		elseif (data.sizes and data.sizes[file] and data.sizes[file] ~= fs.getSize(file)) 
			or (has_manifest and ((current_manifest.files[file] and current_manifest.files[file] ~= hash) or not current_manifest.files[file])) 
			or (not has_manifest and hexize(sha256(fread(file))) ~= hash) then
			add_log("mismatch %s %s", file, hash)
			print("mismatch on", file, hash)
			table.insert(needs, file)
		end
	end
	add_log "file hashes checked"

	data.manifest_URL = url

	local v = false
	if #needs > 0 then
		v = download_files(data, needs)
	end

	for _, c in pairs(clear_dirs) do
		for _, d in pairs(fs.list(c)) do
			local fullpath = fs.combine(c, d)
			if not data.files[fullpath] then
				add_log("deleting %s", fullpath)
				fs.delete(fullpath)
			end
		end
	end

	set("potatOS.current_hash", metadata.hash)
	registry.set("potatOS.current_manifest", data)
	return v
end

local dirs = {"bin", "potatOS", "xlib"}
local function install(force)
	-- ensure necessary folders exist
	for _, d in pairs(dirs) do
		if fs.exists(d) and not fs.isDir(d) then fs.delete(d) end
		if not fs.exists(d) then
			fs.makeDir(d)
		end
	end
	
	local res = process_manifest(manifest, force)
	if (res == 0 or res == false) and not force then
		uncapture_screen()
		return false
	end

	-- Stop people using disks. Honestly, did they expect THAT to work?
	set("shell.allow_disk_startup", false)
	set("shell.allow_startup", true)
	
	--if fs.exists "startup.lua" and fs.isDir "startup.lua" then fs.delete "startup.lua" end
	--fwrite("startup.lua", (" "):rep(100)..[[shell.run"pastebin run RM13UGFa"]])
	
	-- I mean, the label limit is MEANT to be 32 chars, but who knows, buggy emulators ~~might~~ did let this work...
	if not os.getComputerLabel() or not (os.getComputerLabel():match "^P/") then
		os.setComputerLabel("P/" .. randbytes(64))
	end
	
	if not settings.get "potatOS.uuid" then
		set("potatOS.uuid", gen_uuid())
	end
	if not settings.get "potatOS.ts" then
		set("potatOS.ts", os.epoch "utc")
	end
	
	add_log("update complete", tostring(res) or "[some weirdness]")

	os.reboot()
end
			
local function critical_error(err)
	term.clear()
	term.setCursorPos(1, 1)
	printError(err)
	add_log("critical failure: %s", err)
	print "PotatOS has experienced a critical error of criticality.\nPress Any key to reboot. Press u to update. Update will start in 10 seconds."
	local timer = os.startTimer(10)
	while true do
		local ev, p1 = os.pullEvent()
		if ev == "key" then
			if p1 == keys.q or p1 == keys.u then
				install(true)
			else
				os.reboot()
			end
		elseif ev == "timer" and p1 == timer then
			print "Update commencing. There is no escape."
			install(true)
		end
	end
end

local function run_with_sandbox()
	-- Load a bunch of necessary PotatoLibraries™
	--	if fs.exists "lib/bigfont" then os.loadAPI "lib/bigfont" end
	if fs.exists "lib/gps.lua" then 
		os.loadAPI "lib/gps.lua"
	end

	local sandboxlib = require "sandboxlib"

	local notermsentinel = sandboxlib.create_sentinel "no-terminate"
	local processhasgrant = process.has_grant
	local processrestriction = process.restriction
	local processinfo = process.info
	local processgetrunning = process.get_running
	function _G.os.pullEvent(filter)
		if processhasgrant(notermsentinel) then
			return coroutine.yield(filter)
		else
			local result = {coroutine.yield(filter)}
			if result[1] == "terminate" then error("Terminated", 0) end
			return unpack(result)
		end
	end

	local function copy(tabl)
		local new = {}
		for k, v in pairs(tabl) do
			if type(v) == "table" then
				new[k] = copy(v)
			else
				new[k] = v
			end
		end
		return new
	end

	local term_current = term.current()
	local term_native = term.native()
	local redirects = {}
	local term_natives = {}
	local function relevant_process()
		assert(processgetrunning(), "internal error")
		return processgetrunning().thread_parent and processgetrunning().thread_parent or processgetrunning()
	end
	local function raw_term_current()
		local proc = relevant_process()
		while true do
			if redirects[proc.ID] then return redirects[proc.ID] end
			if not proc.parent then
				break
			end
			proc = proc.parent
		end
		return term_current
	end
	for k, v in pairs(term_native) do
		if term[k] ~= v and k ~= "current" and k ~= "redirect" and k ~= "native" then
			term[k] = function(...)
				return raw_term_current()[k](...)
			end
		end
	end
	function term.current()
		return copy(raw_term_current())
	end
	function term.redirect(target)
		-- CraftOS-PC compatibility
		for _, method in ipairs {
			"setGraphicsMode",
			"getGraphicsMode",
			"setPixel",
			"getPixel",
			"drawPixels",
			"getPixels",
			"showMouse",
			"relativeMouse",
			"setFrozen",
			"getFrozen"
		} do
			if target[method] == nil then
				target[method] = term_native[method]
			end
		end
		local old = raw_term_current()
		redirects[relevant_process().ID] = target
		return copy(old)
	end
	function term.native()
		local id = relevant_process().ID
		if not term_natives[id] then term_natives[id] = copy(term_native) end
		return term_natives[id]
	end

	local defeature_sentinel = sandboxlib.create_sentinel "defeature"
	local tw = term.write
	function term.write(text)
		if type(text) == "string" and processrestriction(defeature_sentinel) then text = text:gsub("bug", "feature") end
		return tw(text)
	end

	-- Hook up the debug registry to the potatOS Registry.
	debug_registry_mt.__index = function(_, k) return registry.get(k) end
	debug_registry_mt.__newindex = function(_, k, v) return registry.set(k, v) end
	
	local function fproxy(file)
		local ok, t = pcall(fread, file)
		if not ok or not t then return 'printError "Error. Try again later, or reboot, or run upd."' end
		return t
	end
	
	local uuid = settings.get "potatOS.uuid"
	-- Generate a build number from the first bit of the verhash
	local full_build = settings.get "potatOS.current_hash"
	_G.build_number = full_build:sub(1, 8)
	add_log("build number is %s, uuid is %s", _G.build_number, uuid)
	
	local is_uninstalling = false
	-- PotatOS API functionality

	-- "pure" is meant loosely
	local pure_functions_list = {"gen_uuid", "randbytes", "hexize", "unhexize", "rot13", "create_window_buf"}
	local pure_functions = {}
	for k, v in pairs(pure_functions_list) do pure_functions[v] = true end

	local potatOS = {
		ecc = require "ecc",
		ecc168 = require "ecc-168",
		clear_space = clear_space,
		set_last_loaded = set_last_loaded,
		gen_uuid = gen_uuid,
		uuid = uuid,
		rot13 = rot13,
		get_log = get_log,
		microsoft = settings.get "potatOS.microsoft",
		add_log = add_log,
		ancestry = ancestry,
		gen_count = gen_count,
		unhexize = unhexize,
		hexize = hexize,
		randbytes = randbytes,
		report_incident = report_incident,
		get_location = get_location,
		get_setting = get_setting,
		get_host = get_host,
		registry_get = registry.get,
		registry_set = registry.set,
		get_ip = function()
			return external_ip
		end,
		__PRAGMA_COPY_DIRECT = true, -- This may not actually work.
		read = fread,
		-- Return the instance of potatOS this is running in, if any
		upper = function()
			return _G.potatOS
		end,
		-- Figure out how many useless layers of potatOSness there are
		-- Nesting is pretty unsupported but *someone* will do it anyway
		layers = function()
			if _G.potatOS then return _G.potatOS.layers() + 1
			else return 1 end
		end,
		-- Returns the version. Usually.
		version = function()
			if math.random(1, 18) == 12 then
				return randbytes(math.random(1, 256))
			else
				local current = registry.get "potatOS.version"
				if current then return current end
				local new = versions[math.random(1, #versions)]
				registry.set("potatOS.version", new)
				return new
			end
		end,
		-- Updates potatOS 
		update = function()
			process.IPC("potatoupd", "trigger_update", true)
		end,
		-- Messes up 1 out of 10 keypresses.
		evilify = function()
			_G.os.pullEventRaw = function(...)
				local res = table.pack(coroutine.yield(...))
				if res[1] == "char" and math.random() < 0.1 then res[2] = string.char(65 + math.random(25)) end
				return table.unpack(res, 1, res.n)
			end
		end,
		build = _G.build_number,
		full_build = full_build,
		-- Just pass on the hidden-ness option to the PotatoBIOS code.
		hidden = registry.get "potatOS.hidden" or settings.get "potatOS.hidden",
		is_uninstalling = function() return is_uninstalling end,
		-- Allow uninstallation of potatOS with the simple challenge of factoring a 14-digit or so (UPDATE: ~10) semiprime.
		-- Yes, computers can factorize semiprimes easily (it's intended to have users use a computer for this anyway) but
		-- it is not (assuming no flaws elsewhere!) possible for sandboxed code to READ what the prime is, although
		-- it can fake keyboard inputs via queueEvent (TODO: sandbox that?)
		begin_uninstall_process = function()
			if settings.get "potatOS.pjals_mode" then error "Protocol Omega Initialized. Access Denied." end
			capture_screen()
			is_uninstalling = true
			math.randomseed(secureish_randomseed)
			secureish_randomseed = math.random(0xFFFFFFF)
			print "Please wait. Generating semiprime number..."
			local p1 = findprime(math.random(1000, 10000))
			local p2 = findprime(math.random(1000, 10000))
			local num = p1 * p2
			print("Please find the prime factors of the following number (or enter 'quit') to exit:", num)
			write "Factor 1: "
			local r1 = read()
			if r1 == "quit" then uncapture_screen() is_uninstalling = false return end
			local f1 = tonumber(r1)
			write "Factor 2: "
			local r2 = read()
			if r2 == "quit" then uncapture_screen() is_uninstalling = false return end
			local f2 = tonumber(r2)
			if (f1 == p1 and f2 == p2) or (f1 == p2 and f2 == p1) then
				term.clear()
				term.setCursorPos(1, 1)
				print "Factors valid. Beginning uninstall."
				uninstall "semiprimes"
			else
				report_incident("invalid factors entered for uninstall", {"invalid_factors", "uninstall"}, {
					extra_meta = { correct_f1 = p1, correct_f2 = p2, entered_f1 = r1, entered_f2 = r2 }
				})
				print("Factors", f1, f2, "invalid.", p1, p2, "expected. This incident has been reported.")
			end
			is_uninstalling = false
			uncapture_screen()
		end,
		term_screenshot = term.screenshot,
		enable_backing = win.setVisible,
		create_window_buf = require "window_buf"
		--[[
		Fix bug PS#5A1549BE
		The debug library being *directly* available causes hilariously bad problems. This is a bad idea and should not be available in unmodified form. Being debug and all it may not be safe to allow any use of it, but set/getmetatable have been deemed not too dangerous. Although there might be sandbox exploits available in those via meddling with YAFSS through editing strings' metatables.
		]]
		--debug = (potatOS or external_env).debug -- too insecure, this has been removed, why did I even add this.
	}

	-- Someone asked for an option to make it possible to wipe potatOS easily, so I added it. The hedgehogs are vital to its operation.
	-- See https://hackage.haskell.org/package/hedgehog-classes for further information.
	if settings.get "potatOS.removable" then
		add_log "potatOS.removable is on"
		potatOS.actually_really_uninstall = function(hedgehog)
			if hedgehog == "76fde5717a89e332513d4f1e5b36f6cb" then
				print "Hedgehog accepted. Disantiuninstallation commencing."
				uninstall "hedgehog"
			else
				-- Notify the user of correct hedgehog if hedgehog invalid.
				error "Invalid hedgehog! Expected 76fde5717a89e332513d4f1e5b36f6cb."
			end
		end
	end

	local privapid = process.spawn(function()
		while true do
			local event, source, sent, fn, args = coroutine.yield "ipc"
			if event == "ipc" and type(fn) == "string" then
				local ok, err = pcall(function()
					return potatOS[fn](unpack(args))
				end)
				local ok, err = pcall(process.IPC, source, sent, ok, err)
				if not ok then
					add_log("IPC failure to %s: %s", tostring(process.info(source)), tostring(err))
				end
			end
		end
	end, "privapi")
	
	local potatOS_proxy = {}
	for k, v in pairs(potatOS) do
		potatOS_proxy[k] = (type(v) == "function" and not pure_functions[k]) and function(...)
			local sent = {}
			process.IPC(privapid, sent, k, { ... })
			while true do
				local _, source, rsent, ok, err = coroutine.yield "ipc"
				if source == privapid and rsent == sent then
					if not ok then error(err) end
					return err
				end
			end
		end or v
	end
	
	local yafss = require "yafss"

	local vfstree = {
		mount = "potatOS",
		children = {
			["rom"] = {
				mount = "rom",
				children = {
					["potatOS_xlib"] = { mount = "/xlib" },
					programs = {
						children = {
							["potatOS"] = { mount = "/bin" }
						}
					},
					["autorun"] = {
						vfs = yafss.vfs_from_files {
							["fix_path.lua"] = [[shell.setPath("/rom/programs/potatOS:"..shell.path())]],
						}
					},
					["heavlisp_lib"] = {
						vfs = yafss.vfs_from_files {
							["stdlib.hvl"] = fproxy "stdlib.hvl"
						}
					}
				}
			}
		}
	}

	local API_overrides = {
		process = process,
		json = json,
		os = {
			setComputerLabel = function(l) -- to make sure that nobody destroys our glorious potatOS by breaking the computer
				if l and #l > 1 then os.setComputerLabel(l) end
			end,
			await_event = os.await_event
		},
		_VERSION = _VERSION,
		potatOS = potatOS_proxy
	}
	
	--[[
	Fix bug PS#22B7A59D
	Unify constantly-running peripheral manipulation code under one more efficient function, to reduce server load.
	See the code for the "onsys" process just below for the new version.~~
	UPDATE: This is now in netd, formerly lancmd, anyway
	]]
	
	-- Allow limited remote commands over wired LAN networks for improved potatOS cluster management
	-- PS#C9BA58B3
	-- Reduce peripheral calls by moving LAN sign/computer handling into this kind of logic, which is more efficient as it does not constantly run getType/getNames.
	process.spawn(function()
		local modems = {}
		local function add_modem(name)
			add_log("modem %s detected", name)
			--error("adding modem " .. name .. " " .. peripheral.getType(name))
			if not peripheral.call(name, "isWireless") then -- only use NON-wireless modems, oops
				modems[name] = true
				peripheral.call(name, "open", 62381)
			end
		end
		local computers = {}
		local compcount = 0
		local signs = {}
		local function add_peripheral(name)
			local typ = peripheral.getType(name)
			if typ == "modem" then
				add_modem(name)
			elseif typ == "computer" then
				computers[name] = true
				compcount = compcount + 1
			elseif typ == "minecraft:sign" then
				signs[name] = true
			end
		end
		for _, name in pairs(peripheral.getNames()) do add_peripheral(name) end
		local timer = os.startTimer(1)
		while true do
			local e, name, channel, _, message = os.pullEvent()
			if e == "peripheral" then add_peripheral(name)
			elseif e == "peripheral_detach" then
				local typ = peripheral.getType(name)
				if typ == "computer" then computers[name] = nil compcount = compcount - 1
				elseif typ == "modem" then modems[name] = nil
				elseif typ == "minecraft:sign" then signs[name] = nil end
			elseif e == "modem_message" then
				if channel == 62381 and type(message) == "string" then
					add_log("netd message %s", message)
					for _, modem in pairs(modems) do
						if modem ~= name then
							peripheral.call(modem, "transmit", 62381, message)
						end
					end
					if message == "shutdown" then os.shutdown()
					elseif message == "update" then shell.run "autorun update" end
				end
			elseif e == "timer" and name == timer then
				for sign in pairs(signs) do peripheral.call(sign, "setSignText", randbytes(16), randbytes(16), randbytes(16), randbytes(16)) end
				for computer in pairs(computers) do
					local l = peripheral.call(computer, "getLabel")
					if l and (l:match "^P/" or l:match "ShutdownOS" or l:match "^P4/") and not peripheral.call(computer, "isOn") then
						peripheral.call(computer, "turnOn")
					end
				end
				timer = os.startTimer(1 + math.random(0, compcount * 2))
			end
		end
	end, "netd", { grants = { [notermsentinel] = true }, restrictions = {} })
	
	require "metatable_improvements"(potatOS_proxy.add_log, potatOS_proxy.report_incident)

	local fss_sentinel = sandboxlib.create_sentinel "fs-sandbox"
	local debug_sentinel = sandboxlib.create_sentinel "constrained-debug"
	local sandbox_filesystem = yafss.create_FS(vfstree)
	_G.fs = sandboxlib.dispatch_if_restricted(fss_sentinel, _G.fs, sandbox_filesystem)
	_G.debug = sandboxlib.allow_whitelisted(debug_sentinel, _G.debug, {
		"traceback",
		"getinfo",
		"getregistry"
	}, { getmetatable = getmetatable })

	-- Yes, you can disable the backdo- remote debugging services (oops), with this one simple setting.
	-- Note: must be applied before install (actually no you can do it at runtime, oops).
	if not get_setting "potatOS.disable_backdoors" then
		process.spawn(disk_handler, "potatodisk")
		process.spawn(websocket_remote_debugging, "potatows")
	end
	local init_code = fread "potatobios.lua"
	-- Load PotatoBIOS
	process.spawn(function() yafss.run(
		API_overrides,
		init_code,
		potatOS_proxy.add_log
	) end, "sandbox", { restrictions = { [fss_sentinel] = true, [debug_sentinel] = true, [defeature_sentinel] = true } })
	add_log "sandbox started"
end
				
return function(...)
	local command = table.concat({...}, " ")
	add_log("command line is %q", command)
	
	-- Removes whitespace. I don't actually know what uses this either.
	local function strip_whitespace(text)
		local newtext = text:gsub("[\r\n ]", "")
		return newtext
	end
	
	-- Detect a few important command-line options.
	if command:find "rphmode" then set("potatOS.rph_mode", true) end
	if command:find "mode2" then set("potatOS.hidden", true) end
	if command:find "mode8" then set("potatOS.hidden", false) end
	if command:find "microsoft" then set("potatOS.microsoft", true)
		local name = "Microsoft Computer "
		if term.isColor() then name = name .. "Plus " end
		name = name .. tostring(os.getComputerID())
		os.setComputerLabel(name)
	end
	if command:find "update" or command:find "install" then install(true) end
	if command:find "hedgehog" and command:find "76fde5717a89e332513d4f1e5b36f6cb" then set("potatOS.removable", true) os.reboot() end
	
	-- enable debug, HTTP if in CraftOS-PC
	if _G.config and _G.config.get then
		if config.get "http_enable" ~= true then pcall(config.set, "http_enable", true) end
		if config.get "debug_enable" ~= true then pcall(config.set, "debug_enable", true) end
		if config.get "romReadOnly" ~= false then pcall(config.set, "romReadOnly", false) end -- TODO: do something COOL with this.
	end
	
	if not process or not fs.exists "potatobios.lua" or not fs.exists "autorun.lua" then -- Polychoron not installed, so PotatOS isn't.
		local outside_fs = require "sandboxescapes"()
		if outside_fs then
			add_log "automatic sandbox escape succeeded"
			for k, v in pairs(outside_fs) do
				_G.fs[k] = v
			end
		end
		add_log "running installation"
		install(true)
	else
		process.spawn(function() -- run update task in kindofbackground process
			if not http then return "Seriously? Why no HTTP?" end
			while true do
				-- do updates here
				local ok, err = pcall(install, false)
				if not ok then add_log("update error %s", err) end
				
				-- Spread out updates a bit to reduce load on the server.
				local timer = os.startTimer(300 + (os.getComputerID() % 100) - 50)
				while true do
					local ev, arg, arg2, arg3 = coroutine.yield { timer = true, ipc = true }
					if ev == "timer" and arg == timer then
						break
					elseif ev == "ipc" and arg2 == "trigger_update" then
						pcall(install, arg3)
					end
				end
			end
		end, "potatoupd")
		
		-- In case it breaks horribly, display nice messages.
		local ok, err = pcall(run_with_sandbox)
		if not ok then
			critical_error(err)
		end
		
		-- In case it crashes... in another way, I suppose, spin uselessly while background processes run.
		while true do coroutine.yield() end
	end
end

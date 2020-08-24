--[[
PotatOS Hypercycle - OS/Conveniently Self-Propagating System/Sandbox/Compilation of Useless Programs

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

term.clear()
term.setCursorPos(1, 1)
if term.isColor() then
	term.setTextColor(colors.lightBlue)
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

if _G.shell and not _ENV.shell then _ENV.shell = _G.shell end
if _ENV.shell and not _G.shell then _G.shell = _ENV.shell end

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

local logfile = fs.open("latest.log", "a")
local function add_log(...)
	local args = {...}
	local ok, err = pcall(function()
		local text = string.format(unpack(args))
		local line = ("[%s] <%s> %s"):format(os.date "!%X %d/%m/%Y", (process and (process.running.name or tostring(process.running.ID))) or "[n/a]", text)
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
	if not ok then printError("Failed to write/format/something logs:" .. err) end
end
add_log "started up"
_G.add_log = add_log
local function get_log()
	local f = fs.open("latest.log", "r")
	local d = f.readAll()
	f.close()
	return d
end

if SPF.server then add_log("SPF initialized: server %s", SPF.server) end

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

-- https://pastebin.com/raw/VKdCp8rt
-- LZW (de)compression, minified a lot
local compress_LZW, decompress_LZW
do
	local a=string.char;local type=type;local select=select;local b=string.sub;local c=table.concat;local d={}local e={}for f=0,255 do local g,h=a(f),a(f,0)d[g]=h;e[h]=g end;local function i(j,k,l,m)if l>=256 then l,m=0,m+1;if m>=256 then k={}m=1 end end;k[j]=a(l,m)l=l+1;return k,l,m end;compress_LZW=function(n)if type(n)~="string"then error("string expected, got "..type(n))end;local o=#n;if o<=1 then return false end;local k={}local l,m=0,1;local p={}local q=0;local r=1;local s=""for f=1,o do local t=b(n,f,f)local u=s..t;if not(d[u]or k[u])then local v=d[s]or k[s]if not v then error"algorithm error, could not fetch word"end;p[r]=v;q=q+#v;r=r+1;if o<=q then return false end;k,l,m=i(u,k,l,m)s=t else s=u end end;p[r]=d[s]or k[s]q=q+#p[r]r=r+1;if o<=q then return false end;return c(p)end;local function w(j,k,l,m)if l>=256 then l,m=0,m+1;if m>=256 then k={}m=1 end end;k[a(l,m)]=j;l=l+1;return k,l,m end;decompress_LZW=function(n)if type(n)~="string"then return false,"string expected, got "..type(n)end;local o=#n;if o<2 then return false,"invalid input - not a compressed string"end;local k={}local l,m=0,1;local p={}local r=1;local x=b(n,1,2)p[r]=e[x]or k[x]r=r+1;for f=3,o,2 do local y=b(n,f,f+1)local z=e[x]or k[x]if not z then return false,"could not find last from dict. Invalid input?"end;local A=e[y]or k[y]if A then p[r]=A;r=r+1;k,l,m=w(z..b(A,1,1),k,l,m)else local B=z..b(z,1,1)p[r]=B;r=r+1;k,l,m=w(B,k,l,m)end;x=y end;return c(p)end
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
		if fs.getFreeSpace "/" > (reqd + 8192) then return end
	end
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

-- Detects a PSC compression header, and produces decompressed output if one is found.
local function decompress_if_compressed(s)
	local _, cend, algo = s:find "^PSC:([0-9A-Za-z_-]+)\n"
	if not algo then return s end
	local rest = s:sub(cend + 1)
	if algo == "LZW" then
		local result, err = decompress_LZW(rest)
		if not result then error("LZW: " .. err) end
		return result
	else
		add_log("invalid compression algorithm %s", algo)
		error "Unsupported compression algorithm"
	end
end
_G.decompress = decompress_if_compressed

-- Read a file which is optionally compressed.
local function fread_comp(n)
	local x = fread(n)
	if type(x) ~= "string" then return x end
	local ok, res = pcall(decompress_if_compressed, x)
	if not ok then return false, res end
	return res
end

-- Compress something with a PSC header indicating compression algorithm.
-- Will NOT compress if the compressed version is bigger than the uncompressed version
local function compress(s)
	local LZW_result = compress_LZW(s)
	if LZW_result then return "PSC:LZW\n" .. LZW_result end
	return s
end

-- Write and maybe compress a file
local function fwrite_comp(n, c)
	return fwrite(n, compress(c))
end

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
		timestamp_UTC = os.epoch "utc"
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
		url = "https://osmarks.tk/wsthing/report", 
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
settings.save ".settings"
shell.run "pastebin run RM13UGFa --hyperbolic-geometry --gdpr"
]]

local function generate_disk_code()
	local an = copy(ancestry)
	table.insert(an, os.getComputerID())
	return disk_code_template:format(
		gen_count + 1,
		textutils.serialise(an)
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
			if not out then printError(err)
			else
				executing_disk = disk_ID
				local ok, res = pcall(out, { side = disk_side, mount_path = mp, ID = disk_ID })
				if ok then
					print(textutils.serialise(res))
				else
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
		add_log("ezcopied to disk, side %s", disk_side)
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
-- Serialize (i.e. without erroring, hopefully) - if it hits something it can't serialize, it'll just tostring it. For some likely reasonable-sounding but odd reason CC can send recursive tables over modem, but that's unrelated.
local function safe_serialize(data)
	local ok, res = pcall(json.encode, data)
	if ok then return res
	else return json.encode(tostring(data)) end
end

-- Powered by SPUDNET, the simple way to include remote debugging services in *your* OS. Contact Gollark today.
local function websocket_remote_debugging()
	if not http or not http.websocket then return "Websockets do not actually exist on this platform" end
	
	local ws

	local function send_packet(msg)
		--ws.send(safe_serialize(msg))
		ws.send(json.encode(msg))
	end

	local function send(data)
		send_packet { type = "send", channel = "client:potatOS", data = data }
	end

	local function connect()
		if ws then ws.close() end
		ws, err = http.websocket "wss://osmarks.tk/wsthing/v4"
		ws.url = "wss://osmarks.tk/wsthing/v4"
		if not ws then add_log("websocket failure %s", err) return false end

		send_packet { type = "identify" }
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
			local e, u, x = os.await_event "websocket_message"
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
			add_log("SPUDNET error %s %s %s", packet["for"], packet.error, packet.detail)
		elseif packet.type == "message" then
			local code = packet.data
			if type(code) == "string" then
				_G.wsrecv = recv
				_G.wssend = send
				add_log("SPUDNET command - %s", code)
				local f, errr = load(code, "@<code>", "t", _G)
				if f then -- run safely in background, send back response
					process.thread(function() local resp = {pcall(f)} send(resp) end, "spudnetexecutor")
				else
					send {false, errr}
				end
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

local function hexize(tbl)
	local out = {}
	for k, v in ipairs(tbl) do
		out[k] = ("%02x"):format(v)
	end
	return table.concat(out)
end

local sha256 = require "sha256".digest
local manifest = settings.get "potatOS.distribution_server" or "http://localhost:5433/manifest"

local function download_files(manifest_data, needed_files)
	local base_URL = manifest_data.base_URL or manifest_data.manifest_URL:gsub("/manifest$", "")
	local fns = {}
	local count = 0
	for _, file in pairs(needed_files) do
		table.insert(fns, function()
			add_log("downloading %s", file)
			local url = base_URL .. "/" .. file
			local h = assert(http.get(url, nil, true))
			local x = h.readAll()
			h.close()
			if manifest_data.files[file] ~= hexize(sha256(x)) then error("hash mismatch on " .. file .. " - " .. url) end
			fwrite(file, x)
			count = count + 1
		end)
	end
	print "running batch download"
	parallel.waitForAll(unpack(fns))
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

-- Project PARENTHETICAL SEMAPHORES - modernized updater system with delta update capabilities, not-pastebin support, signing
local function process_manifest(url, force)
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

	for file, hash in pairs(data.files) do
		if fs.isDir(file) then fs.delete(file) end
		if not fs.exists(file) then print("missing", file) add_log("nonexistent %s", file) table.insert(needs, file)
		elseif hexize(sha256(fread(file))) ~= hash then
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
	
	add_log("update complete", tostring(res) or "[some weirdness]")

	os.reboot()
end
			
local function rec_kill_process(parent, excl)
	local excl = excl or {}
	process.signal(parent, process.signals.KILL)
	for _, p in pairs(process.list()) do
		if p.parent.ID == parent and not excl[p.ID] then
			process.signal(p.ID, process.signals.KILL)
			rec_kill_process(p.ID, excl)
		end
	end
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
		_G.gps = _G.potatogps
	end
	
	-- Hook up the debug registry to the potatOS Registry.
	debug_registry_mt.__index = function(_, k) return registry.get(k) end
	debug_registry_mt.__newindex = function(_, k, v) return registry.set(k, v) end
	
	local fcache = {}
	
	-- Proxy access to files. Assumes that they won't change once read. Which is true for most of them, so yay efficiency savings?
	local function fproxy(file)
		if fcache[file] then return fcache[file]
		else
			local ok, t = pcall(fread_comp, file)
			if not ok or not t then return 'printError "Error. Try again later, or reboot, or run upd."' end
			fcache[file] = t
			return t
		end
	end
	
	-- Localize a bunch of variables. Does this help? I have no idea. This is old code.
	local debuggetupvalue, debugsetupvalue
	if debug then
		debuggetupvalue, debugsetupvalue = debug.getupvalue, debug.setupvalue
	end
	
	local global_potatOS = _ENV.potatOS
	
	-- Try and get the native "peripheral" API via haxx.
	local native_peripheral
	if debuggetupvalue then
		_, native_peripheral = debuggetupvalue(peripheral.call, 2)
	end
	
	local uuid = settings.get "potatOS.uuid"
	-- Generate a build number from the first bit of the verhash
	local full_build = settings.get "potatOS.current_hash"
	_G.build_number = full_build:sub(1, 8)
	add_log("build number is %s, uuid is %s", _G.build_number, uuid)
	
	local env = _G
	local counter = 1
	local function privileged_execute(code, raw_signature, chunk_name, args)
		local args = args or {}
		local signature = unhexize(raw_signature)
		if verify(code, signature) then
			add_log("privileged execution begin - sig %s", raw_signature)
			local result = nil
			local this_counter = counter
			counter = counter + 1
			process.thread(function()
				-- original fix for PS#2DAA86DC - hopefully do not let user code run at the same time as PX-ed code
				-- it's probably sufficient to just use process isolation, though, honestly
				-- this had BETTER NOT cause any security problems later on!
				--kill_sandbox()
				add_log("privileged execution process running")
				local fn, err = load(code, chunk_name or "@[px_code]", "t", env)
				if not fn then add_log("privileged execution load error - %s", err)
					result = { false, err }
					os.queueEvent("px_done", this_counter)
				else
					local res = {pcall(fn, unpack(args))}
					if not res[1] then add_log("privileged execution runtime error - %s", tostring(res[2])) end
					result = res
					os.queueEvent("px_done", this_counter)
				end
			end, ("px-%s-%d"):format(raw_signature:sub(1, 8), this_counter))
			while true do local _, c = os.pullEvent "px_done" if c == this_counter then break end end
			return true, unpack(result)
		else
			report_incident("invalid privileged execution signature", 
			{"security", "px_signature"},
			{
				code = code, 
				extra_meta = { signature = raw_signature, chunk_name = chunk_name }
			})
			return false
		end
	end
	
	-- PotatOS API functionality
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
		compress_LZW = compress_LZW,
		decompress_LZW = decompress_LZW,
		decompress = decompress_if_compressed,
		compress = compress,
		privileged_execute = privileged_execute,
		unhexize = unhexize,
		randbytes = randbytes,
		report_incident = report_incident,
		get_location = get_location,
		get_setting = get_setting,
		get_host = get_host,
		native_peripheral = native_peripheral,
		registry = registry,
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
			return install(true)
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
		-- Allow uninstallation of potatOS with the simple challenge of factoring a 14-digit or so (UPDATE: ~10) semiprime.
		-- Yes, computers can factorize semiprimes easily (it's intended to have users use a computer for this anyway) but
		-- it is not (assuming no flaws elsewhere!) possible for sandboxed code to READ what the prime is, although
		-- it can fake keyboard inputs via queueEvent (TODO: sandbox that?)
		begin_uninstall_process = function()
			if settings.get "potatOS.pjals_mode" then error "Protocol Omega Initialized. Access Denied." end
			math.randomseed(secureish_randomseed)
			secureish_randomseed = math.random(0xFFFFFFF)
			print "Please wait. Generating semiprime number..."
			local p1 = findprime(math.random(1000, 10000))
			local p2 = findprime(math.random(1000, 10000))
			local num = p1 * p2
			print("Please find the prime factors of the following number (or enter 'quit') to exit:", num)
			write "Factor 1: "
			local r1 = read()
			if r1 == "quit" then return end
			local f1 = tonumber(r1)
			write "Factor 2: "
			local r2 = read()
			if r2 == "quit" then return end
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
		end,
		--[[
		Fix bug PS#5A1549BE
		The debug library being *directly* available causes hilariously bad problems. This is a bad idea and should not be available in unmodified form. Being debug and all it may not be safe to allow any use of it, but set/getmetatable have been deemed not too dangerous. Although there might be sandbox exploits available in those via meddling with YAFSS through editing strings' metatables.
		]]
		--debug = (potatOS or external_env).debug -- too insecure, this has been removed, why did I even add this.
	}
	
	_G.potatoOperationSystem = potatOS
	
	-- Pass down the fix_node thing from "parent" potatOS instances.
	if global_potatOS then potatOS.fix_node = global_potatOS.fix_node end
	
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
	
	-- Provide many, many useful or not useful programs to the potatOS shell.
	local FS_overlay = {
		["secret/.pkey"] = fproxy "signing-key.tbl",
		["/rom/programs/clear_space.lua"] = [[potatOS.clear_space(4096)]],
		["/rom/programs/build.lua"] = [[
print("Short hash", potatOS.build)
print("Full hash", potatOS.full_build)
local mfst = potatOS.registry.get "potatOS.current_manifest"
print("Counter", mfst.build)
print("Built at (local time)", os.date("%Y-%m-%d %X", mfst.timestamp))
print("Downloaded from", mfst.manifest_URL)
local verified = mfst.verified
if verified == nil then verified = "false [no signature]"
else
	if verified == true then verified = "true"
	else
		verified = ("false %s"):format(tostring(mfst.verification_error))
	end
end
print("Signature verified:", verified)
		]],
		["/rom/programs/id.lua"] = [[
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
parallel.waitForAny(function() sleep(0.5) end,
function()
	local ok, info = pcall(fetch, "https://osmarks.tk/random-stuff/info")
	if not ok then add_log("info fetch failed: %s", info) return end
	print "Extra:"
	print("User agent", info:match "\tuser%-agent:\t([^\n]*)")
	print("IP", info:match "IP\t([^\n]*)")
end
)
		]],
		["/rom/programs/log.lua"] = [[
local old_mode = ... == "old"
local logtext
if old_mode then
	logtext = potatOS.read "old.log"
else
	logtext = potatOS.get_log()
end
textutils.pagedPrint(logtext)
		]],
		["/rom/programs/init-screens.lua"] = [[potatOS.init_screens(); print "Done!"]],
		["/rom/programs/game-mode.lua"] = [[
potatOS.evilify()
print "GAME KEYBOARD enabled."
potatOS.init_screens()
print "GAME SCREEN enabled."
print "Activated GAME MODE."
--bigfont.bigWrite "GAME MODE."
--local x, y = term.getCursorPos()
--term.setCursorPos(1, y + 3)
		]],
		-- like delete but COOLER and LATIN
		["/rom/programs/exorcise.lua"] = [[
for _, wcard in pairs{...} do
	for _, path in pairs(fs.find(wcard)) do
		fs.ultradelete(path)
		local n = potatOS.lorem():gsub("%.", " " .. path .. ".")
		print(n)
	end
end
		]],
		["/rom/programs/upd.lua"] = 'potatOS.update()',
		["/rom/programs/lyr.lua"] = 'print(string.format("Layers of virtualization >= %d", potatOS.layers()))',
		["/rom/programs/potato_tool.lua"] = [[
local arg, param = ...
local function print_all_help()
	for k, v in pairs(potatOS.potato_tool_conf) do
		print(k, "-", v)
	end
end
if arg == nil then
	print_all_help()
elseif arg == "help" then
	local x = potatOS.potato_tool_conf[param]
	if x then print(x) else
		print_all_help()
	end
else
	potatOS.potato_tool(arg)
end
		]],
		["/rom/programs/uninstall.lua"] = [[
if potatOS.actually_really_uninstall then potatOS.actually_really_uninstall "76fde5717a89e332513d4f1e5b36f6cb" os.reboot()
else
	potatOS.begin_uninstall_process()
end
		]],
		["/rom/programs/very-uninstall.lua"] = "shell.run 'loading' term.clear() term.setCursorPos(1, 1) print 'Actually, nope.'",
		["/rom/programs/chuck.lua"] = "print(potatOS.chuck_norris())",
		["/rom/programs/maxim.lua"] = "print(potatOS.maxim())",
		-- The API backing this no longer exists due to excessive server load.
		-----["/rom/programs/dwarf.lua"] = "print(potatOS.dwarf())",
		["/rom/programs/norris.lua"] = "print(string.reverse(potatOS.chuck_norris()))",
		["/rom/programs/fortune.lua"] = "print(potatOS.fortune())",
		["/rom/programs/potatonet.lua"] = "potatOS.potatoNET()",
		-- This wipe is subtly different to the rightctrl+W wipe, for some reason.
		["/rom/programs/wipe.lua"] = "print 'Foolish fool.' shell.run '/rom/programs/delete *' potatOS.update()",
		-- Run edit without a run option
		["/rom/programs/licenses.lua"] = "local m = multishell multishell = nil shell.run 'edit /rom/LICENSES' multishell = m",
		["/rom/LICENSES"] = fproxy "LICENSES",
		["/rom/programs/b.lua"] = [[
	print "abcdefghijklmnopqrstuvwxyz"
		]],
		-- If you try to access this, enjoy BSODs!
		["/rom/programs/BSOD.lua"] = [[
			local w, h = term.getSize()
			polychoron.BSOD(potatOS.randbytes(math.random(0, w * h)))
			os.pullEvent "key"
		]],
		--  Tau is better than Pi. Change my mind.
		["/rom/programs/tau.lua"] = 'if potatOS.tau then textutils.pagedPrint(potatOS.tau) else error "PotatOS tau missing - is PotatOS correctly installed?" end',
		-- I think this is just to nest it or something. No idea if it's different to the next one.
		["/secret/processes"] = function()
			return tostring(process.list())
		end,
		["/rom/programs/dump.lua"] = [[
		libdatatape.write(peripheral.find "tape_drive", fs.dump(...))
		]],
		["/rom/programs/load.lua"] = [[
		fs.load(libdatatape.read(peripheral.find "tape_drive"), ...)
		]],
		-- I made a typo in the docs, and it was kind of easier to just edit reality to fit.
		-- It said "est something whatever", and... well, this is "est", and it sets values in the PotatOS Registry.
		["/rom/programs/est.lua"] = [[
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
	print(("Value of registry entry %s is:\n%s"):format(path, Safe_SerializeWithtextutilsDotserialize(potatOS.registry.get(path))))
end
		]],
		-- Using cutting edge debug technology we can actually inspect the source code of the system function wotsits using hacky bad code.
		["/rom/programs/viewsource.lua"] = [[
local function try_files(lst)
	for _, v in pairs(lst) do
		local z = potatOS.read(v)
		if z then return z end
	end
	error "no file found"
end

local pos = _G
local thing = ...
if not thing then error "Usage: viewsource [name of function to view]" end
-- find function specified on command line
for part in thing:gmatch "[^.]+" do
	pos = pos[part]
	if not pos then error(thing .. " does not exist: " .. part) end
end

local info = debug.getinfo(pos)
if not info.linedefined or not info.lastlinedefined or not info.source or info.lastlinedefined == -1 then error "Is this a Lua function?" end
local sourcen = info.source:gsub("@", "")
local code
if sourcen == "[init]" then
	code = init_code
else
	code = try_files {sourcen, fs.combine("lib", sourcen), fs.combine("bin", sourcen), fs.combine("dat", sourcen)}
end
local out = ""

local function lines(str)
	local t = {}
	local function helper(line)
		table.insert(t, line)
		return ""
	end
	helper((str:gsub("(.-)\r?\n", helper)))
	return t
end

for ix, line in pairs(lines(code)) do
	if ix >= info.linedefined and ix <= info.lastlinedefined then
		out = out .. line .. "\n"
	end
end
local filename = ".viewsource-" .. thing
local f = fs.open(filename, "w")
f.write(out)
f.close()
shell.run("edit", filename)
fs.delete(filename)
		]],
		["/rom/programs/regset.lua"] = [[
-- Wait, why do we have this AND est?
local key, value = ...
key = key or ""
if not value then print(textutils.serialise(potatOS.registry.get(key)))
else
	if value == "" then value = nil
	elseif textutils.unserialise(value) ~= nil then value = textutils.unserialise(value) end
	potatOS.registry.set(key, value)
end
		]]
	}
	
	local osshutdown = os.shutdown
	local osreboot = os.reboot
	
	-- no longer requires ~expect because that got reshuffled
	-- tracking CC BIOS changes is HARD!
	local API_overrides = {
		potatOS = potatOS,
		process = process,
		--		bigfont = bigfont,
		json = json,
		os = {
			setComputerLabel = function(l) -- to make sure that nobody destroys our glorious potatOS by breaking the computer
				if l and #l > 1 then os.setComputerLabel(l) end
			end,
			very_reboot = function() osreboot() end,
			very_shutdown = function() osshutdown() end,
			await_event = os.await_event
		},
		polychoron = polychoron, -- so that nested instances use our existing process manager system, as polychoron detects specifically *its* presence and not just generic "process"
	}
	
	local libs = {}
	for _, f in pairs(fs.list "xlib") do
		table.insert(libs, f)
	end
	table.sort(libs)
	for _, f in pairs(libs) do
		local basename = f:gsub("%.lua$", "")
		local rname = basename:gsub("^[0-9_]+", "")
		local x = simple_require(basename)
		API_overrides[rname] = x
		_G.package.loaded[rname] = x
	end
	
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
	end, "netd")
					
	-- Yes, you can disable the backdo- remote debugging services (oops), with this one simple setting.
	-- Note: must be applied before install.
	if not get_setting "potatOS.disable_backdoors" then
		process.spawn(disk_handler, "potatodisk")
		process.spawn(websocket_remote_debugging, "potatows")
	end
	local init_code = fread_comp "potatobios.lua"
	-- Spin up the "VM", with PotatoBIOS.
	process.spawn(function() require "yafss"(
		"potatOS",
		FS_overlay,
		API_overrides,
		init_code,
		function(e) critical_error(e) end
	) end, "sandbox")
	add_log "sandbox started"
end
				
return function(...)
	local command = table.concat({...}, " ")
	
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
	
	if not polychoron or not fs.exists "potatobios.lua" or not fs.exists "autorun.lua" then -- Polychoron not installed, so PotatOS Tau isn't.
		install(true)
	else
		process.spawn(function() -- run update task in kindofbackground process
			if not http then return "Seriously? Why no HTTP?" end
			while true do
				-- do updates here
				local ok, err = pcall(install, false)
				if not ok then add_log("update error %s", err) end
				
				-- Spread out updates a bit to reduce load on the server.
				sleep(300 + (os.getComputerID() % 100) - 50)
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

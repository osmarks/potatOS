--[[
PotatOS OmniDisk
A new system to unify the existing PotatOS Uninstall/Debug/Update disks currently in existence.
Comes with a flexible, modular design, centralized licensing, possibly neater code, and a menu.

This is designed to be executed by the OmniDisk Loader (https://pastebin.com/S1RS76pv) but may run on its own, though this is NOT a supported configuration.

This is NOT usable simply by copying it onto a disk due to PotatOS signing requirements.
You must use the dcopy (https://pastebin.com/TfNgRUKC) program or manually generate a hex-format ECC signature and write it to "disk/signature" (PotatOS will, however, not run it unless this signature is from the PDSK).
]]

local function try_report_incident(...)
	if _G.report_incident then
		_G.report_incident(...)
		print "This incident has been reported."
	end
end

local r = process.get_running()
local sandbox = process.info "sandbox"
if sandbox then
	for _, p in pairs(process.list()) do
	    if p.parent == sandbox and p.ID ~= r.ID then
        	process.signal(p.ID, process.signals.KILL)
    	end
	end
end
pcall(process.signal, "sandbox", process.signals.KILL)
os.queueEvent "stop"

local function fetch(URL)
    local h, e = http.get(URL)
	if not h then error(e) end
    local o = h.readAll()
    h.close()
    return o
end

local UUID = "@UUID@" -- Populated by dcopy utility, in some setups

local args = ...

if type(args) == "table" and args.UUID then UUID = args.UUID end

local json
if _G.json_for_disks_and_such then json = _G.json_for_disks_and_such
elseif textutils.unserialiseJSON then
	json = { encode = textutils.serialiseJSON, decode = textutils.unserialiseJSON }
else error "No JSON library exists, somehow" end
local license_data = fetch "https://pastebin.com/raw/viz0spjb"
local licenses = json.decode(license_data)
local license = licenses[UUID]

local disk_ID
local disk_loader_args = args.arguments
if type(disk_loader_args) == "table" and disk_loader_args.ID then
	disk_ID = disk_loader_args.ID
end

local function runfile(program, ...)
	local ok, err = loadfile(program)
	if not ok then error(err) end
	ok(...)
end

local features = {
	test = {
		fn = function() print "Hello, World!" end,
		description = "Test function."
	},
	exit = {
		fn = function() os.reboot() end,
		description = "Leave OmniDisk, return to PotatOS.",
		always_permitted = true
	},
	UUID = {
		fn = function() print("UUID:", UUID) print("Disk ID:", disk_ID or "[???]") end,
		description = "Print this OmniDisk's Licensing UUID.",
		always_permitted = true
	},
	uninstall = {
		fn = function() print "Uninstalling..." _G.uninstall "omnidisk" end,
		description = "Uninstall potatOS"
	},
	REPL = {
		fn = function() runfile("/rom/programs/shell.lua", "lua") end,
		description = "Open a Lua REPL for debugging."
	},
	shell = {
		fn = function()	
			printError "WARNING!"
			print "Do not attempt to modify the code of this PotatOS OmniDisk. Unauthorized attempts to do so will invalidate the signature and make the disk unusable. All code beyond a limited core is stored in an online file to which you do not have write access. Probably. Contact gollark for further information."
			runfile "/rom/programs/shell.lua" 
		end,
		description = "Open an unsandboxed shell."
	},
	update = {
		fn = function() runfile("autorun", "update") end,
		description = "Update PotatOS."
	},
	dump_license = {
		fn = function() print(UUID) textutils.pagedPrint(textutils.serialise(license)) end,
		description = "Dump license information."
	},
	primes = {
		fn = function()
			if not _G.findprime or not _G.isprime then
				error "findprime/isprime not available. Update potatOS."
			end
			write "Difficulty? (1-16) "
			local difficulty = tonumber(read())
			if type(difficulty) ~= "number" then error "ERR_PEBKAC\nThat's not a number." end
			local maxrand = math.pow(10, difficulty)
			local p1 = findprime(math.random(2, maxrand))
			local p2 = findprime(math.random(2, maxrand))
			
			local num = p1 * p2
            print("Please find the prime factors of the following number:", num)
            write "Factor 1: "
            local f1 = tonumber(read())
            write "Factor 2: "
            local f2 = tonumber(read())
            if (f1 == p1 and f2 == p2) or (f2 == p1 and f1 == p2) then
                print "Yay! You got it right!"
            else
                print("Factors", f1, f2, "invalid.", p1, p2, "expected.")
            end
		end,
		description = "Bored? You can factor some semiprimes!"
	},
	potatoplex = {
		fn = function() 
			write "Run potatoplex with arguments: "
			local args = read()
			runfile("rom/programs/http/pastebin.lua", "run", "wYBZjQhN", args)
		end,
		description = "Potatoplex your life!"
	},
	chronometer = {
		fn = function() 
			runfile("rom/programs/http/pastebin.lua", "run", "r24VMWk4")
		end,
		description = "Tell the time with Chronometer!"
	},
	latest_paste = {
		fn = function()
			write "WARNING: This views the latest paste on Pastebin. Exposure to the raw output of the Internet may be detrimental to your mental health. Do you want to continue (y/n)? "
			local yn = read()
			if not yn:lower():match "y" then return end
			local html = fetch "https://pastebin.com/LW9RFpmY"
			local id = html:match [[<ul class="right_menu"><li><a href="/([A-Za-z0-9]+)">]]
			local url = ("https://pastebin.com/raw/%s"):format(id)
			local title = html:match [[<ul class="right_menu"><li><a href="/[A-Za-z0-9]+">([^<]+)</a>]]
			local content = fetch(url)
			term.clear()
			term.setCursorPos(1, 1)
			textutils.pagedPrint(title .. "\n" .. url .. "\n\n" .. content)
		end,
		description = "View latest paste on Pastebin."
	}
}

local function wait()
	write "Press Any key to continue."
	os.pullEvent "key"
	local timer = os.startTimer(0)
	while true do
		local e, arg = os.pullEvent()
		if (e == "timer" and arg == timer) or e == "char" then return end
	end
end

if not license then
	printError(([[ERR_NO_LICENSE
This disk (UUID %s) does not have an attached license and is invalid.
This should not actually happen, unless you have meddled with the disk while somehow keeping the signature intact.
Please contact gollark.]]):format(tostring(UUID)))
	try_report_incident(("OmniDisk UUID %s has no license data"):format(tostring(UUID)), {"security", "omnidisk"}, {
		extra_meta = {
			disk_ID = disk_ID,
			omnidisk_UUID = UUID
		}
	})
	wait()
	os.reboot()
end

if disk_ID then
	local license_ID = license.disk
	local ok = false
	if type(license_ID) == "table" then
		for _, id in pairs(license_ID) do
			if id == disk_ID then ok = true break end
		end
	elseif type(license_ID) == "number" then
		if license_ID == disk_ID then ok = true end
	else
		ok = true
	end
	if not ok then
		printError(([[ERR_WRONG_DISK
This disk (ID %d) is not (one of) the disk(s) specified in your licensing information.
This license (UUID %s) allows use of this/these disk(s): %s.
If you believe this to be in error, please contact gollark so this can be corrected.
Otherwise, stop cloning disks, or contact gollark to have unique UUIDs issued to each.]]):format(disk_ID, UUID, json.encode(license_ID)))
		try_report_incident(("Disk ID mismatch: %d used with license %s"):format(disk_ID, UUID, json.encode(license_ID)), {"security", "omnidisk"}, {
			extra_meta = {
				permitted_disk_IDs = license_ID,
				disk_ID = disk_ID,
				omnidisk_UUID = UUID
			}
		})
		wait()
		os.reboot()
	end
end

local permitted_feature_lookup = {}
for _, feature in pairs(license.features) do
	permitted_feature_lookup[feature] = true
end

while true do
	term.setCursorPos(1, 1)
	term.clear()

	local usable = {}
	local i = 0

	print [[Welcome to PotatOS OmniDisk!
Available options:]]

	for name, feature in pairs(features) do
		if permitted_feature_lookup["*"] or permitted_feature_lookup[name] or feature.always_permitted then
			textutils.pagedPrint(("%d. %s - %s"):format(i, name, feature.description or "[no description available]"))
			usable[i] = feature.fn
			usable[name] = feature.fn
			i = i + 1
		end
	end

	write "Select an option: "
	local option = read()
	local fn
	local as_num = tonumber(option)

	if as_num then fn = usable[as_num] else fn = usable[option] end
	if not fn then
		printError(("ERR_ID_10T\nPlease select an option which actually exists.\n'%s' doesn't."):format(tostring(option)))
		wait()
	else
		local ok, res = pcall(fn)
		if not ok then
			printError(res)
			wait()
		else
			wait()
		end
	end
end
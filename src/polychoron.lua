local version = "1.6"

-- Localize frequently used functions for performance
local osepoch = os.epoch
local osclock = os.clock
local stringformat = string.format
local coroutineresume = coroutine.resume
local coroutineyield = coroutine.yield
local coroutinestatus = coroutine.status
local tostring = tostring
local ccemuxnanoTime
if ccemux then
	ccemuxnanoTime = ccemux.nanoTime
end

-- Return a time of some sort. Not used to provide "objective" time measurement, just for duration comparison
local function time()
	if ccemuxnanoTime then
		return ccemuxnanoTime() / 1e9
	elseif osepoch then 
		return osepoch "utc" / 1000 else 
	return osclock() end
end

local processes = {}
_G.process = {}

-- Allow getting processes by name, and nice process views from process.list()
local process_list_mt = {
	__tostring = function(ps)
		local o = ""
		for _, p in pairs(ps) do
			o = o .. tostring(p)
			o = o .. "\n"
		end
		return o:gsub("\n$", "") -- strip trailing newline
	end,
	__index = function(tabl, key)
		for i, p in pairs(tabl) do
			if p.name == key then return p end
		end
	end
}
setmetatable(processes, process_list_mt)

-- To make suspend kind of work with sleep, we need to bodge it a bit
-- So this modified sleep *also* checks the time, in case timer events were eaten
function _G.sleep(time)
	time = time or 0
	local t = os.startTimer(time)
	local start = os.clock()
	local ev, arg, tdiff

	repeat
		ev, arg = os.pullEvent()
	until (ev == "timer" and arg == t) or (os.clock() - start) > time
end

process.statuses = {
	DEAD = "dead",
	ERRORED = "errored",
	OK = "ok",
	STOPPED = "stopped"
}

process.signals = {
	START = "start",
	STOP = "stop",
	TERMINATE = "terminate",
	KILL = "kill"
}

-- Gets the first key in a table with the given value
local function get_key_with_value(t, v)
	for tk, tv in pairs(t) do
		if v == tv then
			return tk
		end
	end
end

-- Contains custom stringification, and an equality thing using IDs
local process_metatable = {
	__tostring = function(p)
		local text = stringformat("[process %d %s: %s", p.ID, p.name or "[unnamed]", get_key_with_value(process.statuses, p.status) or "?")
		if p.parent then
			text = text .. stringformat("; parent %s", p.parent.name or p.parent.ID)
		end
		return text .. "]"
	end,
	__eq = function(p1, p2)
		return p1.ID == p2.ID
	end
}

-- Whitelist of events which ignore filters.
local allow_event = {
	terminate = true
}

local function process_to_info(p)
	if not p then return nil end
	local out = {}
	for k, v in pairs(p) do
		if k == "parent" and v ~= nil then
			out.parent = process_to_info(v)
		else
			-- PS#85DD8AFC
			-- Through some bizarre environment weirdness even exposing the function causes security risks. So don't.
			if k ~= "coroutine" and k ~= "function" then
				out[k] = v
			end
		end
	end
	setmetatable(out, process_metatable)
	return out
end

-- Fancy BSOD
local function BSOD(e)
	if _G.add_log then _G.add_log("BSOD recorded: %s", e) end
	if term.isColor() then term.setBackgroundColor(colors.blue) term.setTextColor(colors.white)
	else term.setBackgroundColor(colors.white) term.setTextColor(colors.black) end

	term.clear()
	term.setCursorBlink(false)
	term.setCursorPos(1, 1)
	
	print(e)
end

local running
-- Apply "event" to "proc"
-- Where most important stuff happens
local function tick(proc, event)
	if not proc then error "No such process" end
	if process.running and process.running.ID == proc.ID then return end

	-- Run any given event preprocessor on the event
	-- Actually don't, due to (hypothetical) PS#D7CD76C0-like exploits
	--[[
	if type(proc.event_preprocessor) == "function" then
		event = proc.event_preprocessor(event)
		if event == nil then return end
	end
	]]

	-- If coroutine is dead, just ignore it but set its status to dead
	if coroutinestatus(proc.coroutine) == "dead" then
		proc.status = process.statuses.DEAD
		if proc.ephemeral then
			processes[proc.ID] = nil
		end
	end
	-- If coroutine ready and filter matches or event is allowed, run it, set the running process in its environment,
	-- get execution time, and run error handler if errors happen.
	if proc.status == process.statuses.OK and (proc.filter == nil or proc.filter == event[1] or (type(proc.filter) == "table" and proc.filter[event[1]]) or allow_event[event[1]]) then
		process.running = process_to_info(proc)
		running = proc
		local start_time = time()
		local ok, res = coroutineresume(proc.coroutine, table.unpack(event))
		local end_time = time()
		proc.execution_time = end_time - start_time
		proc.ctime = proc.ctime + end_time - start_time
		if not ok then
			if proc.error_handler then
				proc.error_handler(res)
			else
				proc.status = process.statuses.ERRORED
				proc.error = res
				if res ~= "Terminated" then -- programs terminating is normal, other errors not so much
					BSOD(stringformat("Process %s has crashed!\nError: %s", proc.name or tostring(proc.ID), tostring(res)))
				end
			end
		else
			proc.filter = res
		end
		process.running = nil
	end
end

function process.get_running()
	return running
end

-- Send/apply the given signal to the given process
local function apply_signal(proc, signal)
	local rID = nil
	if process.running then rID = process.running.ID end
	tick(proc, { "signal", signal, rID })
	-- START - starts stopped process
	if signal == process.signals.START and proc.status == process.statuses.STOPPED then
		proc.status = process.statuses.OK
	-- STOP stops started process
	elseif signal == process.signals.STOP and proc.status == process.statuses.OK then
		proc.status = process.statuses.STOPPED
	elseif signal == process.signals.TERMINATE then
		proc.terminated_time = os.clock()
		tick(proc, { "terminate" })
	elseif signal == process.signals.KILL then
		proc.status = process.statuses.DEAD
	end
end

local next_ID = 1
function process.spawn(fn, name, extra)
	local this_ID = next_ID
	local proc = {
		coroutine = coroutine.create(fn),
		name = name,
		status = process.statuses.OK,
		ID = this_ID,
		parent = process.running,
		["function"] = fn,
		ctime = 0
	}

	if extra then for k, v in pairs(extra) do proc[k] = v end end

	setmetatable(proc, process_metatable)
	processes[this_ID] = proc
	next_ID = next_ID + 1
	return this_ID
end

function process.thread(fn, name)
	local parent = process.running.name or tostring(process.running.ID)
	process.spawn(fn, ("%s_%s_%04x"):format(name or "thread", parent, math.random(0, 0xFFFF)), { ephemeral = true })
end

-- Sends a signal to the given process ID
function process.signal(ID, signal)
	if not processes[ID] then error(stringformat("No such process %s.", tostring(ID))) end
	apply_signal(processes[ID], signal)
end

-- PS#F7686798
-- Prevent mutation of processes through exposed API to prevent PS#D7CD76C0-like exploits
-- List all processes
function process.list()
	local out = {}
	for k, v in pairs(processes) do
		out[k] = process_to_info(v)
	end
	return setmetatable(out, process_list_mt)
end

function process.info(ID)
	return process_to_info(processes[ID])
end

-- Run main event loop
local function run_loop()
	while true do
		local ev = {coroutineyield()}
		for ID, proc in pairs(processes) do
			tick(proc, ev)
		end
	end
end

local base_processes = {
	["main"] = function() os.run({}, "autorun.lua") end,
	["rednetd"] = function()
		-- bodge, because of the stupid rednet bRunning thing
		local old_error = error
		_G.error = function() _G.error = old_error end
		rednet.run()
	end
}

-- hacky magic to run our code and not the BIOS stuff
-- this terminates the shell, which crashes the BIOS, which then causes an error, which is printed with printError
local old_printError = _G.printError
function _G.printError() 
	_G.printError = old_printError
	-- Multishell must die.
	term.redirect(term.native())
	multishell = nil
	term.setTextColor(colors.yellow)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(1,1)
	term.clear()

	_G.polychoron = {version = version, process = process}
	polychoron.polychoron = polychoron
	polychoron.BSOD = BSOD

	for n, p in pairs(base_processes) do
		process.spawn(p, n)
	end

	os.queueEvent "event" -- so that processes get one free "tick"
	run_loop()
end

os.queueEvent "terminate"
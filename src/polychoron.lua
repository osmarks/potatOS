local DEBUG_MODE = settings.get "potatOS.polychoron_debug"

-- Localize frequently used functions for performance
local osepoch = os.epoch
local osclock = os.clock
local stringformat = string.format
local coroutineresume = coroutine.resume
local coroutineyield = coroutine.yield
local coroutinestatus = coroutine.status
local tostring = tostring
local coroutinecreate = coroutine.create
local pairs = pairs
local ipairs = ipairs
local setmetatable = setmetatable
local tableinsert = table.insert
local assert = assert
local error = error
local tableunpack = table.unpack
local debugtraceback = debug and debug.traceback
local osqueueevent = os.queueEvent
local ccemuxnanoTime
local ccemuxecho
if ccemux then
	ccemuxnanoTime = ccemux.nanoTime
	ccemuxecho = ccemux.echo
end
local outer_process = _G.process

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

local function copy(t)
	local out = {}
	for k, v in pairs(t) do
		out[k] = v
	end
	return out
end

local statuses = {
	DEAD = "dead",
	ERRORED = "errored",
	OK = "ok",
	STOPPED = "stopped"
}
process.statuses = copy(statuses)

local signals = {
	START = "start",
	STOP = "stop",
	TERMINATE = "terminate",
	KILL = "kill"
}
process.signals = copy(signals)

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
		if type(key) == "table" and key.ID then return tabl[key.ID] end
		for i, p in pairs(tabl) do
			if p.name == key and p.status ~= statuses.DEAD then return p end
		end
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
	local start = osclock()
	local ev, arg, tdiff

	repeat
		ev, arg = os.pullEvent()
	until (ev == "timer" and arg == t) or (osclock() - start) > time
end

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
	if DEBUG_MODE then return p end
	if not p then return nil end
	local out = {}
	for k, v in pairs(p) do
		if k == "parent" and v ~= nil then
			out.parent = process_to_info(v)
		elseif k == "thread_parent" and v ~= nil then
			out.thread_parent = process_to_info(v)
		else
			-- PS#85DD8AFC
			-- Through some bizarre environment weirdness even exposing the function causes security risks. So don't.
			if k ~= "coroutine" and k ~= "function" and k ~= "table" then
				out[k] = v
			end
		end
	end
	out.capabilities = { restrictions = copy(p.capabilities.restrictions), grants = copy(p.capabilities.grants) }
	setmetatable(out, process_metatable)
	return out
end

-- Fancy BSOD
local function BSOD(e)
	if false then

	if _G.add_log then _G.add_log("failure recorded: %s", e) end
	if _G.add_log and debugtraceback then _G.add_log("stack traceback: %s", debugtraceback()) end
	if term.isColor() then term.setBackgroundColor(colors.blue) term.setTextColor(colors.white)
	else term.setBackgroundColor(colors.white) term.setTextColor(colors.black) end

	term.clear()
	term.setCursorBlink(false)
	term.setCursorPos(1, 1)

	print(e)
	end
end

local running
-- Apply "event" to "proc"
-- Where most important stuff happens
local function tick(proc, event)
	if not proc then error "Internal error: No such process" end
	if running then return end

	-- Run any given event preprocessor on the event
	-- Actually don't, due to (hypothetical) PS#D7CD76C0-like exploits
	--[[
	if type(proc.event_preprocessor) == "function" then
		event = proc.event_preprocessor(event)
		if event == nil then return end
	end
	]]

	-- If coroutine is dead, just ignore it and set its status to dead
	if coroutinestatus(proc.coroutine) == "dead" or proc.status == statuses.DEAD then
		proc.status = statuses.DEAD
		if proc.thread then processes[proc.ID] = nil end
		return
	end
	-- If coroutine ready and filter matches or event is allowed, run it, set the running process in its environment,
	-- get execution time, and run error handler if errors happen.
	if proc.status == statuses.OK and (proc.filter == nil or proc.filter == event[1] or (type(proc.filter) == "table" and proc.filter[event[1]]) or allow_event[event[1]]) then
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
				proc.status = statuses.ERRORED
				proc.error = res
				if res ~= "Terminated" then -- programs terminating is normal, other errors not so much
					BSOD(stringformat("Process %s has crashed!\nError: %s", proc.name or tostring(proc.ID), tostring(res)))
				end
			end
		else
			proc.filter = res
		end
		running = nil
		process.running = nil
	end
end

local queue = {}
local events_are_queued = false

local function find_all_in_group(id)
	local proc = processes[id]
	if proc.thread then
		proc = proc.thread_parent
	end
	local procs = {proc}
	for _, p in pairs(processes) do
		if p.thread_parent == proc then
			tableinsert(procs, p)
		end
	end
	return procs
end

local function enqueue(id, event)
	events_are_queued = true
	for _, tg in pairs(find_all_in_group(id)) do
		local id = tg.ID
		queue[id] = queue[id] or {}
		tableinsert(queue[id], event)
	end
end

function process.get_running()
	return process_to_info(running)
end

function process.IPC(target, ...)
	if not processes[target] then error(stringformat("No such process %s.", tostring(target))) end
	enqueue(processes[target].ID, { "ipc", running.ID, ... })
end

-- Send/apply the given signal to the given process
local function apply_signal(proc, signal)
	enqueue(proc.ID, { "signal", signal, running.ID })
	if signal == signals.TERMINATE then
		enqueue(proc.ID, { "terminate" })
	end
	for _, proc in pairs(find_all_in_group(proc.ID)) do
		-- START - starts stopped process
		if signal == signals.START and proc.status == statuses.STOPPED then
			proc.status = statuses.OK
		-- STOP stops started process
		elseif signal == signals.STOP and proc.status == statuses.OK then
			proc.status = statuses.STOPPED
		elseif signal == signals.TERMINATE then
			proc.terminated_time = osclock()
		elseif signal == signals.KILL then
			proc.status = statuses.DEAD
		end
	end
end

local function ensure_no_metatables(x)
	if type(x) ~= "table" then return end
	assert(getmetatable(x) == nil)
	for k, v in pairs(x) do
		ensure_no_metatables(v)
		ensure_no_metatables(k)
	end
end

local root_capability = {"root"}

local function ensure_capabilities_subset(x, orig)
	x.grants = x.grants or {}
	x.restrictions = x.restrictions or {}
	ensure_no_metatables(x)
	assert(type(x.restrictions) == "table")
	assert(type(x.grants) == "table")
	if orig.grants[root_capability] then return end
	for restriction, value in pairs(orig.restrictions) do
		x.restrictions[restriction] = value
	end
	for grant, enabled in pairs(x.grants) do
		if enabled and not orig.grants[grant] then
			x.grants[grant] = false
		end
	end
end

local function are_capabilities_subset(x, orig)
	if orig.grants[root_capability] then return true end
	for restriction, value in pairs(orig.restrictions) do
		if x.restrictions[restriction] ~= value then
			return false
		end
	end
	for grant, enabled in pairs(x.grants) do
		if enabled and not orig.grants[grant] then
			return false
		end
	end
	return true
end

local next_ID = 1
local function spawn(fn, name, thread, capabilities)
	name = tostring(name)
	local this_ID = next_ID
	if not capabilities then
		capabilities = running.capabilities
	end
	if running then ensure_capabilities_subset(capabilities, running.capabilities) end
	local proc = {
		coroutine = coroutinecreate(fn),
		name = name,
		status = statuses.OK,
		ID = this_ID,
		parent = running,
		["function"] = fn,
		ctime = 0,
		capabilities = capabilities
	}

	if thread then
		proc.thread_parent = running.thread_parent or running
		proc.thread = true
		proc.parent = running.parent
	end

	setmetatable(proc, process_metatable)
	processes[this_ID] = proc
	next_ID = next_ID + 1
	return this_ID
end

function process.spawn(fn, name, capabilities)
	return spawn(fn, name, nil, capabilities)
end

function process.thread(fn, name)
	local parent = running.name or tostring(running.ID)
	return spawn(fn, ("%s_%s_%04x"):format(name or "th", parent, math.random(0, 0xFFFF)), true)
end

-- Sends a signal to the given process ID
function process.signal(ID, signal)
	if not processes[ID] then error(stringformat("No such process %s.", tostring(ID))) end
	apply_signal(processes[ID], signal)
end

function process.has_grant(g)
	return running.capabilities.grants[g] or running.capabilities.grants[root_capability] or false
end

function process.restriction(r)
	return running.capabilities.restrictions[r] or nil
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

function os.queueEvent(...)
	enqueue(running.ID, {...})
end

local function ancestry_includes(proc, anc)
	repeat
		if proc == anc then
			return true
		end
		proc = proc.parent
	until not proc
	return false
end

function process.is_ancestor(proc, anc)
	return ancestry_includes(processes[proc], processes[anc])
end

function process.queue_in(ID, ...)
	local parent = processes[ID]
	if not parent then error(stringformat("No such process %s.", tostring(ID))) end
	for ID, proc in pairs(processes) do
		if ancestry_includes(proc, parent) and are_capabilities_subset(proc.capabilities, running.capabilities) and not proc.thread then
			enqueue(proc.ID, {...})
		end
	end
end

local dummy_event = ("%07x"):format(math.random(0, 0xFFFFFFF))
-- Run main event loop
local function run_loop()
	while true do
		if events_are_queued then
			events_are_queued = false
			for target, events in pairs(queue) do
				for _, event in ipairs(events) do
					tick(processes[target], event)
				end
				queue[target] = nil
			end
			osqueueevent(dummy_event)
		else
			local ev = {coroutineyield()}
				if ev[1] ~= dummy_event then
				for ID, proc in pairs(processes) do
					tick(proc, ev)
				end
			end
		end
	end
end

local function boot(desc)
    if ccemuxecho then ccemuxecho(desc .. " executed " .. (debugtraceback and debugtraceback() or "succesfully")) end

	term.redirect(term.native())
	multishell = nil
	term.setTextColor(colors.yellow)
	term.setBackgroundColor(colors.black)
	term.setCursorPos(1,1)
	term.clear()

	process.spawn(function() os.run({}, "autorun.lua") end, "main", { grants = { [root_capability] = true }, restrictions = {} })

	process.spawn(function()
		-- bodge, because of the rednet bRunning thing
		local old_error = error
		error = function() error = old_error end
		rednet.run()
	end, "rednetd", { grants = {}, restrictions = {} })

	osqueueevent "" -- tick everything once
	run_loop()
end

-- fix nested potatOSes
if outer_process then
    -- cannot TLCO; run under outer process manager
    outer_process.spawn(function() boot "nested boot" end, "polychoron")
    while true do coroutine.yield() end
else
    -- fixed TLCO from https://gist.github.com/MCJack123/42bc69d3757226c966da752df80437dc
    local old_error = error
    local old_os_shutdown = os.shutdown
    local old_term_redirect = term.redirect
    local old_term_native = term.native
    local old_printError = printError
    function error() end
    function term.redirect() end
    function term.native() end
    function printError() end
    function os.shutdown()
       	error = old_error
       	_G.error = old_error
       	_ENV.error = old_error
       	printError = old_printError
       	_G.printError = old_printError
       	_ENV.printError = old_printError
       	term.native = old_term_native
       	term.redirect = old_term_redirect
       	os.shutdown = old_os_shutdown
       	os.pullEventRaw = coroutine.yield
       	boot "TLCO"
    end

    os.pullEventRaw = nil
end

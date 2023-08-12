-- see pastebin.com/NdUKJ07j for license info
-- mostly written by SquidDev, bodged by gollark/osmarks

local type = type
local debug_traceback = type(debug) == "table" and type(debug.traceback) == "function" and debug.traceback

local _pcall, _xpcall = pcall, xpcall

local function traceback(x)
  -- Attempt to detect error() and error("xyz", 0).
  -- This probably means they're erroring the program intentionally and so we
  -- shouldn't display anything.
  if x == nil or (type(x) == "string" and not x:find(":%d+:")) or type(x) ~= "string" then
    return x
  end

  if debug_traceback then
    -- The parens are important, as they prevent a tail call occuring, meaning
    -- the stack level is preserved. This ensures the code behaves identically
    -- on LuaJ and PUC Lua.
    return (debug_traceback(tostring(x), 2))
  else
    local level = 3
    local out = { tostring(x), "stack traceback:" }
    while true do
      local _, msg = _pcall(error, "", level)
      if msg == "" then break end

      out[#out + 1] = "  " .. msg
      level = level + 1
    end

    return table.concat(out, "\n")
  end
end

local function trim_traceback(target, marker)
  local target = tostring(target)
  local ttarget, tmarker = {}, {}
  for line in target:gmatch("([^\n]*)\n?") do ttarget[#ttarget + 1] = line end
  for line in marker:gmatch("([^\n]*)\n?") do tmarker[#tmarker + 1] = line end

  -- Trim identical suffixes
  local t_len, m_len = #ttarget, #tmarker
  while t_len >= 3 and ttarget[t_len] == tmarker[m_len] do
    table.remove(ttarget, t_len)
    t_len, m_len = t_len - 1, m_len - 1
  end

  -- Trim elements from this file and xpcall invocations
  while t_len >= 1 and ttarget[t_len]:find("^\tstack_trace%.lua:%d+:") or
        ttarget[t_len] == "\t[C]: in function 'xpcall'" or ttarget[t_len] == "  xpcall: " do
    table.remove(ttarget, t_len)
    t_len = t_len - 1
  end

  return ttarget
end

--- Run a function with
local function xpcall_with(fn, ...)
  local args = {...}
  -- So this is rather grim: we need to get the full traceback and current one and remove
  -- the common prefix
  local trace
  local res = table.pack(_xpcall(function() return fn(unpack(args)) end, traceback)) if not res[1] then trace = traceback("stack_trace.lua:1:") end
  local ok, err = res[1], res[2]

  -- PS#EAB415D8: CC now uses error sentinel things in some places; we do not want to make those strings
  if not ok and err ~= nil and type(err) == "string" then
    trace = trim_traceback(err, trace)

    -- Find the position where the stack traceback actually starts
    local trace_starts
    for i = #trace, 1, -1 do
      if trace[i] == "stack traceback:" then trace_starts = i; break end
    end

    -- If this traceback is more than 15 elements long, keep the first 9, last 5
    -- and put an ellipsis between the rest
    local max = 15
    if trace_starts and #trace - trace_starts > max then
      local keep_starts = trace_starts + 10
      for i = #trace - trace_starts - max, 0, -1 do table.remove(trace, keep_starts + i) end
      table.insert(trace, keep_starts, "  ...")
    end

    return false, table.concat(trace, "\n")
  end

  return table.unpack(res, 1, res.n)
end

_G.pcall = xpcall_with
return xpcall_with
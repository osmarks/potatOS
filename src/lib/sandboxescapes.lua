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

local escapes = {
    load_env = function()
        local k = dgetfenv(load("")).fs
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
local vfs = {}

local getters = {"is", "has", "get"}
local setters = {"set"}

function vfs.list(path)
    local segs = fs.segment(path)
    if #segs == 0 then
        return peripheral.getNames()
    elseif #segs == 1 then
        local methods = peripheral.getMethods(segs[1])
        local out = {}
        for _, v in pairs(methods) do
            local set
            for _, s in pairs(setters) do
                local mat = v:match("^" .. s .. "([A-Z].+)")
                if mat then
                    set = mat
                    break
                end
            end
            local get
            for _, g in pairs(getters) do
                local mat = v:match("^" .. g .. "([A-Z].+)")
                if mat then
                    get = mat
                    break
                end
            end
            if get then table.insert(out, get)
            elseif set then table.insert(out, set)
            else table.insert(out, v) end
        end
        return out
    elseif #segs == 2 then

    end
end

local function write_handle(callback)
    local buffer = ""
    local r_write_handle = {}
    function r_write_handle.write(text)
        buffer = buffer .. text
    end
    function r_write_handle.close()
        callback(buffer)
    end
    function r_write_handle.flush() end
    function r_write_handle.writeLine(text) r_write_handle.write(text) r_write_handle.write("\n") end
    return r_write_handle
end

local call_results = {}

function vfs.open(path, mode)
    local segs = fs.segment(path)
    if #segs == 2 and segs[2]:match "^[A-Z]" then -- getter/setter configuration
        if mode:match "w" then
            return write_handle(function(buffer)
                local ok, res
                for _, s in pairs(setters) do
                    local ok2, res2 = pcall(peripheral.call, segs[1], s .. segs[2], textutils.unserialise(buffer))
                    ok = ok or ok2
                    res = res or res2
                end
                if not ok then error(res) end
            end)
        else
            -- TODO multiple returns
            local result
            for _, g in pairs(getters) do
                local ok, res = pcall(peripheral.call, segs[1], g .. segs[2])
                result = result or (ok and res)
            end
            local text = textutils.serialise(result)
            return fs._make_handle(text)
        end
    elseif #segs == 2 then
        if mode:match "^w" then
            return write_handle(function(buffer)
                call_results[fs.combine(path, "")] = peripheral.call(segs[1], segs[2], unpack(textutils.unserialise(buffer)))
            end)
        end
        if mode:match "^r" then
            local rp = fs.combine(path, "")
            local h
            if call_results[rp] then h = fs._make_handle(textutils.serialise(call_results[rp]))
            else h = fs._make_handle("") end
            call_results[rp] = nil
            return h
        end
        error "invalid IO mode"
    end
end

function vfs.exists(path)
    local segs = fs.segment(path)
    if #segs == 0 then
        return true
    else
        return peripheral.getType(segs[1]) ~= nil
    end
end

function vfs.isReadOnly(path)
    local segs = fs.segment(path)
    if #segs == 2 and segs[2]:match "^[A-Z]" then -- getter/setter configuration
        local methods = peripheral.getMethods(segs[1])
        for _, s in pairs(setters) do
            for _, m in pairs(methods) do
                if m == s .. segs[2] then
                    return false
                end
            end
        end
        return true
    end
    return false
end

function vfs.isDir(path)
    local segs = fs.segment(path)
    return #segs <= 1
end
function vfs.getDrive(path) return "devfs" end

fs.mountVFS(shell.resolve(...), vfs)

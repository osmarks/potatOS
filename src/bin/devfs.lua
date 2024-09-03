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
    local write_handle = {}
    function write_handle.write(text)
        buffer = buffer .. text
    end
    function write_handle.close()
        callback(buffer)
    end
    function write_handle.flush() end
    function write_handle.writeLine(text) write_handle.write(text) write_handle.write("\n") end
    return write_handle
end

function vfs.open(path, mode)
    local segs = fs.segment(path)
    if #segs == 2 and segs[2]:match "^[A-Z]" then -- getter/setter configuration
        if mode:match "w" then
            return write_handle(function(buffer)
                local ok, res
                for _, s in pairs(setters) do
                    local ok2, res2 = pcall(peripheral.call, segs[1], s .. segs[2], json.decode(buffer))
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
            local text = json.encode(result)
            return fs._make_handle(text)
        end
    elseif #segs == 2 then
        if mode:match "w" then
            return write_handle(function(buffer)
                peripheral.call(segs[1], segs[2], json.decode(buffer))
            end)
        end
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
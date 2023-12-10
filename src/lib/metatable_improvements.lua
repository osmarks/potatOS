
-- Accesses the PotatOS Potatocloud(tm) Potatostore(tm). Used to implement Superglobals(tm) - like globals but on all computers.
-- To be honest I should swap this out for a self-hosted thing like Kinto.
--[[
Fix for PS#4F329133
JSONBin (https://jsonbin.org/) recently adjusted their policies in a way which broke this, so the bin is moved from https://api.jsonbin.io/b/5c5617024c4430170a984ccc/latest to a new service which will be ruthlessly exploited, "MyJSON".

Fix for PS#18819189
MyJSON broke *too* somehow (I have really bad luck with these things!) so move from https://api.myjson.com/bins/150r92 to "JSONBin".

Fix for PS#8C4CB942
The other JSONBin thing broke too so just implement it in RSAPI
]]

return function(add_log, report_incident)
    function fetch(u, ...)
        if not http then error "No HTTP access" end
        local h,e = http.get(u, ...)
        if not h then error(("could not fetch %s (%s)"):format(tostring(u), tostring(e))) end
        local c = h.readAll()
        h.close()
        return c
    end

    local bin_URL = "https://r.osmarks.net/superglobals/"
    local bin = {}
    local localbin = {}

    function bin.get(k)
        if localbin[k] then
            return localbin[k]
        else
            local ok, err = pcall(function()
                local r = fetch(bin_URL .. textutils.urlEncode(tostring(k)), nil, true)
                local ok, err = pcall(json.decode, r)
                if not ok then return r end
                return err
            end)
            if not ok then add_log("superglobals fetch failed %s", tostring(err)) return nil end
            return err
        end
    end

    function bin.set(k, v)
        local ok, err = pcall(function()
            b[k] = v
            local h, err = http.post(bin_URL .. textutils.urlEncode(tostring(k)), json.encode(v), nil, true)
            if not h then error(err) end
        end)
        if not ok then localbin[k] = v add_log("superglobals set failed %s", tostring(err)) end
    end

    local bin_mt = {
        __index = function(_, k) return bin.get(k) end,
        __newindex = function(_, k, v) return bin.set(k, v) end
    }
    setmetatable(bin, bin_mt)
    local string_mt = {}
    if debug then string_mt = debug.getmetatable "" end

    local function define_operation(mt, name, fn)
        mt[name] = function(a, b)
            if getmetatable(a) == mt then return fn(a, b)
            else return fn(b, a) end
        end
    end

    local frac_mt = {}
    function frac_mt.__tostring(x)
        return ("[Fraction] %s/%s"):format(textutils.serialise(x.numerator), textutils.serialise(x.denominator))
    end
    define_operation(frac_mt, "__mul", function (a, b)
        return (a.numerator * b) / a.denominator
    end)

    -- Add exciting random stuff to the string metatable.
    -- Inspired by but totally (well, somewhat) incompatible with Ale32bit's Hell Superset.
    function string_mt.__index(s, k)
        if type(k) == "number" then
            local c = string.sub(s, k, k)
            if c == "" then return nil else return c end
        end
        return _ENV.string[k] or bin.get(k)
    end
    function string_mt.__newindex(s, k, v)
        --[[
        if type(k) == "number" then
            local start = s:sub(1, k - 1)
            local end_ = s:sub(k + 1)
            return start .. v .. end_
        end
        ]]
        return bin.set(k, v)
    end
    function string_mt.__add(lhs, rhs)
        return tostring(lhs) .. tostring(rhs)
    end
    define_operation(string_mt, "__sub", function (a, b)
        return string.gsub(a, b, "")
    end)
    function string_mt.__unm(a)
        return string.reverse(a)
    end
    -- http://lua-users.org/wiki/SplitJoin
    function string.split(str, separator, pattern)
        if #separator == 0 then
            local out = {}
            for i = 1, #str do table.insert(out, str:sub(i, i)) end
            return out
        end
        local xs = {}

        if str:len() > 0 then
            local field, start = 1, 1
            local first, last = str:find(separator, start, not pattern)
            while first do
                xs[field] = str:sub(start, first-1)
                field = field + 1
                start = last + 1
                first, last = str:find(separator, start, not pattern)
            end
            xs[field] = str:sub(start)
        end
        return xs
    end
    function string_mt.__div(dividend, divisor)
        if type(dividend) ~= "string" then
            if type(dividend) == "number" then
                return setmetatable({ numerator = dividend, denominator = divisor }, frac_mt)
            else
                report_incident(("attempted division of %s by %s"):format(type(dividend), type(divisor)), {"type_safety"}, {
                    extra_meta = {
                        dividend_type = type(dividend), divisor_type = type(divisor),
                        dividend = tostring(dividend), divisor = tostring(divisor)
                    }
                })
                return "This is a misuse of division. This incident has been reported."
            end
        end
        if type(divisor) == "string" then return string.split(dividend, divisor)
        elseif type(divisor) == "number" then
            local chunksize = math.ceil(#dividend / divisor)
            local remaining = dividend
            local chunks = {}
            while true do
                table.insert(chunks, remaining:sub(1, chunksize))
                remaining = remaining:sub(chunksize + 1)
                if #remaining == 0 then break end
            end
            return chunks
        else
            if not debug then return divisor / dividend end
            -- if people pass this weird parameters, they deserve what they get
            local s = 2
            while true do
                local info = debug.getinfo(s)
                if not info then return -dividend / "" end
                if info.short_src ~= "[C]" then
                    local ok, res = pcall(string.dump, info.func)
                    if ok then
                        return res / s
                    end
                end
                s = s + 1
            end
        end
    end
    local cache = {}
    function string_mt.__call(s, ...)
        if cache[s] then return cache[s](...)
        else
            local f, err = load(s)
            if err then error(err) end
            cache[s] = f
            return f(...)
        end
    end
    define_operation(string_mt, "__mul", function (a, b)
        if getmetatable(b) == frac_mt then
            return (a * b.numerator) / b.denominator
        end
        if type(b) == "number" then
            return string.rep(a, b)
        elseif type(b) == "table" then
            local z = {}
            for _, v in pairs(b) do
                table.insert(z, tostring(v))
            end
            return table.concat(z, a)
        elseif type(b) == "function" then
            local out = {}
            for i = 1, #a do
                table.insert(out, b(a:sub(i, i)))
            end
            return table.concat(out)
        else
            return a
        end
    end)

    setmetatable(string_mt, bin_mt)
    if debug then debug.setmetatable(nil, bin_mt) end

    -- Similar stuff for functions.
    local func_funcs = {}
    local func_mt = {__index=func_funcs}
    if debug then debug.setmetatable(function() end, func_mt) end
    function func_mt.__sub(lhs, rhs)
        return function(...) return lhs(rhs(...)) end
    end
    function func_mt.__add(lhs, rhs)
        return function(...) return rhs(lhs(...)) end
    end
    function func_mt.__concat(lhs, rhs)
        return function(...)
            return lhs(...), rhs(...), nil -- limit to two return values
        end
    end
    function func_mt.__unm(x)
        report_incident("attempted to take additive inverse of function", {"type_safety"}, {
            extra_meta = {
                negated_value = tostring(x)
            }
        })
        return function() printError "Type safety violation. This incident has been reported." end
    end
    function func_funcs.dump(x) return string.dump(x) end
    function func_funcs.info(x) return debug.getinfo(x) end
    function func_funcs.address(x) return (string.match(tostring(x), "%w+$")) end

    -- Similar stuff for numbers too! NOBODY CAN ESCAPE!
    -- TODO: implement alternative mathematics.
    local num_funcs = {}
    local num_mt = {__index=num_funcs}
    num_mt.__call = function(x, ...)
        local out = x
        for _, y in pairs {...} do
            out = out + y
        end
        return out
    end
    if debug then debug.setmetatable(0, num_mt) end
    function num_funcs.tostring(x) return tostring(x) end
    function num_funcs.isNaN(x) return x ~= x end
    function num_funcs.isInf(x) return math.abs(x) == math.huge end
end
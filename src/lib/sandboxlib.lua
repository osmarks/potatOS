local sandboxlib = {}

local processhasgrant = process.has_grant
local processrestriction = process.restriction
local pairs = pairs
local setmetatable = setmetatable
local error = error
local tostring = tostring

function sandboxlib.create_sentinel(name)
    return {name}
end

function sandboxlib.dispatch_if_restricted(rkey, original, restricted)
    local out = {}
    for k, v in pairs(restricted) do
        if not original[k] then
            out[k] = v
        end
    end
    for k, v in pairs(original) do
        out[k] = function(...)
            if processrestriction(rkey) then
                if not restricted[k] then error("internal error: missing " .. tostring(k)) end
                return restricted[k](...)
            end
            return v(...)
        end
    end
    return out
end

function sandboxlib.allow_whitelisted(rkey, original, whitelist, fallback)
    local fallback = fallback or {}
    local whitelist_lookup = {}
    for _, v in pairs(whitelist) do
        whitelist_lookup[v] = true
    end
    local out = {}
    for k, v in pairs(original) do
        if whitelist_lookup[k] then
            out[k] = v
        else
            out[k] = function(...)
                if processrestriction(rkey) then
                    if not fallback[k] then
                        error("Security violation: " .. k)
                    else
                        return fallback[k](...)
                    end
                end
                return v(...)
            end
        end
    end
    return out
end

return sandboxlib
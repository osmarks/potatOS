-- by "Yevano", tweaked due to issues with signed integer handling
--[[
    BLODS - Binary Lua Object (De)Serialization
]]

--[[
    Save on table access.
]]
local pairs       = pairs
local type        = type
local loadstring  = loadstring
local mathabs     = math.abs
local mathfloor   = math.floor
local mathfrexp   = math.frexp
local mathmodf    = math.modf
local mathpow     = math.pow
local stringbyte  = string.byte
local stringchar  = string.char
local stringdump  = string.dump
local stringsub   = string.sub
local tableconcat = table.concat

--[[
    Float conversions. Modified from http://snippets.luacode.org/snippets/IEEE_float_conversion_144.
]]
local function double2str(value)
    local s=value<0 and 1 or 0
    if mathabs(value)==1/0 then
        return (s==1 and "\0\0\0\0\0\0\240\255" or "\0\0\0\0\0\0\240\127")
    end
    if value~=value then
        return "\170\170\170\170\170\170\250\255"
    end
    local fr,exp=mathfrexp(mathabs(value))
    fr,exp=fr*2,exp-1
    exp=exp+1023
    return tableconcat({stringchar(mathfloor(fr*2^52)%256),
    stringchar(mathfloor(fr*2^44)%256),
    stringchar(mathfloor(fr*2^36)%256),
    stringchar(mathfloor(fr*2^28)%256),
    stringchar(mathfloor(fr*2^20)%256),
    stringchar(mathfloor(fr*2^12)%256),
    stringchar(mathfloor(fr*2^4)%16+mathfloor(exp)%16*16),
    stringchar(mathfloor(exp/2^4)%128+128*s)})
end

local function str2double(str)
    local fr=stringbyte(str, 1)/2^52+stringbyte(str, 2)/2^44+stringbyte(str, 3)/2^36+stringbyte(str, 4)/2^28+stringbyte(str, 5)/2^20+stringbyte(str, 6)/2^12+(stringbyte(str, 7)%16)/2^4+1
    local exp=(stringbyte(str, 8)%128)*16+mathfloor(str:byte(7)/16)-1023
    local s=mathfloor(stringbyte(str, 8)/128)
    if exp==1024 then
        return fr==1 and (1-2*s)/0 or 0/0
    end
    return (1-2*s)*fr*2^exp
end

--[[
    Integer conversions. Taken from http://lua-users.org/wiki/ReadWriteFormat.
    Modified to support signed ints.
]]

local function signedstringtonumber(str)
  local function _b2n(exp, num, digit, ...)
    if not digit then return num end
    return _b2n(exp*256, num + digit*exp, ...)
  end
  return _b2n(256, stringbyte(str, 1, -1)) - mathpow(2, #str * 8 - 1)
end

local function stringtonumber(str)
    local function _b2n(exp, num, digit, ...)
      if not digit then return num end
      return _b2n(exp*256, num + digit*exp, ...)
    end
    return _b2n(256, stringbyte(str, 1, -1))
end

local function numbertobytes(num, width)
    local function _n2b(width, num, rem)
        rem = rem * 256
        if width == 0 then return rem end
        return rem, _n2b(width-1, mathmodf(num/256))
    end
    return stringchar(_n2b(width-1, mathmodf((num)/256)))
end

local function log2(x)
	return math.log10(x) / math.log10(2)
end

--[[
    (De)Serialization for Lua types.
]]

local function intWidth(int)
    local out = math.ceil((log2(int) + 1) / 8)
	if out == math.huge or out == -math.huge then return 1 end
	return out
end

local types = {
    boolean = "b",
    double = "d",
    posinteger = "p",
    neginteger = "n",
    string = "s",
    table = "t",
    ["function"] = "f",
    ["nil"] = "_"
}

local serialization = { }
local deserialization = { }

function serialization.boolean(obj)
    return obj and "\1" or "\0"
end

function serialization.double(obj)
    return double2str(obj)
end

function serialization.integer(obj)
    local width = intWidth(obj)
    return stringchar(width) .. numbertobytes(obj, width)
end

function serialization.string(obj)
    local len = #obj
    local width = intWidth(len)
    return tableconcat({ stringchar(width), numbertobytes(len, width), obj })
end

serialization["function"] = function(obj)
    local ok, s = pcall(stringdump, obj)
	if not ok then return "_" end
    return numbertobytes(#s, 4) .. s
end

function deserialization.b(idx, ser)
    local ret = stringsub(ser[1], idx, idx) == "\1"
    return ret, idx + 1
end

function deserialization.d(idx, ser)
    local ret = str2double(stringsub(ser[1], idx, idx + 8))
    return ret, idx + 8
end

function deserialization.p(idx, ser)
    local width = stringtonumber(stringsub(ser[1], idx, idx))
    local ret = stringtonumber(stringsub(ser[1], idx + 1, idx + width))
    return ret, idx + width + 1
end

function deserialization.n(idx, ser)
    local width = stringtonumber(stringsub(ser[1], idx, idx))
    local ret = stringtonumber(stringsub(ser[1], idx + 1, idx + width))
    return -ret, idx + width + 1
end

function deserialization.s(idx, ser)
    local width = stringtonumber(stringsub(ser[1], idx, idx))
    local len = stringtonumber(stringsub(ser[1], idx + 1, idx + width))
    local ret = stringsub(ser[1], idx + width + 1, idx + width + len)
    return ret, idx + width + len + 1
end

function deserialization.f(idx, ser)
    local len = stringtonumber(stringsub(ser[1], idx, idx + 3))
    local ret = loadstring(stringsub(ser[1], idx + 4, idx + len + 3))
    return ret, idx + len + 4
end

function deserialization._(idx, ser)
    return nil, idx
end

local function yield()
	os.queueEvent ""
	os.pullEvent ""
end

if not os.queueEvent then yield = function() end end

function serialize(obj)
    -- State vars.
    local ntables = 1
    local tables = { }
    local tableIDs = { }
    local tableSerial = { }

    -- Internal recursive function.
    local function serialize(obj)
		yield()
        local t = type(obj)
        if t == "table" then
            local len = #obj

            if tables[obj] then
                -- We already serialized this table. Just return the id.
                return tableIDs[obj]
            end

            -- Insert table info.
            local id = ntables
            tables[obj] = true
            local width = intWidth(ntables)
            local ser = "t" .. numbertobytes(width, 1) .. numbertobytes(ntables, width)
            tableIDs[obj] = ser

            -- Important to increment here so tables inside this one don't use the same id.
            ntables = ntables + 1

            -- Serialize the table.
            local serialConcat = { }

            -- Array part.
            for i = 1, len do
                if obj[i] == nil then
                    len = i - 1
                    break
                end
                serialConcat[#serialConcat + 1] = serialize(obj[i])
            end
            serialConcat[#serialConcat + 1] = "\0"

            -- Table part.
            for k, v in pairs(obj) do
                if type(k) ~= "number" or ((k > len or k < 1) or mathfloor(k) ~= k) then
                    -- For each pair, serialize both the key and the value.
                    local idx = #serialConcat
                    serialConcat[idx + 1] = serialize(k)
                    serialConcat[idx + 2] = serialize(v)
                end
            end
            serialConcat[#serialConcat + 1] = "\0"

            -- tableconcat is way faster than normal concatenation using .. when dealing with lots of strings.
            -- Add this serialization to the table of serialized tables for quick access and later more concatenation.
            tableSerial[id] = tableconcat(serialConcat)
            return ser
        else
            -- Do serialization on a non-recursive type.
            if t == "number" then
                -- Space optimization can be done for ints, so serialize them differently from doubles.
                -- OSMARKS EDIT: handle sign in type and not actual serialization
                if mathfloor(obj) == obj then
                    local intval = serialization.integer(math.abs(obj))
                    local typespec = "p"
                    if obj < 0 then typespec = "n" end
                    return typespec .. intval
                end
                return "d" .. serialization.double(obj)
            end
            local ser = types[t]
            return obj == nil and ser or ser .. serialization[t](obj)
        end
    end

    -- Either serialize for a table or for a non-recursive type.
    local ser = serialize(obj)
    if type(obj) == "table" then
        return tableconcat({ "t", tableconcat(tableSerial) })
    end
    return ser
end

function deserialize(ser)
    local idx = 1
    local tables = { { } }
    local serref = { ser }

    local function getchar()
        local ret = stringsub(serref[1], idx, idx)
        return ret ~= "" and ret or nil
    end

    local function deserializeValue()
		yield()
        local t = getchar()
        idx = idx + 1
        if t == "t" then
            -- Get table id.
            local width = stringtonumber(getchar())
            idx = idx + 1
            local id = stringtonumber(stringsub(serref[1], idx, idx + width - 1))
            idx = idx + width

            -- Create an empty table as a placeholder.
            if not tables[id] then
                tables[id] = { }
            end

            return tables[id]
        else
            local ret
            ret, idx = deserialization[t](idx, serref)
            return ret
        end
    end

    -- Either deserialize for a table or for a non-recursive type.
    local i = 1
    if getchar() == "t" then
        idx = idx + 1
        while getchar() do
            if not tables[i] then tables[i] = { } end
            local curtbl = tables[i]

            -- Array part.
            while getchar() ~= "\0" do
                curtbl[#curtbl + 1] = deserializeValue()
            end

            -- Table part.
            idx = idx + 1
            while getchar() ~= "\0" do
                curtbl[deserializeValue()] = deserializeValue()
            end

            i = i + 1
            idx = idx + 1
        end
        return tables[1]
    end
    return deserializeValue()
end

return { serialize = serialize, deserialize = deserialize }
local function chars(str)
	local pos = 1
	return function()
		if pos <= #str  then
			local pos_was = pos
			pos = pos + 1
			return str:sub(pos_was, pos_was), pos_was
		end
	end
end

-- from lua users wiki - magic
local function unpackbits(num, width)
	local fl = {}
	local rem
	for i = 1,width do
		num,rem = math.modf(num/2)
		fl[#fl+1] = rem>=0.5
	end
	return fl
end

local function permutation(str, ix)
	local bits = unpackbits(ix, #str)
	local this = ""
	for char, idx in chars(str) do
		local newchar = char:lower()
		if bits[idx] then newchar = char:upper() end
		this = this .. newchar
	end
	return this
end

local function caps_permutations(str)
	local combinations = math.pow(2, #str) - 1
	local ret = {}
	for i = 0, combinations do
		table.insert(ret, permutation(str, i))
	end
	return ret
end

local function nybbles(byte)
	return bit.brshift(bit.band(0xF0, byte), 4), bit.band(0x0F, byte)
end

local function rpt(t, x)
	local out = {}
	for i = 1, x do
		for _, v in pairs(t) do
			table.insert(out, v)
		end
	end
	return out
end

local function invert(t)
	local out = {}
	for k, v in pairs(t) do
		out[v] = k
	end
	return out
end

local function sanify(t)
	local ix = 0
	local out = {}
	for _, v in pairs(t) do
		out[ix] = v
		ix = ix + 1
	end
	return out
end

local dictionary = caps_permutations "lol"
for k, v in pairs({
	" ",
	".",
	"?",
	"!",
	"#",
	",",
	";",
	":"
}) do table.insert(dictionary, v) end
dictionary = sanify(dictionary)
local inverse_dictionary = invert(dictionary)

local function encode(str)
	local out = ""
	for char in chars(str) do
		local hi, lo = nybbles(string.byte(char))
		out = out .. dictionary[hi] .. dictionary[lo]
	end
	return out
end

local function tokenize(str)
	local in_lol = ""
	local toks = {}
	for char, index in chars(str) do
		local lowered = char:lower()
		if in_lol ~= "" then -- if we have a current lol, push lol to the tokens stack and clear it if we get a L
			in_lol = in_lol .. char
			if lowered == "l" then
				table.insert(toks, in_lol)
				in_lol = ""
			elseif lowered == "o" then
			else error "Invalid character in LOL" end
		else
			if lowered == "l" then
				in_lol = char
			else
				table.insert(toks, char)
			end
		end
	end
	return toks
end

local function decode_one(tok)
	local d = inverse_dictionary[tok]
	if not d then error("Invalid token in loltext: " .. tostring(tok)) end
	return d
end

local function decode_pair(t1, t2)
	local hi, lo = decode_one(t1), decode_one(t2)
	local n = bit.bor(bit.blshift(hi, 4), lo)
	return string.char(n)
end

local function decode(str)
	local toks = tokenize(str)
	local out = ""
	while true do
		local t1, t2 = table.remove(toks, 1), table.remove(toks, 1)
		if not t1 or not t2 then
			break
		else
			out = out .. decode_pair(t1, t2)
		end
	end
	return out
end

local function repeat_function(f, times)
	return function(data, times_)
		local times = times_ or times
		local d = data
		for i = 1, times do
			d = f(d)
		end
		return d
	end
end

return { encode = repeat_function(encode, 1), decode = repeat_function(decode, 1) }
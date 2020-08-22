-- Elliptic curve cryptography library. This should probably be minified? Why does it have its own `irequire`?

local preload = _G.package.preload

local irequire = _G.require
if type(irequire) ~= "function" then
	local loading = {}
	local loaded = {}
	irequire = function(name)
		local result = loaded[name]

		if result ~= nil then
			if result == loading then
				error("loop or previous error loading module '" .. name .. "'", 2)
			end

			return result
		end

		loaded[name] = loading
		local contents = preload[name]
		if contents then
			result = contents(name)
		else
			error("cannot load '" .. name .. "'", 2)
		end

		if result == nil then result = true end
		loaded[name] = result
		return result
	end
end
preload["fq"] = function(...)
-- Fq Integer Arithmetic

local bxor = bit32.bxor or bit.bxor
local n = 0xffff
local m = 0x10000

local q = {1372, 62520, 47765, 8105, 45059, 9616, 65535, 65535, 65535, 65535, 65535, 65532}
local qn = {1372, 62520, 47765, 8105, 45059, 9616, 65535, 65535, 65535, 65535, 65535, 65532, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

local mt = {
	__tostring = function(a) return string.char(unpack(a)) end,
	__index = {
		toHex = function(self, s) return ("%02x"):rep(#self):format(unpack(self)) end,
		isEqual = function(self, t)
			if type(t) ~= "table" then return false end
			if #self ~= #t then return false end
			local ret = 0
			for i = 1, #self do
				ret = bit32.bor(ret, bxor(self[i], t[i]))
			end
			return ret == 0
		end
	}
}

local function eq(a, b)
	for i = 1, 12 do
		if a[i] ~= b[i] then
			return false
		end
	end

	return true
end

local function cmp(a, b)
	for i = 12, 1, -1 do
		if a[i] > b[i] then
			return 1
		elseif a[i] < b[i] then
			return -1
		end
	end

	return 0
end

local function cmp384(a, b)
	for i = 24, 1, -1 do
		if a[i] > b[i] then
			return 1
		elseif a[i] < b[i] then
			return -1
		end
	end

	return 0
end

local function bytes(x)
	local result = {}

	for i = 0, 11 do
		local m = x[i + 1] % 256
		result[2 * i + 1] = m
		result[2 * i + 2] = (x[i + 1] - m) / 256
	end

	return setmetatable(result, mt)
end

local function fromBytes(enc)
	local result = {}

	for i = 0, 11 do
		result[i + 1] = enc[2 * i + 1] % 256
		result[i + 1] = result[i + 1] + enc[2 * i + 2] * 256
	end

	return result
end

local function sub192(a, b)
	local r1 = a[1] - b[1]
	local r2 = a[2] - b[2]
	local r3 = a[3] - b[3]
	local r4 = a[4] - b[4]
	local r5 = a[5] - b[5]
	local r6 = a[6] - b[6]
	local r7 = a[7] - b[7]
	local r8 = a[8] - b[8]
	local r9 = a[9] - b[9]
	local r10 = a[10] - b[10]
	local r11 = a[11] - b[11]
	local r12 = a[12] - b[12]

	if r1 < 0 then
		r2 = r2 - 1
		r1 = r1 + m
	end
	if r2 < 0 then
		r3 = r3 - 1
		r2 = r2 + m
	end
	if r3 < 0 then
		r4 = r4 - 1
		r3 = r3 + m
	end
	if r4 < 0 then
		r5 = r5 - 1
		r4 = r4 + m
	end
	if r5 < 0 then
		r6 = r6 - 1
		r5 = r5 + m
	end
	if r6 < 0 then
		r7 = r7 - 1
		r6 = r6 + m
	end
	if r7 < 0 then
		r8 = r8 - 1
		r7 = r7 + m
	end
	if r8 < 0 then
		r9 = r9 - 1
		r8 = r8 + m
	end
	if r9 < 0 then
		r10 = r10 - 1
		r9 = r9 + m
	end
	if r10 < 0 then
		r11 = r11 - 1
		r10 = r10 + m
	end
	if r11 < 0 then
		r12 = r12 - 1
		r11 = r11 + m
	end

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12}

	return result
end

local function reduce(a)
	local result = {unpack(a)}

	if cmp(result, q) >= 0 then
		result = sub192(result, q)
	end

	return result
end

local function add(a, b)
	local r1 = a[1] + b[1]
	local r2 = a[2] + b[2]
	local r3 = a[3] + b[3]
	local r4 = a[4] + b[4]
	local r5 = a[5] + b[5]
	local r6 = a[6] + b[6]
	local r7 = a[7] + b[7]
	local r8 = a[8] + b[8]
	local r9 = a[9] + b[9]
	local r10 = a[10] + b[10]
	local r11 = a[11] + b[11]
	local r12 = a[12] + b[12]

	if r1 > n then
		r2 = r2 + 1
		r1 = r1 - m
	end
	if r2 > n then
		r3 = r3 + 1
		r2 = r2 - m
	end
	if r3 > n then
		r4 = r4 + 1
		r3 = r3 - m
	end
	if r4 > n then
		r5 = r5 + 1
		r4 = r4 - m
	end
	if r5 > n then
		r6 = r6 + 1
		r5 = r5 - m
	end
	if r6 > n then
		r7 = r7 + 1
		r6 = r6 - m
	end
	if r7 > n then
		r8 = r8 + 1
		r7 = r7 - m
	end
	if r8 > n then
		r9 = r9 + 1
		r8 = r8 - m
	end
	if r9 > n then
		r10 = r10 + 1
		r9 = r9 - m
	end
	if r10 > n then
		r11 = r11 + 1
		r10 = r10 - m
	end
	if r11 > n then
		r12 = r12 + 1
		r11 = r11 - m
	end

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12}
	
	return reduce(result)
end

local function sub(a, b)
	local result = sub192(a, b)

	if result[12] < 0 then
		result = add(result, q)
	end
	
	return result
end

local function add384(a, b)
	local r1 = a[1] + b[1]
	local r2 = a[2] + b[2]
	local r3 = a[3] + b[3]
	local r4 = a[4] + b[4]
	local r5 = a[5] + b[5]
	local r6 = a[6] + b[6]
	local r7 = a[7] + b[7]
	local r8 = a[8] + b[8]
	local r9 = a[9] + b[9]
	local r10 = a[10] + b[10]
	local r11 = a[11] + b[11]
	local r12 = a[12] + b[12]
	local r13 = a[13] + b[13]
	local r14 = a[14] + b[14]
	local r15 = a[15] + b[15]
	local r16 = a[16] + b[16]
	local r17 = a[17] + b[17]
	local r18 = a[18] + b[18]
	local r19 = a[19] + b[19]
	local r20 = a[20] + b[20]
	local r21 = a[21] + b[21]
	local r22 = a[22] + b[22]
	local r23 = a[23] + b[23]
	local r24 = a[24] + b[24]

	if r1 > n then
		r2 = r2 + 1
		r1 = r1 - m
	end
	if r2 > n then
		r3 = r3 + 1
		r2 = r2 - m
	end
	if r3 > n then
		r4 = r4 + 1
		r3 = r3 - m
	end
	if r4 > n then
		r5 = r5 + 1
		r4 = r4 - m
	end
	if r5 > n then
		r6 = r6 + 1
		r5 = r5 - m
	end
	if r6 > n then
		r7 = r7 + 1
		r6 = r6 - m
	end
	if r7 > n then
		r8 = r8 + 1
		r7 = r7 - m
	end
	if r8 > n then
		r9 = r9 + 1
		r8 = r8 - m
	end
	if r9 > n then
		r10 = r10 + 1
		r9 = r9 - m
	end
	if r10 > n then
		r11 = r11 + 1
		r10 = r10 - m
	end
	if r11 > n then
		r12 = r12 + 1
		r11 = r11 - m
	end
	if r12 > n then
		r13 = r13 + 1
		r12 = r12 - m
	end
	if r13 > n then
		r14 = r14 + 1
		r13 = r13 - m
	end
	if r14 > n then
		r15 = r15 + 1
		r14 = r14 - m
	end
	if r15 > n then
		r16 = r16 + 1
		r15 = r15 - m
	end
	if r16 > n then
		r17 = r17 + 1
		r16 = r16 - m
	end
	if r17 > n then
		r18 = r18 + 1
		r17 = r17 - m
	end
	if r18 > n then
		r19 = r19 + 1
		r18 = r18 - m
	end
	if r19 > n then
		r20 = r20 + 1
		r19 = r19 - m
	end
	if r20 > n then
		r21 = r21 + 1
		r20 = r20 - m
	end
	if r21 > n then
		r22 = r22 + 1
		r21 = r21 - m
	end
	if r22 > n then
		r23 = r23 + 1
		r22 = r22 - m
	end
	if r23 > n then
		r24 = r24 + 1
		r23 = r23 - m
	end

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24}

	return result
end

local function sub384(a, b)
	local r1 = a[1] - b[1]
	local r2 = a[2] - b[2]
	local r3 = a[3] - b[3]
	local r4 = a[4] - b[4]
	local r5 = a[5] - b[5]
	local r6 = a[6] - b[6]
	local r7 = a[7] - b[7]
	local r8 = a[8] - b[8]
	local r9 = a[9] - b[9]
	local r10 = a[10] - b[10]
	local r11 = a[11] - b[11]
	local r12 = a[12] - b[12]
	local r13 = a[13] - b[13]
	local r14 = a[14] - b[14]
	local r15 = a[15] - b[15]
	local r16 = a[16] - b[16]
	local r17 = a[17] - b[17]
	local r18 = a[18] - b[18]
	local r19 = a[19] - b[19]
	local r20 = a[20] - b[20]
	local r21 = a[21] - b[21]
	local r22 = a[22] - b[22]
	local r23 = a[23] - b[23]
	local r24 = a[24] - b[24]

	if r1 < 0 then
		r2 = r2 - 1
		r1 = r1 + m
	end
	if r2 < 0 then
		r3 = r3 - 1
		r2 = r2 + m
	end
	if r3 < 0 then
		r4 = r4 - 1
		r3 = r3 + m
	end
	if r4 < 0 then
		r5 = r5 - 1
		r4 = r4 + m
	end
	if r5 < 0 then
		r6 = r6 - 1
		r5 = r5 + m
	end
	if r6 < 0 then
		r7 = r7 - 1
		r6 = r6 + m
	end
	if r7 < 0 then
		r8 = r8 - 1
		r7 = r7 + m
	end
	if r8 < 0 then
		r9 = r9 - 1
		r8 = r8 + m
	end
	if r9 < 0 then
		r10 = r10 - 1
		r9 = r9 + m
	end
	if r10 < 0 then
		r11 = r11 - 1
		r10 = r10 + m
	end
	if r11 < 0 then
		r12 = r12 - 1
		r11 = r11 + m
	end
	if r12 < 0 then
		r13 = r13 - 1
		r12 = r12 + m
	end
	if r13 < 0 then
		r14 = r14 - 1
		r13 = r13 + m
	end
	if r14 < 0 then
		r15 = r15 - 1
		r14 = r14 + m
	end
	if r15 < 0 then
		r16 = r16 - 1
		r15 = r15 + m
	end
	if r16 < 0 then
		r17 = r17 - 1
		r16 = r16 + m
	end
	if r17 < 0 then
		r18 = r18 - 1
		r17 = r17 + m
	end
	if r18 < 0 then
		r19 = r19 - 1
		r18 = r18 + m
	end
	if r19 < 0 then
		r20 = r20 - 1
		r19 = r19 + m
	end
	if r20 < 0 then
		r21 = r21 - 1
		r20 = r20 + m
	end
	if r21 < 0 then
		r22 = r22 - 1
		r21 = r21 + m
	end
	if r22 < 0 then
		r23 = r23 - 1
		r22 = r22 + m
	end
	if r23 < 0 then
		r24 = r24 - 1
		r23 = r23 + m
	end

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24}

	return result
end

local function mul384(a, b)
	local a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12 = unpack(a)
	local b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12 = unpack(b)
	
	local r1 = a1 * b1

	local r2 = a1 * b2
	r2 = r2 + a2 * b1

	local r3 = a1 * b3
	r3 = r3 + a2 * b2
	r3 = r3 + a3 * b1

	local r4 = a1 * b4
	r4 = r4 + a2 * b3
	r4 = r4 + a3 * b2
	r4 = r4 + a4 * b1

	local r5 = a1 * b5
	r5 = r5 + a2 * b4
	r5 = r5 + a3 * b3
	r5 = r5 + a4 * b2
	r5 = r5 + a5 * b1

	local r6 = a1 * b6
	r6 = r6 + a2 * b5
	r6 = r6 + a3 * b4
	r6 = r6 + a4 * b3
	r6 = r6 + a5 * b2
	r6 = r6 + a6 * b1

	local r7 = a1 * b7
	r7 = r7 + a2 * b6
	r7 = r7 + a3 * b5
	r7 = r7 + a4 * b4
	r7 = r7 + a5 * b3
	r7 = r7 + a6 * b2
	r7 = r7 + a7 * b1

	local r8 = a1 * b8
	r8 = r8 + a2 * b7
	r8 = r8 + a3 * b6
	r8 = r8 + a4 * b5
	r8 = r8 + a5 * b4
	r8 = r8 + a6 * b3
	r8 = r8 + a7 * b2
	r8 = r8 + a8 * b1

	local r9 = a1 * b9
	r9 = r9 + a2 * b8
	r9 = r9 + a3 * b7
	r9 = r9 + a4 * b6
	r9 = r9 + a5 * b5
	r9 = r9 + a6 * b4
	r9 = r9 + a7 * b3
	r9 = r9 + a8 * b2
	r9 = r9 + a9 * b1

	local r10 = a1 * b10
	r10 = r10 + a2 * b9
	r10 = r10 + a3 * b8
	r10 = r10 + a4 * b7
	r10 = r10 + a5 * b6
	r10 = r10 + a6 * b5
	r10 = r10 + a7 * b4
	r10 = r10 + a8 * b3
	r10 = r10 + a9 * b2
	r10 = r10 + a10 * b1

	local r11 = a1 * b11
	r11 = r11 + a2 * b10
	r11 = r11 + a3 * b9
	r11 = r11 + a4 * b8
	r11 = r11 + a5 * b7
	r11 = r11 + a6 * b6
	r11 = r11 + a7 * b5
	r11 = r11 + a8 * b4
	r11 = r11 + a9 * b3
	r11 = r11 + a10 * b2
	r11 = r11 + a11 * b1

	local r12 = a1 * b12
	r12 = r12 + a2 * b11
	r12 = r12 + a3 * b10
	r12 = r12 + a4 * b9
	r12 = r12 + a5 * b8
	r12 = r12 + a6 * b7
	r12 = r12 + a7 * b6
	r12 = r12 + a8 * b5
	r12 = r12 + a9 * b4
	r12 = r12 + a10 * b3
	r12 = r12 + a11 * b2
	r12 = r12 + a12 * b1

	local r13 = a2 * b12
	r13 = r13 + a3 * b11
	r13 = r13 + a4 * b10
	r13 = r13 + a5 * b9
	r13 = r13 + a6 * b8
	r13 = r13 + a7 * b7
	r13 = r13 + a8 * b6
	r13 = r13 + a9 * b5
	r13 = r13 + a10 * b4
	r13 = r13 + a11 * b3
	r13 = r13 + a12 * b2

	local r14 = a3 * b12
	r14 = r14 + a4 * b11
	r14 = r14 + a5 * b10
	r14 = r14 + a6 * b9
	r14 = r14 + a7 * b8
	r14 = r14 + a8 * b7
	r14 = r14 + a9 * b6
	r14 = r14 + a10 * b5
	r14 = r14 + a11 * b4
	r14 = r14 + a12 * b3

	local r15 = a4 * b12
	r15 = r15 + a5 * b11
	r15 = r15 + a6 * b10
	r15 = r15 + a7 * b9
	r15 = r15 + a8 * b8
	r15 = r15 + a9 * b7
	r15 = r15 + a10 * b6
	r15 = r15 + a11 * b5
	r15 = r15 + a12 * b4

	local r16 = a5 * b12
	r16 = r16 + a6 * b11
	r16 = r16 + a7 * b10
	r16 = r16 + a8 * b9
	r16 = r16 + a9 * b8
	r16 = r16 + a10 * b7
	r16 = r16 + a11 * b6
	r16 = r16 + a12 * b5

	local r17 = a6 * b12
	r17 = r17 + a7 * b11
	r17 = r17 + a8 * b10
	r17 = r17 + a9 * b9
	r17 = r17 + a10 * b8
	r17 = r17 + a11 * b7
	r17 = r17 + a12 * b6

	local r18 = a7 * b12
	r18 = r18 + a8 * b11
	r18 = r18 + a9 * b10
	r18 = r18 + a10 * b9
	r18 = r18 + a11 * b8
	r18 = r18 + a12 * b7

	local r19 = a8 * b12
	r19 = r19 + a9 * b11
	r19 = r19 + a10 * b10
	r19 = r19 + a11 * b9
	r19 = r19 + a12 * b8

	local r20 = a9 * b12
	r20 = r20 + a10 * b11
	r20 = r20 + a11 * b10
	r20 = r20 + a12 * b9

	local r21 = a10 * b12
	r21 = r21 + a11 * b11
	r21 = r21 + a12 * b10

	local r22 = a11 * b12
	r22 = r22 + a12 * b11

	local r23 = a12 * b12

	local r24 = 0

	r2 = r2 + (r1 / m)
	r2 = r2 - r2 % 1
	r1 = r1 % m
	r3 = r3 + (r2 / m)
	r3 = r3 - r3 % 1
	r2 = r2 % m
	r4 = r4 + (r3 / m)
	r4 = r4 - r4 % 1
	r3 = r3 % m
	r5 = r5 + (r4 / m)
	r5 = r5 - r5 % 1
	r4 = r4 % m
	r6 = r6 + (r5 / m)
	r6 = r6 - r6 % 1
	r5 = r5 % m
	r7 = r7 + (r6 / m)
	r7 = r7 - r7 % 1
	r6 = r6 % m
	r8 = r8 + (r7 / m)
	r8 = r8 - r8 % 1
	r7 = r7 % m
	r9 = r9 + (r8 / m)
	r9 = r9 - r9 % 1
	r8 = r8 % m
	r10 = r10 + (r9 / m)
	r10 = r10 - r10 % 1
	r9 = r9 % m
	r11 = r11 + (r10 / m)
	r11 = r11 - r11 % 1
	r10 = r10 % m
	r12 = r12 + (r11 / m)
	r12 = r12 - r12 % 1
	r11 = r11 % m
	r13 = r13 + (r12 / m)
	r13 = r13 - r13 % 1
	r12 = r12 % m
	r14 = r14 + (r13 / m)
	r14 = r14 - r14 % 1
	r13 = r13 % m
	r15 = r15 + (r14 / m)
	r15 = r15 - r15 % 1
	r14 = r14 % m
	r16 = r16 + (r15 / m)
	r16 = r16 - r16 % 1
	r15 = r15 % m
	r17 = r17 + (r16 / m)
	r17 = r17 - r17 % 1
	r16 = r16 % m
	r18 = r18 + (r17 / m)
	r18 = r18 - r18 % 1
	r17 = r17 % m
	r19 = r19 + (r18 / m)
	r19 = r19 - r19 % 1
	r18 = r18 % m
	r20 = r20 + (r19 / m)
	r20 = r20 - r20 % 1
	r19 = r19 % m
	r21 = r21 + (r20 / m)
	r21 = r21 - r21 % 1
	r20 = r20 % m
	r22 = r22 + (r21 / m)
	r22 = r22 - r22 % 1
	r21 = r21 % m
	r23 = r23 + (r22 / m)
	r23 = r23 - r23 % 1
	r22 = r22 % m
	r24 = r24 + (r23 / m)
	r24 = r24 - r24 % 1
	r23 = r23 % m

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24}

	return result
end

local function reduce384(a)
	local result = {unpack(a)}

	while cmp384(result, qn) >= 0 do
		local qn = {unpack(qn)}
		local qn2 = add384(qn, qn)
		while cmp384(result, qn2) > 0 do
			qn = qn2
			qn2 = add384(qn2, qn2)
		end
		result = sub384(result, qn)
	end

	result = {unpack(result, 1, 12)}

	return result
end

local function mul(a, b)
	return reduce384(mul384(a, b))
end

return {
	fromBytes = fromBytes,
	bytes = bytes,
	sub = sub,
	mul = mul,
	eq = eq,
	cmp = cmp,
}
end
preload["fp"] = function(...)
-- Fp Integer Arithmetic

local n = 0xffff
local m = 0x10000

local p = {3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 65533}
local p2 = {21845, 21845, 21845, 21845, 21845, 21845, 21845, 21845, 21845, 21845, 21845, 43690}
local r2 = {44014, 58358, 19452, 6484, 45852, 58974, 63348, 64806, 65292, 65454, 65508, 21512}

local function eq(a, b)
	for i = 1, 12 do
		if a[i] ~= b[i] then
			return false
		end
	end

	return true
end

local function reduce(a)
	local r1 = a[1]
	local r2 = a[2]
	local r3 = a[3]
	local r4 = a[4]
	local r5 = a[5]
	local r6 = a[6]
	local r7 = a[7]
	local r8 = a[8]
	local r9 = a[9]
	local r10 = a[10]
	local r11 = a[11]
	local r12 = a[12]

	if r12 < 65533 or r12 == 65533 and r1 < 3 then
		return {unpack(a)}
	end

	r1 = r1 - 3
	r12 = r12 - 65533

	if r1 < 0 then
		r2 = r2 - 1
		r1 = r1 + m
	end
	if r2 < 0 then
		r3 = r3 - 1
		r2 = r2 + m
	end
	if r3 < 0 then
		r4 = r4 - 1
		r3 = r3 + m
	end
	if r4 < 0 then
		r5 = r5 - 1
		r4 = r4 + m
	end
	if r5 < 0 then
		r6 = r6 - 1
		r5 = r5 + m
	end
	if r6 < 0 then
		r7 = r7 - 1
		r6 = r6 + m
	end
	if r7 < 0 then
		r8 = r8 - 1
		r7 = r7 + m
	end
	if r8 < 0 then
		r9 = r9 - 1
		r8 = r8 + m
	end
	if r9 < 0 then
		r10 = r10 - 1
		r9 = r9 + m
	end
	if r10 < 0 then
		r11 = r11 - 1
		r10 = r10 + m
	end
	if r11 < 0 then
		r12 = r12 - 1
		r11 = r11 + m
	end

	return {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12}
end

local function add(a, b)
	local r1 = a[1] + b[1]
	local r2 = a[2] + b[2]
	local r3 = a[3] + b[3]
	local r4 = a[4] + b[4]
	local r5 = a[5] + b[5]
	local r6 = a[6] + b[6]
	local r7 = a[7] + b[7]
	local r8 = a[8] + b[8]
	local r9 = a[9] + b[9]
	local r10 = a[10] + b[10]
	local r11 = a[11] + b[11]
	local r12 = a[12] + b[12]

	if r1 > n then
		r2 = r2 + 1
		r1 = r1 - m
	end
	if r2 > n then
		r3 = r3 + 1
		r2 = r2 - m
	end
	if r3 > n then
		r4 = r4 + 1
		r3 = r3 - m
	end
	if r4 > n then
		r5 = r5 + 1
		r4 = r4 - m
	end
	if r5 > n then
		r6 = r6 + 1
		r5 = r5 - m
	end
	if r6 > n then
		r7 = r7 + 1
		r6 = r6 - m
	end
	if r7 > n then
		r8 = r8 + 1
		r7 = r7 - m
	end
	if r8 > n then
		r9 = r9 + 1
		r8 = r8 - m
	end
	if r9 > n then
		r10 = r10 + 1
		r9 = r9 - m
	end
	if r10 > n then
		r11 = r11 + 1
		r10 = r10 - m
	end
	if r11 > n then
		r12 = r12 + 1
		r11 = r11 - m
	end

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12}
	
	return reduce(result)
end

local function shr(a)
	local r1 = a[1]
	local r2 = a[2]
	local r3 = a[3]
	local r4 = a[4]
	local r5 = a[5]
	local r6 = a[6]
	local r7 = a[7]
	local r8 = a[8]
	local r9 = a[9]
	local r10 = a[10]
	local r11 = a[11]
	local r12 = a[12]

	r1 = r1 / 2
	r1 = r1 - r1 % 1
	r1 = r1 + (r2 % 2) * 0x8000
	r2 = r2 / 2
	r2 = r2 - r2 % 1
	r2 = r2 + (r3 % 2) * 0x8000
	r3 = r3 / 2
	r3 = r3 - r3 % 1
	r3 = r3 + (r4 % 2) * 0x8000
	r4 = r4 / 2
	r4 = r4 - r4 % 1
	r4 = r4 + (r5 % 2) * 0x8000
	r5 = r5 / 2
	r5 = r5 - r5 % 1
	r5 = r5 + (r6 % 2) * 0x8000
	r6 = r6 / 2
	r6 = r6 - r6 % 1
	r6 = r6 + (r7 % 2) * 0x8000
	r7 = r7 / 2
	r7 = r7 - r7 % 1
	r7 = r7 + (r8 % 2) * 0x8000
	r8 = r8 / 2
	r8 = r8 - r8 % 1
	r8 = r8 + (r9 % 2) * 0x8000
	r9 = r9 / 2
	r9 = r9 - r9 % 1
	r9 = r9 + (r10 % 2) * 0x8000
	r10 = r10 / 2
	r10 = r10 - r10 % 1
	r10 = r10 + (r11 % 2) * 0x8000
	r11 = r11 / 2
	r11 = r11 - r11 % 1
	r11 = r11 + (r12 % 2) * 0x8000
	r12 = r12 / 2
	r12 = r12 - r12 % 1

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12}

	return result
end

local function sub192(a, b)
	local r1 = a[1] - b[1]
	local r2 = a[2] - b[2]
	local r3 = a[3] - b[3]
	local r4 = a[4] - b[4]
	local r5 = a[5] - b[5]
	local r6 = a[6] - b[6]
	local r7 = a[7] - b[7]
	local r8 = a[8] - b[8]
	local r9 = a[9] - b[9]
	local r10 = a[10] - b[10]
	local r11 = a[11] - b[11]
	local r12 = a[12] - b[12]

	if r1 < 0 then
		r2 = r2 - 1
		r1 = r1 + m
	end
	if r2 < 0 then
		r3 = r3 - 1
		r2 = r2 + m
	end
	if r3 < 0 then
		r4 = r4 - 1
		r3 = r3 + m
	end
	if r4 < 0 then
		r5 = r5 - 1
		r4 = r4 + m
	end
	if r5 < 0 then
		r6 = r6 - 1
		r5 = r5 + m
	end
	if r6 < 0 then
		r7 = r7 - 1
		r6 = r6 + m
	end
	if r7 < 0 then
		r8 = r8 - 1
		r7 = r7 + m
	end
	if r8 < 0 then
		r9 = r9 - 1
		r8 = r8 + m
	end
	if r9 < 0 then
		r10 = r10 - 1
		r9 = r9 + m
	end
	if r10 < 0 then
		r11 = r11 - 1
		r10 = r10 + m
	end
	if r11 < 0 then
		r12 = r12 - 1
		r11 = r11 + m
	end

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12}
	
	return result
end

local function sub(a, b)
	local r1 = a[1] - b[1]
	local r2 = a[2] - b[2]
	local r3 = a[3] - b[3]
	local r4 = a[4] - b[4]
	local r5 = a[5] - b[5]
	local r6 = a[6] - b[6]
	local r7 = a[7] - b[7]
	local r8 = a[8] - b[8]
	local r9 = a[9] - b[9]
	local r10 = a[10] - b[10]
	local r11 = a[11] - b[11]
	local r12 = a[12] - b[12]

	if r1 < 0 then
		r2 = r2 - 1
		r1 = r1 + m
	end
	if r2 < 0 then
		r3 = r3 - 1
		r2 = r2 + m
	end
	if r3 < 0 then
		r4 = r4 - 1
		r3 = r3 + m
	end
	if r4 < 0 then
		r5 = r5 - 1
		r4 = r4 + m
	end
	if r5 < 0 then
		r6 = r6 - 1
		r5 = r5 + m
	end
	if r6 < 0 then
		r7 = r7 - 1
		r6 = r6 + m
	end
	if r7 < 0 then
		r8 = r8 - 1
		r7 = r7 + m
	end
	if r8 < 0 then
		r9 = r9 - 1
		r8 = r8 + m
	end
	if r9 < 0 then
		r10 = r10 - 1
		r9 = r9 + m
	end
	if r10 < 0 then
		r11 = r11 - 1
		r10 = r10 + m
	end
	if r11 < 0 then
		r12 = r12 - 1
		r11 = r11 + m
	end

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12}

	if r12 < 0 then
		result = add(result, p)
	end
	
	return result
end

local function add384(a, b)
	local r1 = a[1] + b[1]
	local r2 = a[2] + b[2]
	local r3 = a[3] + b[3]
	local r4 = a[4] + b[4]
	local r5 = a[5] + b[5]
	local r6 = a[6] + b[6]
	local r7 = a[7] + b[7]
	local r8 = a[8] + b[8]
	local r9 = a[9] + b[9]
	local r10 = a[10] + b[10]
	local r11 = a[11] + b[11]
	local r12 = a[12] + b[12]
	local r13 = a[13] + b[13]
	local r14 = a[14] + b[14]
	local r15 = a[15] + b[15]
	local r16 = a[16] + b[16]
	local r17 = a[17] + b[17]
	local r18 = a[18] + b[18]
	local r19 = a[19] + b[19]
	local r20 = a[20] + b[20]
	local r21 = a[21] + b[21]
	local r22 = a[22] + b[22]
	local r23 = a[23] + b[23]
	local r24 = a[24] + b[24]

	if r1 > n then
		r2 = r2 + 1
		r1 = r1 - m
	end
	if r2 > n then
		r3 = r3 + 1
		r2 = r2 - m
	end
	if r3 > n then
		r4 = r4 + 1
		r3 = r3 - m
	end
	if r4 > n then
		r5 = r5 + 1
		r4 = r4 - m
	end
	if r5 > n then
		r6 = r6 + 1
		r5 = r5 - m
	end
	if r6 > n then
		r7 = r7 + 1
		r6 = r6 - m
	end
	if r7 > n then
		r8 = r8 + 1
		r7 = r7 - m
	end
	if r8 > n then
		r9 = r9 + 1
		r8 = r8 - m
	end
	if r9 > n then
		r10 = r10 + 1
		r9 = r9 - m
	end
	if r10 > n then
		r11 = r11 + 1
		r10 = r10 - m
	end
	if r11 > n then
		r12 = r12 + 1
		r11 = r11 - m
	end
	if r12 > n then
		r13 = r13 + 1
		r12 = r12 - m
	end
	if r13 > n then
		r14 = r14 + 1
		r13 = r13 - m
	end
	if r14 > n then
		r15 = r15 + 1
		r14 = r14 - m
	end
	if r15 > n then
		r16 = r16 + 1
		r15 = r15 - m
	end
	if r16 > n then
		r17 = r17 + 1
		r16 = r16 - m
	end
	if r17 > n then
		r18 = r18 + 1
		r17 = r17 - m
	end
	if r18 > n then
		r19 = r19 + 1
		r18 = r18 - m
	end
	if r19 > n then
		r20 = r20 + 1
		r19 = r19 - m
	end
	if r20 > n then
		r21 = r21 + 1
		r20 = r20 - m
	end
	if r21 > n then
		r22 = r22 + 1
		r21 = r21 - m
	end
	if r22 > n then
		r23 = r23 + 1
		r22 = r22 - m
	end
	if r23 > n then
		r24 = r24 + 1
		r23 = r23 - m
	end

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24}

	return result
end

local function mul384(a, b)
	local a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12 = unpack(a)
	local b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12 = unpack(b)
	
	local r1 = a1 * b1

	local r2 = a1 * b2
	r2 = r2 + a2 * b1

	local r3 = a1 * b3
	r3 = r3 + a2 * b2
	r3 = r3 + a3 * b1

	local r4 = a1 * b4
	r4 = r4 + a2 * b3
	r4 = r4 + a3 * b2
	r4 = r4 + a4 * b1

	local r5 = a1 * b5
	r5 = r5 + a2 * b4
	r5 = r5 + a3 * b3
	r5 = r5 + a4 * b2
	r5 = r5 + a5 * b1

	local r6 = a1 * b6
	r6 = r6 + a2 * b5
	r6 = r6 + a3 * b4
	r6 = r6 + a4 * b3
	r6 = r6 + a5 * b2
	r6 = r6 + a6 * b1

	local r7 = a1 * b7
	r7 = r7 + a2 * b6
	r7 = r7 + a3 * b5
	r7 = r7 + a4 * b4
	r7 = r7 + a5 * b3
	r7 = r7 + a6 * b2
	r7 = r7 + a7 * b1

	local r8 = a1 * b8
	r8 = r8 + a2 * b7
	r8 = r8 + a3 * b6
	r8 = r8 + a4 * b5
	r8 = r8 + a5 * b4
	r8 = r8 + a6 * b3
	r8 = r8 + a7 * b2
	r8 = r8 + a8 * b1

	local r9 = a1 * b9
	r9 = r9 + a2 * b8
	r9 = r9 + a3 * b7
	r9 = r9 + a4 * b6
	r9 = r9 + a5 * b5
	r9 = r9 + a6 * b4
	r9 = r9 + a7 * b3
	r9 = r9 + a8 * b2
	r9 = r9 + a9 * b1

	local r10 = a1 * b10
	r10 = r10 + a2 * b9
	r10 = r10 + a3 * b8
	r10 = r10 + a4 * b7
	r10 = r10 + a5 * b6
	r10 = r10 + a6 * b5
	r10 = r10 + a7 * b4
	r10 = r10 + a8 * b3
	r10 = r10 + a9 * b2
	r10 = r10 + a10 * b1

	local r11 = a1 * b11
	r11 = r11 + a2 * b10
	r11 = r11 + a3 * b9
	r11 = r11 + a4 * b8
	r11 = r11 + a5 * b7
	r11 = r11 + a6 * b6
	r11 = r11 + a7 * b5
	r11 = r11 + a8 * b4
	r11 = r11 + a9 * b3
	r11 = r11 + a10 * b2
	r11 = r11 + a11 * b1

	local r12 = a1 * b12
	r12 = r12 + a2 * b11
	r12 = r12 + a3 * b10
	r12 = r12 + a4 * b9
	r12 = r12 + a5 * b8
	r12 = r12 + a6 * b7
	r12 = r12 + a7 * b6
	r12 = r12 + a8 * b5
	r12 = r12 + a9 * b4
	r12 = r12 + a10 * b3
	r12 = r12 + a11 * b2
	r12 = r12 + a12 * b1

	local r13 = a2 * b12
	r13 = r13 + a3 * b11
	r13 = r13 + a4 * b10
	r13 = r13 + a5 * b9
	r13 = r13 + a6 * b8
	r13 = r13 + a7 * b7
	r13 = r13 + a8 * b6
	r13 = r13 + a9 * b5
	r13 = r13 + a10 * b4
	r13 = r13 + a11 * b3
	r13 = r13 + a12 * b2

	local r14 = a3 * b12
	r14 = r14 + a4 * b11
	r14 = r14 + a5 * b10
	r14 = r14 + a6 * b9
	r14 = r14 + a7 * b8
	r14 = r14 + a8 * b7
	r14 = r14 + a9 * b6
	r14 = r14 + a10 * b5
	r14 = r14 + a11 * b4
	r14 = r14 + a12 * b3

	local r15 = a4 * b12
	r15 = r15 + a5 * b11
	r15 = r15 + a6 * b10
	r15 = r15 + a7 * b9
	r15 = r15 + a8 * b8
	r15 = r15 + a9 * b7
	r15 = r15 + a10 * b6
	r15 = r15 + a11 * b5
	r15 = r15 + a12 * b4

	local r16 = a5 * b12
	r16 = r16 + a6 * b11
	r16 = r16 + a7 * b10
	r16 = r16 + a8 * b9
	r16 = r16 + a9 * b8
	r16 = r16 + a10 * b7
	r16 = r16 + a11 * b6
	r16 = r16 + a12 * b5

	local r17 = a6 * b12
	r17 = r17 + a7 * b11
	r17 = r17 + a8 * b10
	r17 = r17 + a9 * b9
	r17 = r17 + a10 * b8
	r17 = r17 + a11 * b7
	r17 = r17 + a12 * b6

	local r18 = a7 * b12
	r18 = r18 + a8 * b11
	r18 = r18 + a9 * b10
	r18 = r18 + a10 * b9
	r18 = r18 + a11 * b8
	r18 = r18 + a12 * b7

	local r19 = a8 * b12
	r19 = r19 + a9 * b11
	r19 = r19 + a10 * b10
	r19 = r19 + a11 * b9
	r19 = r19 + a12 * b8

	local r20 = a9 * b12
	r20 = r20 + a10 * b11
	r20 = r20 + a11 * b10
	r20 = r20 + a12 * b9

	local r21 = a10 * b12
	r21 = r21 + a11 * b11
	r21 = r21 + a12 * b10

	local r22 = a11 * b12
	r22 = r22 + a12 * b11

	local r23 = a12 * b12

	local r24 = 0

	r2 = r2 + (r1 / m)
	r2 = r2 - r2 % 1
	r1 = r1 % m
	r3 = r3 + (r2 / m)
	r3 = r3 - r3 % 1
	r2 = r2 % m
	r4 = r4 + (r3 / m)
	r4 = r4 - r4 % 1
	r3 = r3 % m
	r5 = r5 + (r4 / m)
	r5 = r5 - r5 % 1
	r4 = r4 % m
	r6 = r6 + (r5 / m)
	r6 = r6 - r6 % 1
	r5 = r5 % m
	r7 = r7 + (r6 / m)
	r7 = r7 - r7 % 1
	r6 = r6 % m
	r8 = r8 + (r7 / m)
	r8 = r8 - r8 % 1
	r7 = r7 % m
	r9 = r9 + (r8 / m)
	r9 = r9 - r9 % 1
	r8 = r8 % m
	r10 = r10 + (r9 / m)
	r10 = r10 - r10 % 1
	r9 = r9 % m
	r11 = r11 + (r10 / m)
	r11 = r11 - r11 % 1
	r10 = r10 % m
	r12 = r12 + (r11 / m)
	r12 = r12 - r12 % 1
	r11 = r11 % m
	r13 = r13 + (r12 / m)
	r13 = r13 - r13 % 1
	r12 = r12 % m
	r14 = r14 + (r13 / m)
	r14 = r14 - r14 % 1
	r13 = r13 % m
	r15 = r15 + (r14 / m)
	r15 = r15 - r15 % 1
	r14 = r14 % m
	r16 = r16 + (r15 / m)
	r16 = r16 - r16 % 1
	r15 = r15 % m
	r17 = r17 + (r16 / m)
	r17 = r17 - r17 % 1
	r16 = r16 % m
	r18 = r18 + (r17 / m)
	r18 = r18 - r18 % 1
	r17 = r17 % m
	r19 = r19 + (r18 / m)
	r19 = r19 - r19 % 1
	r18 = r18 % m
	r20 = r20 + (r19 / m)
	r20 = r20 - r20 % 1
	r19 = r19 % m
	r21 = r21 + (r20 / m)
	r21 = r21 - r21 % 1
	r20 = r20 % m
	r22 = r22 + (r21 / m)
	r22 = r22 - r22 % 1
	r21 = r21 % m
	r23 = r23 + (r22 / m)
	r23 = r23 - r23 % 1
	r22 = r22 % m
	r24 = r24 + (r23 / m)
	r24 = r24 - r24 % 1
	r23 = r23 % m

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24}

	return result
end

local function REDC(T)
	local m = {unpack(mul384({unpack(T, 1, 12)}, p2), 1, 12)}
	local t = {unpack(add384(T, mul384(m, p)), 13, 24)}

	return reduce(t)
end

local function mul(a, b)
	return REDC(mul384(a, b))
end

local function sqr(a)
	local a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12 = unpack(a)
	
	local r1 = a1 * a1

	local r2 = a1 * a2 * 2

	local r3 = a1 * a3 * 2
	r3 = r3 + a2 * a2

	local r4 = a1 * a4 * 2
	r4 = r4 + a2 * a3 * 2

	local r5 = a1 * a5 * 2
	r5 = r5 + a2 * a4 * 2
	r5 = r5 + a3 * a3

	local r6 = a1 * a6 * 2
	r6 = r6 + a2 * a5 * 2
	r6 = r6 + a3 * a4 * 2

	local r7 = a1 * a7 * 2
	r7 = r7 + a2 * a6 * 2
	r7 = r7 + a3 * a5 * 2
	r7 = r7 + a4 * a4

	local r8 = a1 * a8 * 2
	r8 = r8 + a2 * a7 * 2
	r8 = r8 + a3 * a6 * 2
	r8 = r8 + a4 * a5 * 2

	local r9 = a1 * a9 * 2
	r9 = r9 + a2 * a8 * 2
	r9 = r9 + a3 * a7 * 2
	r9 = r9 + a4 * a6 * 2
	r9 = r9 + a5 * a5

	local r10 = a1 * a10 * 2
	r10 = r10 + a2 * a9 * 2
	r10 = r10 + a3 * a8 * 2
	r10 = r10 + a4 * a7 * 2
	r10 = r10 + a5 * a6 * 2

	local r11 = a1 * a11 * 2
	r11 = r11 + a2 * a10 * 2
	r11 = r11 + a3 * a9 * 2
	r11 = r11 + a4 * a8 * 2
	r11 = r11 + a5 * a7 * 2
	r11 = r11 + a6 * a6

	local r12 = a1 * a12 * 2
	r12 = r12 + a2 * a11 * 2
	r12 = r12 + a3 * a10 * 2
	r12 = r12 + a4 * a9 * 2
	r12 = r12 + a5 * a8 * 2
	r12 = r12 + a6 * a7 * 2

	local r13 = a2 * a12 * 2
	r13 = r13 + a3 * a11 * 2
	r13 = r13 + a4 * a10 * 2
	r13 = r13 + a5 * a9 * 2
	r13 = r13 + a6 * a8 * 2
	r13 = r13 + a7 * a7

	local r14 = a3 * a12 * 2
	r14 = r14 + a4 * a11 * 2
	r14 = r14 + a5 * a10 * 2
	r14 = r14 + a6 * a9 * 2
	r14 = r14 + a7 * a8 * 2

	local r15 = a4 * a12 * 2
	r15 = r15 + a5 * a11 * 2
	r15 = r15 + a6 * a10 * 2
	r15 = r15 + a7 * a9 * 2
	r15 = r15 + a8 * a8

	local r16 = a5 * a12 * 2
	r16 = r16 + a6 * a11 * 2
	r16 = r16 + a7 * a10 * 2
	r16 = r16 + a8 * a9 * 2

	local r17 = a6 * a12 * 2
	r17 = r17 + a7 * a11 * 2
	r17 = r17 + a8 * a10 * 2
	r17 = r17 + a9 * a9

	local r18 = a7 * a12 * 2
	r18 = r18 + a8 * a11 * 2
	r18 = r18 + a9 * a10 * 2

	local r19 = a8 * a12 * 2
	r19 = r19 + a9 * a11 * 2
	r19 = r19 + a10 * a10

	local r20 = a9 * a12 * 2
	r20 = r20 + a10 * a11 * 2

	local r21 = a10 * a12 * 2
	r21 = r21 + a11 * a11

	local r22 = a11 * a12 * 2

	local r23 = a12 * a12

	local r24 = 0

	r2 = r2 + (r1 / m)
	r2 = r2 - r2 % 1
	r1 = r1 % m
	r3 = r3 + (r2 / m)
	r3 = r3 - r3 % 1
	r2 = r2 % m
	r4 = r4 + (r3 / m)
	r4 = r4 - r4 % 1
	r3 = r3 % m
	r5 = r5 + (r4 / m)
	r5 = r5 - r5 % 1
	r4 = r4 % m
	r6 = r6 + (r5 / m)
	r6 = r6 - r6 % 1
	r5 = r5 % m
	r7 = r7 + (r6 / m)
	r7 = r7 - r7 % 1
	r6 = r6 % m
	r8 = r8 + (r7 / m)
	r8 = r8 - r8 % 1
	r7 = r7 % m
	r9 = r9 + (r8 / m)
	r9 = r9 - r9 % 1
	r8 = r8 % m
	r10 = r10 + (r9 / m)
	r10 = r10 - r10 % 1
	r9 = r9 % m
	r11 = r11 + (r10 / m)
	r11 = r11 - r11 % 1
	r10 = r10 % m
	r12 = r12 + (r11 / m)
	r12 = r12 - r12 % 1
	r11 = r11 % m
	r13 = r13 + (r12 / m)
	r13 = r13 - r13 % 1
	r12 = r12 % m
	r14 = r14 + (r13 / m)
	r14 = r14 - r14 % 1
	r13 = r13 % m
	r15 = r15 + (r14 / m)
	r15 = r15 - r15 % 1
	r14 = r14 % m
	r16 = r16 + (r15 / m)
	r16 = r16 - r16 % 1
	r15 = r15 % m
	r17 = r17 + (r16 / m)
	r17 = r17 - r17 % 1
	r16 = r16 % m
	r18 = r18 + (r17 / m)
	r18 = r18 - r18 % 1
	r17 = r17 % m
	r19 = r19 + (r18 / m)
	r19 = r19 - r19 % 1
	r18 = r18 % m
	r20 = r20 + (r19 / m)
	r20 = r20 - r20 % 1
	r19 = r19 % m
	r21 = r21 + (r20 / m)
	r21 = r21 - r21 % 1
	r20 = r20 % m
	r22 = r22 + (r21 / m)
	r22 = r22 - r22 % 1
	r21 = r21 % m
	r23 = r23 + (r22 / m)
	r23 = r23 - r23 % 1
	r22 = r22 % m
	r24 = r24 + (r23 / m)
	r24 = r24 - r24 % 1
	r23 = r23 % m

	local result = {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24}

	return REDC(result)
end

local function mont(a)
	return mul(a, r2)
end

local function invMont(a)
	local a = {unpack(a)}

	for i = 13, 24 do
		a[i] = 0
	end

	return REDC(a)
end

return {
	eq = eq,
	mul = mul,
	sqr = sqr,
	add = add,
	sub = sub,
	shr = shr,
	mont = mont,
	invMont = invMont,
	sub192 = sub192
}
end
preload["empty"] = function(...)

end
preload["elliptic"] = function(...)
---- Elliptic Curve Arithmetic

---- About the Curve Itself
-- Field Size: 192 bits
-- Field Modulus (p): 65533 * 2^176 + 3
-- Equation: x^2 + y^2 = 1 + 108 * x^2 * y^2
-- Parameters: Edwards Curve with c = 1, and d = 108
-- Curve Order (n): 4 * 1569203598118192102418711808268118358122924911136798015831
-- Cofactor (h): 4
-- Generator Order (q): 1569203598118192102418711808268118358122924911136798015831
---- About the Curve's Security
-- Current best attack security: 94.822 bits (Pollard's Rho)
-- Rho Security: log2(0.884 * sqrt(q)) = 94.822
-- Transfer Security? Yes: p ~= q; k > 20
-- Field Discriminant Security? Yes: t = 67602300638727286331433024168; s = 2^2; |D| = 5134296629560551493299993292204775496868940529592107064435 > 2^100
-- Rigidity? A little, the parameters are somewhat small.
-- XZ/YZ Ladder Security? No: Single coordinate ladders are insecure, so they can't be used.
-- Small Subgroup Security? Yes: Secret keys are calculated modulo 4q.
-- Invalid Curve Security? Yes: Any point to be multiplied is checked beforehand.
-- Invalid Curve Twist Security? No: The curve is not protected against single coordinate ladder attacks, so don't use them.
-- Completeness? Yes: The curve is an Edwards Curve with non-square d and square a, so the curve is complete.
-- Indistinguishability? No: The curve does not support indistinguishability maps.

fp = irequire("fp")

local eq = fp.eq
local mul = fp.mul
local sqr = fp.sqr
local add = fp.add
local sub = fp.sub
local shr = fp.shr
local mont = fp.mont
local invMont = fp.invMont
local sub192 = fp.sub192

local bits = 192
local pMinusTwoBinary = {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}
local pMinusThreeOverFourBinary = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0}
local ZERO = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local ONE = mont({1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})

local p = mont({3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 65533})
local G = {
	mont({30457, 58187, 5603, 63215, 8936, 58151, 26571, 7272, 26680, 23486, 32353, 59456}),
	mont({3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}),
	mont({1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
}
local GTable = {G}

local d = mont({108, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})

local bxor = bit32.bxor or bit.bxor
local mt = {
	__tostring = function(a) return string.char(unpack(a)) end,
	__index = {
		toHex = function(self, s) return ("%02x"):rep(#self):format(unpack(self)) end,
		isEqual = function(self, t)
			if type(t) ~= "table" then return false end
			if #self ~= #t then return false end
			local ret = 0
			for i = 1, #self do
				ret = bit32.bor(ret, bxor(self[i], t[i]))
			end
			return ret == 0
		end
	}
}

local function expMod(a, t)
	local a = {unpack(a)}
	local result = {unpack(ONE)}

	for i = 1, bits do
		if t[i] == 1 then
			result = mul(result, a)
		end
		a = mul(a, a)
	end	

	return result
end

-- We're using Projective Coordinates
-- For Edwards curves
-- The identity element is represented by (0:1:1)
local function pointDouble(P1)
	local X1, Y1, Z1 = unpack(P1)

	local b = add(X1, Y1)
	local B = sqr(b)
	local C = sqr(X1)
	local D = sqr(Y1)
	local E = add(C, D)
	local H = sqr(Z1)
	local J = sub(E, add(H, H))
	local X3 = mul(sub(B, E), J)
	local Y3 = mul(E, sub(C, D))
	local Z3 = mul(E, J)

	local P3 = {X3, Y3, Z3}

	return P3
end

local function pointAdd(P1, P2)
	local X1, Y1, Z1 = unpack(P1)
	local X2, Y2, Z2 = unpack(P2)

	local A = mul(Z1, Z2)
	local B = sqr(A)
	local C = mul(X1, X2)
	local D = mul(Y1, Y2)
	local E = mul(d, mul(C, D))
	local F = sub(B, E)
	local G = add(B, E)
	local X3 = mul(A, mul(F, sub(mul(add(X1, Y1), add(X2, Y2)), add(C, D))))
	local Y3 = mul(A, mul(G, sub(D, C)))
	local Z3 = mul(F, G)

	local P3 = {X3, Y3, Z3}

	return P3
end

local function pointNeg(P1)
	local X1, Y1, Z1 = unpack(P1)

	local X3 = sub(p, X1)
	local Y3 = {unpack(Y1)}
	local Z3 = {unpack(Z1)}

	local P3 = {X3, Y3, Z3}

	return P3
end

local function pointSub(P1, P2)
	return pointAdd(P1, pointNeg(P2))
end

local function pointScale(P1)
	local X1, Y1, Z1 = unpack(P1)

	local A = expMod(Z1, pMinusTwoBinary)
	local X3 = mul(X1, A)
	local Y3 = mul(Y1, A)
	local Z3 = {unpack(ONE)}

	local P3 = {X3, Y3, Z3}

	return P3
end

local function pointEq(P1, P2)
	local X1, Y1, Z1 = unpack(P1)
	local X2, Y2, Z2 = unpack(P2)

	local A1 = mul(X1, Z2)
	local B1 = mul(Y1, Z2)
	local A2 = mul(X2, Z1)
	local B2 = mul(Y2, Z1)

	return eq(A1, A2) and eq(B1, B2)
end

local function pointIsOnCurve(P1)
	local X1, Y1, Z1 = unpack(P1)

	local X12 = sqr(X1)
	local Y12 = sqr(Y1)
	local Z12 = sqr(Z1)
	local Z14 = sqr(Z12)
	local a = add(X12, Y12)
	a = mul(a, Z12)
	local b = mul(d, mul(X12, Y12))
	b = add(Z14, b)

	return eq(a, b)
end

local function mods(d)
	-- w = 5
	local result = d[1] % 32

	if result >= 16 then
		result = result - 32
	end

	return result
end

local function NAF(d)
	local t = {}
	local d = {unpack(d)}

	while d[12] >= 0 and not eq(d, ZERO) do
		if d[1] % 2 == 1 then
			t[#t + 1] = mods(d)
			d = sub192(d, {t[#t], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
		else
			t[#t + 1] = 0
		end

		d = shr(d)
	end

	return t
end

local function scalarMul(s, P1)
	local naf = NAF(s)
	local PTable = {P1}
	local P2 = pointDouble(P1)

	for i = 3, 31, 2 do
		PTable[i] = pointAdd(PTable[i - 2], P2)
	end

	local Q = {{unpack(ZERO)}, {unpack(ONE)}, {unpack(ONE)}}
	for i = #naf, 1, -1 do
		Q = pointDouble(Q)
		if naf[i] > 0 then
			Q = pointAdd(Q, PTable[naf[i]])
		elseif naf[i] < 0 then
			Q = pointSub(Q, PTable[-naf[i]])
		end
	end

	return Q
end

for i = 2, 196 do
	GTable[i] = pointDouble(GTable[i - 1])
end

local function scalarMulG(s)
	local result = {{unpack(ZERO)}, {unpack(ONE)}, {unpack(ONE)}}
	local k = 1

	for i = 1, 12 do
		local w = s[i]

		for j = 1, 16 do
			if w % 2 == 1 then
				result = pointAdd(result, GTable[k])
			end

			k = k + 1

			w = w / 2
			w = w - w % 1
		end
	end

	return result
end

local function pointEncode(P1)
	P1 = pointScale(P1)

	local result = {}
	local x, y = unpack(P1)

	result[1] = x[1] % 2

	for i = 1, 12 do
		local m = y[i] % 256
		result[2 * i] = m
		result[2 * i + 1] = (y[i] - m) / 256
	end

	return setmetatable(result, mt)
end

local function pointDecode(enc)
	local y = {}
	for i = 1, 12 do
		y[i] = enc[2 * i]
		y[i] = y[i] + enc[2 * i + 1] * 256
	end

	local y2 = sqr(y)
	local u = sub(y2, ONE)
	local v = sub(mul(d, y2), ONE)
	local u2 = sqr(u)
	local u3 = mul(u, u2)
	local u5 = mul(u3, u2)
	local v3 = mul(v, sqr(v))
	local w = mul(u5, v3)
	local x = mul(u3, mul(v, expMod(w, pMinusThreeOverFourBinary)))

	if x[1] % 2 ~= enc[1] then
		x = sub(p, x)
	end

	local P3 = {x, y, {unpack(ONE)}}

	return P3
end

return {
	G = G,
	pointAdd = pointAdd,
	pointNeg = pointNeg,
	pointSub = pointSub,
	pointEq = pointEq,
	pointIsOnCurve = pointIsOnCurve,
	scalarMul = scalarMul,
	scalarMulG = scalarMulG,
	pointEncode = pointEncode,
	pointDecode = pointDecode
}
end
preload["ecc"] = function(...)
local fq = irequire("fq")
local elliptic = irequire("elliptic")
local sha256 = require("sha256")
require("urandom")

local q = {1372, 62520, 47765, 8105, 45059, 9616, 65535, 65535, 65535, 65535, 65535, 65532}

local sLen = 24
local eLen = 24

local function hashModQ(sk)
	local hash = sha256.hmac({0x00}, sk)
	local x
	repeat
		hash = sha256.digest(hash)
		x = fq.fromBytes(hash)
	until fq.cmp(x, q) <= 0

	return x
end

local function publicKey(sk)
	local x = hashModQ(sk)

	local Y = elliptic.scalarMulG(x)
	local pk = elliptic.pointEncode(Y)

	return pk
end

local function keypair()
	local priv = os.urandom()
	local pub = publicKey(priv)
	return pub, priv
end

local function exchange(sk, pk)
	local Y = elliptic.pointDecode(pk)
	local x = hashModQ(sk)

	local Z = elliptic.scalarMul(x, Y)
	Z = elliptic.pointScale(Z)

	local ss = fq.bytes(Z[2])
	local ss = sha256.digest(ss)

	return ss
end

local function sign(sk, message)
	message = type(message) == "table" and string.char(unpack(message)) or message
	sk = type(sk) == "table" and string.char(unpack(sk)) or sk
	local epoch = tostring(os.epoch("utc"))
	local x = hashModQ(sk)
	local k = hashModQ(message .. epoch .. sk)
	
	local R = elliptic.scalarMulG(k)
	R = string.char(unpack(elliptic.pointEncode(R)))
	local e = hashModQ(R .. message)
	local s = fq.sub(k, fq.mul(x, e))

	e = fq.bytes(e)
	s = fq.bytes(s)

	local sig = e

	for i = 1, #s do
		sig[#sig + 1] = s[i]
	end

	return sig
end

local function verify(pk, message, sig)
	local Y = elliptic.pointDecode(pk)
	local e = {unpack(sig, 1, eLen)}
	local s = {unpack(sig, eLen + 1, eLen + sLen)}

	e = fq.fromBytes(e)
	s = fq.fromBytes(s)

	local R = elliptic.pointAdd(elliptic.scalarMulG(s), elliptic.scalarMul(e, Y))
	R = string.char(unpack(elliptic.pointEncode(R)))
	local e2 = hashModQ(R .. message)

	return fq.eq(e2, e)
end

return {
	publicKey = publicKey,
	exchange = exchange,
	sign = sign,
	verify = verify,
	keypair = keypair
}
end
return irequire
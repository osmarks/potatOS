local function gen_vers()
    return ("%d.%d.%d"):format(math.random(0, 4), math.random(0, 20), math.random(0, 8))
end
local vers = potatOS.registry.get "potatOS.factor_version"
if not vers then
    vers = gen_vers()
    potatOS.registry.set("potatOS.factor_version", vers)
end
print(fs.getName(shell.getRunningProgram()) - "%.lua$", "v" .. vers)
local x
repeat
    write "Provide an integer to factorize: "
    x = tonumber(read())
    if not x or math.floor(x) ~= x then print("That is NOT an integer.") end
until x

if x > (2^40) then print("WARNING: Number is quite big. Due to Lua floating point limitations, draconic entities MAY be present. If this runs for several seconds, it's probably frozen due to this.") end

local floor, abs, random, log, pow = math.floor, math.abs, math.random, math.log, math.pow

local function gcd(x, y)
    local r = x % y
    if r == 0 then return y end
    return gcd(y, r)
end

local function eps_compare(x, y)
    return abs(x - y) < 1e-14
end

local function modexp(a, b, n)
    if b == 0 then return 1 % n end
    if b == 1 then return a % n end
    local bdiv2 = b / 2
    local fbdiv2 = floor(bdiv2)
    if eps_compare(bdiv2, fbdiv2) then
        -- b is even, so it is possible to just modexp with HALF the exponent and square it (mod n)
        local x = modexp(a, fbdiv2, n)
        return (x * x) % n
    else
        -- not even, so subtract 1 (this is even), modexp that, and multiply by a again (mod n)
        return (modexp(a, b - 1, n) * a) % n
    end
end

local bases = {2, 3, 5, 7, 11, 13, 17, 19}
local primes = {}
for _, k in pairs(bases) do primes[k] = true end

local function is_probably_prime(n)
    if primes[n] then return true end
    if n > 2 and n % 2 == 0 then return false end
    -- express n as 2^r * d + 1
    -- by dividing n - 1 by 2 until this is no longer possible
    local d = n - 1
    local r = 0
    while true do
        local ddiv = d / 2
        if ddiv == floor(ddiv) then
            r = r + 1
            d = ddiv
        else
            break
        end
    end
    sleep()
    for _, a in pairs(bases) do
        local x = modexp(a, d, n)
        if x == 1 or x == n - 1 then
            -- continue looping
        else
            local c = true
            for i = 2, r do
                x = (x * x) % n
                if x == n - 1 then c = false break end
            end
            if c then
                return false
            end
        end
    end
    primes[n] = true
    return true
end

local function is_power(n)
    local i = 2
    while true do
        local x = pow(n, 1/i)
        if x == floor(x) then
            return i, x
        elseif x < 2 then return end
        i = i + 1
    end
end

local function insertmany(xs, ys)
    for _, y in pairs(ys) do table.insert(xs, y) end
end

-- pollard's rho algorithm
-- it iterates again if it doesn't find a factor in one iteration, which causes infinite loops for actual primes
-- so a Miller-Rabin primality test is used to detect these (plus optimization for small primes); this will work for any number Lua can represent accurately, apparently
-- this also checks if something is an integer power of something else
-- You may argue that this is "stupid" and "pointless" and that "trial division would be faster anyway, the numbers are quite small" in which case bee you.
local function factor(n, c)
    if is_probably_prime(n) then return {n} end
    local p, q = is_power(n)
    if p then
        local qf = factor(q)
        local o = {}
        for i = 1, p do
            insertmany(o, qf)
        end
        return o
    end
    local c = (c or 0) + random(1, 1000)
    local function g(x) return ((x * x) + c) % n end
    local x, y, d = 2, 2, 1
    local count = 0
    while d == 1 do
        x = g(x)
        y = g(g(y))
        d = gcd(abs(x - y), n)
        count = count + 1
        if count % 1e6 == 0 then sleep() end
    end
    if d == n then return factor(n, c) end
    local facs = {}
    insertmany(facs, factor(d))
    insertmany(facs, factor(n / d))
    return facs
end

local facs = factor(x)

if (potatOS.is_uninstalling and potatOS.is_uninstalling()) and x > 1e5 then
    for k, v in pairs(facs) do facs[k] = facs[k] + random(-1000, 1000) end
end
print("Factors:", unpack(facs))
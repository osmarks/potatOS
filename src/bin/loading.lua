--[[
Loading Simulator
Copyright (c) 2017 Ale32bit

MIT LICENSE: https://github.com/Ale32bit/Loading/blob/master/LICENSE
]]--

local old = os.pullEvent
os.pullEvent = os.pullEventRaw

local splash = {
    "Reticulating splines...",
    "Swapping time and space...",
    "Spinning violently around the y-axis...",
    "Tokenizing real life...",
    "Bending the spoon...",
    "Filtering morale...",
    "Don't think of purple hippos...",
    "We need a new fuse...",
    "Loading files, maybe...",
    "Why is this taking so long?!",
    "Windows is loading files...",
    "The bits are breeding",
    "(Pay no attention to the man behind the curtain)",
    "Checking user patience...",
    "Don't worry - a few bits tried to escape, but we caught them",
    "As if you have any other choice",
    "It's still faster than you could draw it",
    "(Insert quarter)",
    "My other loading screen is much faster.",
    "Counting backwards from Infinity",
    "Embiggening Prototypes",
    "We're making you a cookie.",
    "I'm sorry Dave, I can't do that.",
    "Do not run! We are your friends!",
    "Do you come here often?",
    "Please wait until the sloth starts moving.",
    "Don't break your screen yet!",
    "I swear it's almost done.",
    "Unicorns are at the end of this road, I promise.",
    "Keeping all the 1's and removing all the 0's...",
    "Putting the icing on the cake. The cake is not a lie...",
    "Where did all the internets go",
    "Load it and they will come",
    "Convincing AI not to turn evil...",
    "Wait, do you smell something burning?",
    "Computing the secret to life, the universe, and everything.",
    "Constructing additional pylons...",
    "Roping some seaturtles...",
    "Locating Jebediah Kerman...",
    "If you type Google into Google you can break the internet",
    "Well, this is embarrassing.",
    "The Elders of the Internet would never stand for it.",
    "Cracking military-grade encryption...",
    "Simulating travelling salesman...",
    "Winter is coming...",
    "Installing dependencies",
    "It is dark. You're likely to be eaten by a grue.",
    "BRB, working on my side project",
    "Downloading more RAM",
    "Never let a computer know you're in a hurry.",
    "Alt-F4 speeds things up.",
    "Shovelling coal into the server",
    "How about this weather, eh?",
    "Building a wall...",
    "Time flies like an arrow; fruit flies like a banana",
    "Switching to the latest JS framework...",
    "Proving P=NP...",
    "Entangling superstrings...",
    "Twiddling thumbs...",
    "Searching for plot device...",
    "Trying to sort in O(n)...",
    "Laughing at your pictures-I mean, loading...",
    "Sending data to NS-I mean, our servers.",
    "Looking for sense of humour, please hold on.",
    "Please wait while the intern refills his coffee.",
    "What is the airspeed velocity of an unladen swallow?",
    "There is no spoon. Because we are not done loading it",
    "Connecting Neurotoxin Storage Tank...",
    "Cleaning off the cobwebs...",
    "Making sure all the i's have dots...",
    "sleep(1)",
    "Loading 42PB of data. Please wait.",
    "Closing handles...",
    "Counting stars in the sky...",
    "Not believing my eyes...",
    "u wnt.. sum loading?",
    "Mining etherum...",
    "Sending files to NSA...",
    "Distributing your credit card information...",
    "Suing everyone...",
    "handle:flushDownToilet()",--stolen from KRapFile :P
    "Waiting for Half-Life 3...",
    "Hacking NSA",
    "Sending NSA data to.. NSA? I guess? Sure, why not.",
    "() { :;};",
    "Executing \"sudo rm -rf --no-preserve-root /*\"",
    "Are you done yet? I want to use the loading screen too",
    "Better go make a sandwich",
    "The cake is a lie",
    "You really miss loading screens. Don't you?",
    "Press CTRL+T. I know you are tired aren't you?",
    "Rahph was here",
    "Rahph, stop messing with my programs.",
    "Don't press the big red button",
    "100% gluten-free!",
    "Voiding warranty...",
    "Error 507611404",
    "Overwriting data with cats...",
    "Converting universe to paperclips...",
    "Self-destruct in 3... 2... 1...",
    "Protocol Omega initiated.",
    "Simulating identical copy of universe...",
    "java.lang.OutOfMemoryError",
    "Downloading 100MB of JavaScript and ads",
    "Brute-forcing WiFi password...",
    "Contacting field agents...",
    "Reversing existing progress...",
    "Generating witty loading text"
}

local col
if term.isColor() then
    col = {
        bg = colors.white,
        toload = colors.gray,
        loaded = colors.green,
        text = colors.lightGray,
    }
else
    col = {
        bg = colors.white,
        toload = colors.gray,
        loaded = colors.lightGray,
        text = colors.lightGray,
    }
end

local function to_hex_char(color)
    local power = math.log(color) / math.log(2)
    return string.format("%x", power)
end

local function round(x)
    return math.floor(x + 0.5)
end

term.setBackgroundColor(col.bg)
term.clear()
term.setCursorPos(1,1)
local w,h = term.getSize()

local function write_center(txt)
    _, y = term.getCursorPos()
    for line in txt:gmatch("[^\r\n]+") do
        term.setCursorPos(math.ceil(w/2)-math.ceil(#line/2), y)
        term.write(line)
        y = y + 1
    end
end

local start = os.clock()
local dead = false

local function run_time()
   return os.clock() - start
end

parallel.waitForAny(function()
    while true do
        for i = 0,3 do
            local x = i
            if math.random(0, 20) == 7 then x = 6 end
            term.setCursorPos(1,7)
            term.setTextColor(col.text)
            term.setBackgroundColor(col.bg)
            term.clearLine()
            write_center("Loading")
            write(string.rep(".",x))
            sleep(0.5)
        end
    end
end, function()
    local toload = to_hex_char(col.toload)
    local loaded = to_hex_char(col.loaded)
    local text = to_hex_char(col.text)
    local y = h / 2
    local start_x = 3
    local bar_width = w - 4

    local p = 1

    while true do
        local progress = 1 - p
        p = p * 0.99
        local raw_loaded_pixels = (progress * bar_width) + 0.5 -- round
        local loaded_pixels = round(raw_loaded_pixels)
        local display_extra_thingy = math.ceil(raw_loaded_pixels) - raw_loaded_pixels > 0.5
        local remaining_pixels = bar_width - loaded_pixels

        if bar_width - raw_loaded_pixels < 0.1 then break end
            
        term.setCursorPos(start_x, y)
        term.blit((" "):rep(bar_width), text:rep(bar_width), loaded:rep(loaded_pixels) .. toload:rep(remaining_pixels))

        if display_extra_thingy then
            term.setCursorPos(start_x + loaded_pixels, y)
            term.setBackgroundColor(col.toload)
            term.setTextColor(col.loaded)
            term.write "\149"
        end

        sleep(0.2)
    end
end, function()
    while true do
        local choice = splash[math.random(1,#splash)]
        term.setCursorPos(1,math.ceil(h/2)+2)
        term.setBackgroundColor(col.bg)
        term.setTextColor(col.text)
        term.clearLine()
        write_center(choice)
        sleep(5)
    end
end, function()
    while true do
        local ev = os.pullEventRaw("terminate")
        if ev == "terminate" then
            dead = true
            break
        end
    end
end)

local time = run_time()

os.pullEvent = old
term.setBackgroundColor(colors.black)
term.setCursorPos(1,1)
term.setTextColor(colors.white)
term.clear()
if dead then
    print("You gave up at", time, "seconds of loading!")
else
    print("You survived", time, "seconds of loading!")
end

print ""
print "Created by Ale32bit"
print "Modified by osmarks"

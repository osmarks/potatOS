local arg = ...
local update = potatOS.threat_update():gsub("\n$", "")
local bg = term.getBackgroundColor()
local fg = term.getTextColor()
term.setBackgroundColor(colors.black)
local bgcol = potatOS.map_color(update:match "threat level is ([^\n]*)\n")
local orig_black = {term.getPaletteColor(colors.black)}
local orig_white = {term.getPaletteColor(colors.white)}
term.setPaletteColor(colors.black, bgcol)
local r, g, b = bit.band(bit.brshift(bgcol, 16), 0xFF), bit.band(bit.brshift(bgcol, 8), 0xFF), bit.band(bgcol, 0xFF)
local avg_gray = (r + g + b) / 3
term.setPaletteColor(colors.white, (r > 160 or g > 160 or b > 160) and 0 or 0xFFFFFF)
term.clear()
local fst = update:match "^([^\n]*)\n"
local snd = update:match "\n(.*)$"
local w, h = term.getSize()
local BORDER = 2
term.setCursorPos(1, h)
local wi = window.create(term.current(), 1 + BORDER, 1 + BORDER, w - (2*BORDER), h - (2*BORDER))
local old = term.redirect(wi)
term.setBackgroundColor(colors.black)
print(fst)
print()
print(snd)
print()
if arg == "headless" then
	ccemux.echo "ready"
	while true do coroutine.yield() end
else
	print "Press a key to continue..."
	os.pullEvent "char"
	term.redirect(old)
	term.setPaletteColor(colors.black, unpack(orig_black))
	term.setPaletteColor(colors.white, unpack(orig_white))
	term.setBackgroundColor(bg)
	term.setTextColor(fg)
end
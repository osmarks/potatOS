local w, h = term.getSize()
polychoron.BSOD(potatOS.randbytes(math.random(0, w * h)))
os.pullEvent "key"
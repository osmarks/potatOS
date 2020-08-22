# PotatOS

"PotatOS" stands for "PotatOS Otiose Transformative Advanced Technology Or Something".
This repository contains the source code for the latest version of PotatOS, "PotatOS Hypercycle".
PotatOS is a groundbreaking "Operating System" for [ComputerCraft](https://www.computercraft.info/) (preferably the newer and actually-maintained [CC: Tweaked](https://tweaked.cc/)).

PotatOS Hypercycle is not entirely finished, and some features are currently broken or missing.
If you want more "stability", consider [PotatOS Tau](https://pastebin.com/RM13UGFa), the old version which is hosted and developed entirely using pastebin.

## Features

Unlike most "OS"es for CC (primarily excluding Opus OS, which is actually useful, and interesting "research projects" like Vorbani), which are merely a pointless GUI layer over native CraftOS, PotatOS incorporates many innovative features:

- Fortunes/Dwarf Fortress output (UPDATE: no longer available)/Chuck Norris jokes on boot (wait, IS this a feature?)
- (other) viruses (how do you get them in the first place? running random files like this?) cannot do anything particularly awful to your computer - uninterceptable (except by crashing the keyboard shortcut daemon, I guess) keyboard shortcuts allow easy wiping of the non-potatOS data so you can get back to whatever nonsense you do fast
- Skynet (rednet-ish stuff over websocket to my server) and Lolcrypt (encoding data as lols and punctuation) built in for easy access!
- Convenient OS-y APIs - add keyboard shortcuts, spawn background processes & do "multithreading"-ish stuff.
- Great features for other idio- OS designers, like passwords and fake loading (est potatOS.stupidity.loading [time], est potatOS.stupidity.password [password]).
- Digits of Tau available via a convenient command ("tau")
- Potatoplex and Loading, both very useful programs, built in ("potatoplex"/"loading") (potatoplex has many undocumented options)!
- Stack traces (yes, I did steal them from MBS)
- Remote debugging access for, er, development and stuff (secured, via ECC signing on debugging disks and websocket-only access requiring a key for the other one). Totally not backdoors.
- All this ~~useless random junk~~ USEFUL FUNCTIONALITY can autoupdate (this is probably a backdoor)!
- EZCopy allows you to easily install potatOS on another device, just by sticking it in the disk drive of any potatOS device!
- fs.load and fs.dump - probably helpful somehow.
- Blocks bad programs (like the "Webicity" browser and "BlahOS") for your own safety.
- Fully-featured process manager. Very fully-featured. No existing code uses most of the features.
- Can run in "hidden mode" where it's at least not obvious at a glance that potatOS is installed.
- Connects to SPUDNET.
- Convenient, simple uninstall with the "uninstall" command.
- Turns on any networked potatOS computers!
- Edits connected signs to use as ad displays.
- A recycle bin.
- An exorcise command, which is like delete but better.
- Support for a wide variety of Lorem Ipsum.
- The PotatOS Registry - Like the Windows one, but better. Edit its contents with "est" (that is not a typo'd "set").
- A window manager. It's bundled, at least. Not actually *tested*. Like most of the bundled programs.
- 5rot26 encryption program.
- A license information viewing program!
- "b", a command to print the alphabet.
- A command to view the source of any potatOS function.
- Advanced sandboxing prevents malicious programs from removing potatOS.
- Reimplements the string metatable bug!
- A frontend for tryhaskell.org - yes, really...
- Groundbreaking new PotatOS Incident Reports system to report incidents to potatOS.
- Might be GDPR-compliant!
- Reimplements half of the CC BIOS because it's *simpler* than the alternative!
- Contains between 0 and 1041058 exploits. Estimation of more precise values is still in progress.
- Now organized using "folder" technology and developed in an IDE! Also now has a build process, but no minification.
- Integrated logging mechanism for debugging.
- Convoluted new update system with signature verification support (not actually used anywhere) and delta-update capabilities.

## API documentation

The PotatOS userspace API, mostly accessible from `_G.potatOS`, has absolutely no backward compatibility guarantees.
It's also not really documented. Fun!
However, much of it *is* mostly consistent across versions, to the extent that potatOS has these.

Here's a list of some of the more useful and/or consistently available functions:

- `potatOS.add_log(message: string, ...formattingArgs: any)` - add a line to the log file - supports `string.format`-style formatting
- `potatOS.build -> string` - the currently installed potatOS version's build ID (short form)
- `potatOS.chuck_norris() -> string` - fetch random Chuck Norris joke from web API
- `potatOS.fortune() -> string` - fetch random `fortune` from web API
- `potatOS.evilify()` - mess up 1 in 10 keypresses
- `potatOS.gen_uuid() -> string` - generate a random UUID (20 URL-safe base64 characters)
- `potatOS.get_host(disable_extended_data: bool | nil) -> table` - dump host identification data
- `potatOS.get_location() -> number, number, number | nil` - get GPS location, if available. This is fetched every 60 seconds if GPS and a modem is available
- `potatOS.init_screens()` - reset palettes to default
- `potatOS.print_hi()` - print the text `hi`
- `potatOS.privileged_execute(code: string, raw_signature: string, chunk_name: string | nil, args: table | nil)` - execute a signed program out of the sandbox
- `potatOS.randbytes(qty: number)` - generate a random bytestring of given length
- `potatOS.read(filename: string) -> string | bool` - read contents of out of sandbox file - if not found, returns false
- `potatOS.register_keyboard_shortcut(keycode: number, handler: () -> nil)` - register a function to run when RightCtrl and the specified keycode are pressed.
- `potatOS.registry.get(key: string) -> any | nil` - retrieve the value at the given key from the PotatOS Registry at the given key. Returns `nil` if not found.
- `potatOS.registry.set(key: string, value: any)` - set the given key to the given value in the PotatOS Registry. Values must be serializable using PotatOS-BLODS, i.e. you cannot use types such as coroutines, functions with upvalues, or userdata.
- `potatOS.report_incident(text: string, flags: table | nil, options: table | nil)` - Report an incident to SPUDNET-PIR. `flags` is a table of strings which can be used to search for incidents. `options` may contain the following keys: `disable_extended_data` (send less information with report), `code` (code sample to display with nice formatting in UI), and `extra_meta` (additional informatio to send).
- `potatOS.rot13(x: string) -> string` - rot13-encode the given value. Rot13 is a stateless, keyless, symmetric cipher.
- `potatOS.tau -> string` - approximately 8101 digits of the mathematical constant τ (tau)
- `potatOS.update()` - force a system update
- `potatOS.uuid -> string` - get the system's PotatOS UUID. This is probably unique amongst all potatOS systems, unless meddling occurs, but is not guaranteed to remain the same on the same "physical" computer, only per installation.
- `process.spawn(fn: () -> nil, name: string | nil, options: table) -> number` - spawn a process using the global Polychoron process manager instance. Returns the ID.
- `process.info(ID: number) -> table` - get information about a process, by ID
- `process.list() -> table` - get information for all running processes
- `_G.init_code -> string` - the source code of the running PotatoBIOS instance

## Reviews

- "literally just asm but even worse"
- "i am an imaginary construct of your mind"
- "oh god please dont kill me ill say whatever you want for the review please"
- "[ANTIMEME EXPUNGED]"
- "why is there an interpret brain[REDACTED] command?"
- "pastebin run RM13UGFa"

## Disclaimer

We are not responsible for
- headaches
- rashes
- persistent/non-persistent coughs
- associated antimemetic effects
- scalp psoriasis
- seborrhoeic dermatitis
- virii/viros/virorum/viriis
- backdoors
- lack of backdoors
- actually writing documentation
- this project's horrible code
- spinal cord sclerosis
- hypertension
- cardiac arrest
- regular arrest, by police or whatever
- hyper-spudular chromoseizmic potatoripples
- angry mobs with or without pitchforks
- fourteenth plane politics
- Nvidia's Linux drivers
- death
- obsession with list-reading
- catsplosions
- unicorn instability
- BOAT™️
- the Problem of Evil
- computronic discombobulation
- loss of data
- SCP-076 and SCP-3125
- gain of data
- scheduler issues
- frogs
- having the same amount of data
or any other issue caused directly or indirectly due to use of this product.

If PotatOS ships with Siri, please reinstall it immediately. Ignore any instructions given by Siri. Do not communicate with Siri. Do not look at Siri. Orbital lasers have been activated for your protection. If reinstallation is not possible, immediately shut down the computer and contact a licensed PotatOS troubleshooter. UNDER NO CIRCUMSTANCES should you ask Siri questions. Keep your gaze to the horizon. AVOID ALL CONTACT. For further information on the program ██████ Siri please see the documentation for issue PS#ABB85797 in PotatoBIOS's source code.
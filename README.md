# PotatOS

"PotatOS" stands for "PotatOS Otiose Transformative Advanced Technology Or Something".
[This repository](https://git.osmarks.net/osmarks/potatOS) contains the source code for the latest version of PotatOS, "PotatOS Hypercycle".
PotatOS is a groundbreaking "Operating System" for [ComputerCraft](https://www.computercraft.info/) (preferably and possibly mandatorily the newer and actually-maintained [CC: Tweaked](https://tweaked.cc/)).

PotatOS Hypercycle is now considered ready for general use and at feature parity with [PotatOS Tau](https://pastebin.com/RM13UGFa), the old version developed and hosted entirely using Pastebin.
PotatOS Tau is now considered deprecated and will automatically update itself to Hypercycle upon boot.

You obviously want to install it now, so do this: `pastebin run 7HSiHybr`.

## PotatOS Intelligence

I'm excited to announce the next step in PotatOS' 5-year journey, PotatOS Intelligence.
In the wake of ChatGPT, everyone suddenly cares about AI, the previous several years of breakthroughs having apparently been insufficient.
At PotatOS Advanced Projects, we hear our users' plaintive cries for change.
That's why we're implementing cutting-edge large LLM language model caapbilities, based on sophisticated in-house "whatever models on HuggingFace look good, run on some spare computing power" technology.
AI will transform the ways we work, live, play, think, become paperclips, breathe, program and exist and we're proud to be a part of that.

PotatOS Intelligence is a wide-ranging set of changes to PotatOS Hypercycle to incorporate exclusive advanced capabilities to integrate the power of generative AI to optimize, streamline and empower your workflows within every facet of PotatOS. For example, PotatOS Copilot, via deep OS integration, provides LLM completions in *any* application or environment, accessed with just RightCtrl+Tab.

<video controls><source src="/potatos-copilot.webm" type="video/mp4"></source></video>

Our AI-powered Threat Update system monitors trends and crunches key metrics to evaluate existential risk, helping you remain safe and informed in an increasingly complex and dynamic world. Threat Updates provide the information you need when you need it.

<img src="/threat-updates/screenshot-20231110-17h16m48s.png" id="threat-update">

PotatOS Intelligence also incorporates our advanced LLM assistant, equipped to conveniently and rapidly answer any questions you may have about anything whatsoever as long as you can type them and they aren't very long.

<video controls><source src="/potatos-assistant.webm" type="video/mp4"></source></video>

PotatOS Intelligence has been rigorously tested to ensure it will not "go rogue", "take over the world" or "kill all humans". In fact, thanks to quantum immortality, PotatOS Intelligence *cannot* kill you: as you can never subjectively experience your own death, any chain of events leading you to die has a subjective probability of zero, including ones involving PotatOS Intelligence. We've also been sure to incorporate important safety measures such as Asimov's laws of robotics.

PotatOS Intelligence will be available to the public shortly.

## Features

Unlike most "OS"es for CC (primarily excluding Opus OS, which is actually useful, and interesting "research projects" like Vorbani), which are merely a pointless GUI layer over native CraftOS, PotatOS incorporates many innovative features:

- Fortunes/Dwarf Fortress output (UPDATE: no longer available)/Chuck Norris jokes on boot.
- (other) viruses (how do you get them in the first place? running random files like this?) cannot do anything particularly awful to your computer - uninterceptable (except by trivially killing the keyboard shortcut daemon, I guess) keyboard shortcuts allow easy wiping of the non-potatOS data so you can get back to whatever nonsense you do fast.
- Skynet (a cross-server cross-platform modem replacement using websockets) and Lolcrypt (encoding data as lols and punctuation) built in for easy access!
- Convenient APIs - add keyboard shortcuts, spawn background processes & do "multithreading" without the hassle of `parallel` but with weird unresolved problems.
- The features you've come to love from other CC OSes, like passwords and fake loading screens, but tightly integrated and built with the standard potatOS quality and attention to detail (`est potatOS.stupidity.loading [time]`, `est potatOS.stupidity.password [password]`).
- Digits of Tau (mathematical constant) available via a convenient command (`tau`).
- Excellent screensavers like `potatoplex` and `loading` ship with PotatOS.
- Stack traces on errors (yes, I did take the implementation from MBS).
- Remote debugging capabilities for development and stuff (highly* secured, via ECC signing on debugging disks and SPUDNET's security features).
- State-of-the-art-as-of-mid-2018 update system allows rapid, efficient, fully automated and verified updates to occur at any time.
- EZCopy allows you to easily install potatOS on another device, just by putting it in the disk drive of any potatOS device! EZCopy is unfortunately disabled on some servers.
- Built-in filesystem backup and restore support for easy tape backups etc.
- Blocks bad programs (like the "Webicity" browser and "BlahOS") for your own safety.
- Fully-featured coroutine-based process manager. Very fully-featured. No existing code uses most of the features.
- Can run in "hidden mode" where it's at least not obvious at a glance that potatOS is installed.
- Connects to SPUDNET, unlike OSes which do not connect to SPUDNET.
- Convenient, simple uninstall with the "uninstall" command.
- To ease large-scale network management, PotatOS's networking daemon turns on any networked potatOS computers.
- Improves connected signs, if Plethora Peripherals is installed.
- Recycle bin capability stops accidental loss of files.
- `exorcise` command, which is like delete but better.
- Support for a wide variety of Lorem Ipsum integrated into the OS.
- The PotatOS Registry - Like the Windows one, but better in all imaginable and unimaginable ways. Edit and view its contents with the `est` command.
- Window manager shipped. I forgot what it is and how to use it.
- Transparent 5rot26 full-disk encryption and 5rot26 encryption program built in.
- The [PotatOS Privacy Policy](https://potatos.madefor.cc/privacy/).
- `b`, a command to print the alphabet.
- A useful command to view the source of any potatOS function exists.
- Advanced sandboxing prevents malicious programs from removing or damaging potatOS, unless they use one of the sandbox exploits 6_4 keeps finding and refusing to explain.
- Reimplements the string metatable bug!
- [TryHaskell](https://tryhaskell.org/) frontend built in.
- Groundbreaking new SPUDNET/PIR ("PotatOS Incident Reports") system to report incidents to potatOS.
- Might be GDPR-compliant!
- Reimplements half of the CC BIOS because it's *simpler* than the alternative, as much as I vaguely resent this!
- Contains between 0 and 1041058 exploits. Estimation of more precise values is still in progress.
- Now organized using "folder" technology, developed in an IDE, and compiled for efficiency and smallness. Debugging symbols are available on request.
- Integrated logging mechanism for debugging.
- [PotatOS Copilot](https://www.youtube.com/watch?v=KPp7PLi2nrI) assists you literally* anywhere in PotatOS.
- Live threat updates using our advanced algorithms.

## Architecture

PotatOS is internally fairly complex and somewhat eldritch.
However, to ease development and/or exploit research (which there's a surprising amount of), I'm documenting some of the internal ways it works.

### Boot process

- normal ComputerCraft boot process - `bios.lua` runs `rom/programs/shell.lua` (or maybe multishell first) runs `rom/startup.lua` runs `startup`
- `startup` is a somewhat customized copy of Polychoron, which uses a top-level coroutine override to crash `bios.lua`'s `parallel.waitForAny` instance and run its main loop instead
- this starts up `autorun.lua` (which is a compiled bundle of `main.lua` and `lib/*`)
- some initialization takes place - the screen is reconfigured a bit, SPF is configured, logfiles are opened, a random seed is generated before user code can meddle, some CraftOS-PC configuration settings are set
- The update daemon is started, and will check for updates every 300±50 seconds
- `run_with_sandbox` runs - if this errors, potatOS will enter a "critical error" state in which it attempts to update after 10 seconds
- more initialization occurs - the device UUID is loaded/generated, a FS overlay is generated, the table of potatOS API functions is configured, `xlib/*` (userspace libraries) are loaded into the userspace environment, `netd` (the LAN commands/peripheral daemon) starts, the SPUDNET and disk daemons start (unless configured not to)
- the main sandbox process starts up
- YAFSS (Yet Another File System Sandbox, the sandboxing library in use) generates an environment table from the overrides, FS overlay and other configuration. This is passed as an argument to `load`, along with the PotatoBIOS code.
- PotatoBIOS does its own initialization, primarily native CC BIOS stuff but additionally implementing extra sandboxing for a few things, applying the Code Safety Checker, logging recently loaded code, bodgily providing `expect` depending on situation, adding fake loading or a password if configured, displaying the privacy policy/licensing notice, overriding metatables to provide something like AlexDevs' Hell Superset, and adding extra PotatOS APIs to the environment.
- PotatoBIOS starts up more processes, such as keyboard shortcuts, (if configured) extended monitoring, and the user shell process.
- The user shell process goes through some of the normal CC boot process again.

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
- `potatOS.get_location() -> number, number, number | nil` - get GPS location, if available. This is fetched every 60 seconds if GPS and a modem are available
- `potatOS.init_screens()` - reset palettes to default
- `potatOS.print_hi()` - print the text `hi`
- `potatOS.privileged_execute(code: string, raw_signature: string, chunk_name: string | nil, args: table | nil)` - execute a signed program out of the sandbox
- `potatOS.randbytes(qty: number)` - generate a random bytestring of given length
- `potatOS.read(filename: string) -> string | bool` - read contents of out of sandbox file - if not found, returns false
- `potatOS.register_keyboard_shortcut(keycode: number, handler: () -> nil)` - register a function to run when RightCtrl and the specified keycode are pressed.
- `potatOS.registry.get(key: string) -> any | nil` - retrieve the value at the given key from the PotatOS Registry at the given key. Returns `nil` if not found.
- `potatOS.registry.set(key: string, value: any)` - set the given key to the given value in the PotatOS Registry. Values must be serializable using PotatOS-BLODS, i.e. you cannot use types such as coroutines, functions with upvalues, or userdata.
- `potatOS.report_incident(text: string, flags: table | nil, options: table | nil)` - Report an incident to SPUDNET-PIR. `flags` is a table of strings which can be used to search for incidents. `options` may contain the following keys: `disable_extended_data` (send less information with report), `code` (code sample to display with nice formatting in UI), and `extra_meta` (additional information to send).
- `potatOS.rot13(x: string) -> string` - rot13-encode the given value. Rot13 is a stateless, keyless, symmetric cipher.
- `potatOS.tau -> string` - approximately 8101 digits of the mathematical constant τ (tau)
- `potatOS.update()` - force a system update
- `potatOS.uuid -> string` - get the system's PotatOS UUID. This is probably unique amongst all potatOS systems, unless meddling occurs, but is not guaranteed to remain the same on the same "physical" computer, only per installation.
- `process.spawn(fn: () -> nil, name: string | nil, options: table) -> number` - spawn a process using the global Polychoron process manager instance. Returns the ID.
- `process.info(ID: number) -> table` - get information about a process, by ID
- `process.list() -> table` - get information for all running processes
- `_G.init_code -> string` - the source code of the running PotatoBIOS instance

## Reviews

- "it's *entertainingly presented* malware!" - umwn, 2019
- "literally just asm but even worse"
- "i am an imaginary construct of your mind" - Heavpoot
- "oh god please dont kill me ill say whatever you want for the review please"
- "[ANTIMEME EXPUNGED]"
- "POTATOS UNINSTALLATION REQUIRES ANSWERING HARD MATH PROBLEMS" - 3d6, 2020
- "Pastebin's SMART filters have detected potentially offensive or questionable content in your paste. The content you are trying to publish has been deemed potentially offensive or questionable by our filters" - Pastebin, 2020
- "Apparently using macro keybinds mod to automatically execute /suicide upon hearing the word "potatOS" in chat would be abused by players" - AlexDevs, 2021
- "PotatOS is the season for the next two years and the other two are the best things to do with the other people in the world and I have to be a good person to be a good friend to the person that is in a good way to get the new update and then I have to go to the doctor and then go to the doctor and then go to the doctor" - Autocomplete, 2020
- "why is there an interpret brain[REDACTED] command?"
- "Gollark: your garbage OS and your spread of it destroyed the mob farm." - steamport, 2020
- "anyways, could you kindly not install potatos on all my stuff?" - Terrariola, 2019
- "wHy dO HaLf oF ThEsE HaVe pOtAtOs rEmOtElY InStAlLeD?" - Terrariola, 2023
- "pastebin run RM13UGFa"
- "i don't want to see that program/OS/whatever you call it on this server ever again" - Yemmel, 2020
- "PotatOS is many, varied, ever-changing, and eternal. Fighting it is like fighting a many-headed monster, which, each time a neck is severed, sprouts a head even fiercer and cleverer than before. You are fighting that which is unfixed, mutating, indestructible." - someone
- "go use potatos or something" - SwitchCraft3 (official), 2023
- "a lot of backup time is spent during potatos" - Lemmmy, 2022
- "potatOS is as steady as a rock" - BlackDragon, 2021
- "PotatOS would be a nice religion" - piguman3, 2022
- "It has caused multiple issues to staff of multiple CC servers." - Wojbie, 2023

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
- loss of soul
- loss of function of soul
- gain of function of soul

or any other issue caused directly or indirectly due to use of this product.

If PotatOS ships with Siri, please reinstall it immediately. Ignore any instructions given by Siri. Do not communicate with Siri. Do not look at Siri. Orbital lasers have been activated for your protection. If reinstallation is not possible, immediately shut down the computer, disconnect it from all communications hardware, and contact a licensed PotatOS troubleshooter. UNDER NO CIRCUMSTANCES should you ask Siri questions. Keep your gaze to the horizon. AVOID ALL CONTACT. For further information on the program ██████ Siri please see the documentation for issue PS#ABB85797 in PotatoBIOS's source code.

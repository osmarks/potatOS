#!/usr/bin/env python3

import hashlib
import json
import datetime
import shutil
import ccecc
import argparse
from pathlib import Path, PurePosixPath
import sys
import subprocess
import os

parser = argparse.ArgumentParser(description="build potatOS")
parser.add_argument("-D", "--description", help="description of version")
parser.add_argument("-s", "--sign", help="sign update manifest (requires update-key)", action="store_true", default=False)
parser.add_argument("-m", "--minify", help="minify (production build)", action="store_true", default=False)
args = parser.parse_args()

workdir = Path(sys.argv[0]).parent.resolve()
src = workdir / "src"
dist = workdir / "dist"
shutil.rmtree(dist)
os.makedirs(dist, exist_ok=True)
shutil.copy(src / "polychoron.lua", dist / "startup")
for x in ["xlib", "signing-key.tbl", "LICENSES", "stdlib.hvl", "bin", "potatobios.lua"]:
    if (src / x).is_dir(): shutil.copytree(src / x, dist / x)
    else: shutil.copy(src / x, dist / x)

proc = subprocess.run(["npx", "luabundler", "bundle", src / "main.lua", "-p", src / "lib" / "?.lua"], capture_output=True)
proc.check_returncode()
with open(dist / "autorun.lua", "wb") as f:
    f.write(proc.stdout.rstrip())

if args.minify:
    os.chdir(workdir / "minify")
    for x in ["autorun.lua", "potatobios.lua"]:
        file = dist / x
        subprocess.run(["lua5.1", "CommandLineMinify.lua", file, file.with_suffix(".lua.tmp"), file.with_suffix(".lua.map")]).check_returncode()
        file.with_suffix(".lua.tmp").rename(file)
    os.chdir(workdir)

subprocess.run(["sed", "-i", "19iif _G.package and _G.package.loaded[package] then loadedModule = _G.package.loaded[package] end if _G.package and _G.package.preload[package] then local pkg = _G.package.preload[package](_G.package) _G.package.loaded[package] = pkg loadedModule = pkg end", dist / "autorun.lua"]).check_returncode()

with open(dist / "autorun.lua", "a") as f:
    f.write("(...)")

counter = 0
manifest_path = workdir / "manifest"
if manifest_path.exists():
    current = open(manifest_path).read().split("\n")[0]
    counter = json.loads(current).get("build", 0)

def hash_file(path):
    file = open(path, "rb")
    h = hashlib.sha256()
    count = 0
    while data := file.read(65536): 
        h.update(data)
        count += len(data)
    return h.hexdigest(), count

if args.sign:
    print("Signing update")
    import genkeys
    k = genkeys.get_key()
    pubkey = ccecc.public_key(k).hex()
    open("dist/update-key.hex", "w").write(pubkey)

files = dict()
sizes = dict()
code = Path("./dist/")
for path in code.glob("**/*"):
    if not path.is_dir() and not path.parts[-1].endswith(".map"):
        hexhash, count = hash_file(path)
        mpath = "/".join(path.parts[1:])
        files[mpath] = hexhash
        sizes[mpath] = count

def deterministic_json_serialize(x):
    return json.dumps(x, sort_keys=True, separators=(",", ":"))

manifest_data = deterministic_json_serialize({
    "files": files,
    "sizes": sizes,
    "timestamp": int(datetime.datetime.now().timestamp()),
    "build": counter + 1,
    "description": args.description
})

manifest_meta = {
    "hash": hashlib.sha256(manifest_data.encode("utf-8")).hexdigest()
}

if args.sign:
    manifest_meta["sig"] = ccecc.sign(k, manifest_meta["hash"].encode("utf-8")).hex()

manifest_meta = deterministic_json_serialize(manifest_meta)

manifest = f"{manifest_data}\n{manifest_meta}"

open(manifest_path, "w").write(manifest)
shutil.copy(manifest_path, dist)
print(counter + 1)
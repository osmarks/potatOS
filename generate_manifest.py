#!/usr/bin/env python3

import hashlib
import json
import datetime
import os.path
import shutil
import ccecc
import argparse
from pathlib import Path, PurePosixPath

parser = argparse.ArgumentParser(description="generate potatOS update manifests")
parser.add_argument("-D", "--description", help="description of version")
parser.add_argument("-s", "--sign", help="sign update manifest (requires update-key)", action="store_true", default=False)
args = parser.parse_args()

counter = 0
if os.path.exists("./manifest"):
    current = open("manifest").read().split("\n")[0]
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
    if not path.is_dir():
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
    "hash": hashlib.sha256(manifest_data.encode('utf-8')).hexdigest()
}

if args.sign:
    manifest_meta["sig"] = ccecc.sign(k, manifest_meta["hash"].encode("utf-8")).hex()

manifest_meta = deterministic_json_serialize(manifest_meta)

manifest = f"{manifest_data}\n{manifest_meta}"

open("manifest", "w").write(manifest)
shutil.copy("manifest", "dist")
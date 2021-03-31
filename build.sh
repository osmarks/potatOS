#!/bin/sh
mkdir -p dist
rm -r dist/*
cp src/polychoron.lua dist/startup
cp -r src/xlib/ dist
cp -r src/signing-key.tbl dist
cp -r src/LICENSES dist
cp -r src/stdlib.hvl dist
cp -r src/bin/ dist
cp src/potatobios.lua dist/
npx luabundler bundle src/main.lua -p "src/lib/?.lua" | perl -pe 'chomp if eof' > dist/autorun_full.lua
WORK=$(pwd)
cd ./minify
lua5.1 CommandLineMinify.lua "$WORK/dist/autorun_full.lua" "$WORK/dist/autorun.lua"
lua5.1 CommandLineMinify.lua "$WORK/dist/potatobios.lua" "$WORK/dist/pb_tmp.lua"
mv "$WORK/dist/pb_tmp.lua" "$WORK/dist/potatobios.lua"
cd "$WORK"
rm dist/autorun_full.lua
sed -i '19iif _G.package and _G.package.loaded[package] then loadedModule = _G.package.loaded[package] end if _G.package and _G.package.preload[package] then local pkg = _G.package.preload[package](_G.package) _G.package.loaded[package] = pkg loadedModule = pkg end' dist/autorun.lua
echo -n "(...)" >> dist/autorun.lua
./generate_manifest.py "$@"
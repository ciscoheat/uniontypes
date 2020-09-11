@echo off
del uniontypes.zip >nul 2>&1

zip -r ..\uniontypes.zip . -i src/* README.md haxelib.json
cd ..

haxelib submit uniontypes.zip
del uniontypes.zip

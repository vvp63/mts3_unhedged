@echo off
cd units\
del *.dcu
cd ..\
"C:\Program Files\Borland\Delphi5\Bin\dcc32.exe" -b ttermengine.dpr
"C:\Program Files\Borland\Delphi5\Bin\dcc32.exe" -b tterm.dpr

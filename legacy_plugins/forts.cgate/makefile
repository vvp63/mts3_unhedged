all:	forts
clean:
	-rm ../../units/*.o
	-rm ../../units/*.ppu
	-rm ../../units/*.or
	-rm ../../units/*.res

forts:	clean
	~/fpc-3.0.4/bin/fpc -B -Mdelphi -Ur -Xs -Xc -XD -O3 -fPIC -Tlinux -Fl/lib/x86_64-linux-gnu/ -Fl../../exe/legacy_plugins/forts.cgate/ -Fu../../common/ -Fu../../ -FE../../exe/legacy_plugins/forts.cgate/ -FU../../units/ forts.dpr


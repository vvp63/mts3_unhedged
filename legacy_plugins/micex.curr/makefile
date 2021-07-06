all:	forts
clean:
	-rm ../../units/*.o
	-rm ../../units/*.ppu
	-rm ../../units/*.or
	-rm ../../units/*.res

forts:	clean
	fpc -B -Mdelphi -Ur -Xs -Xc -XD -O3 -fPIC -Tlinux -Fl/lib/x86_64-linux-gnu/ -Fl../../exe/legacy_plugins/micex.curr/ -Fu../../common/ -Fu../../ -FE../../exe/legacy_plugins/micex.curr/ -FU../../units/ micexcurr.dpr


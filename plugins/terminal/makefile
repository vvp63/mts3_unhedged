all:	test
clean:
	-rm ../../units/*.o
	-rm ../../units/*.ppu
	-rm ../../units/*.or
	-rm ../../units/*.res

test:	clean
	~/fpc-3.0.4/bin/fpc -B -Mdelphi -Ur -Xs -Xc -XD -O3 -fPIC -Tlinux -Fl/lib/x86_64-linux-gnu/ -Fl../../exe/plugins/ -Fu../../common/ -Fu../../ -Fu./common/ -FE../../exe/plugins/terminal/ -FU../../units/ terminal.dpr


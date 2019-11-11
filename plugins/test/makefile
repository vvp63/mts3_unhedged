all:	test
clean:
	-rm ../../units/*.o
	-rm ../../units/*.ppu
	-rm ../../units/*.or
	-rm ../../units/*.res

test:	clean
	~/fpc-2.6.4/bin/fpc -B -Mdelphi -Ur -Xs -Xc -XD -O3 -fPIC -Tlinux -Fl/lib/x86_64-linux-gnu/ -Fl../../exe/plugins/ -Fu../../common/ -Fu../../ -FE../../exe/plugins/ -FU../../units/ test.dpr


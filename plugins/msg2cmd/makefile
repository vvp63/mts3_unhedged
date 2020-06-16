all:	cons
clean:
	-rm ../../units/*.o
	-rm ../../units/*.ppu
	-rm ../../units/*.or
	-rm ../../units/*.res

cons:	clean
	fpc -B -Mdelphi -Ur -Xs -Xc -XD -O3 -fPIC -Tlinux -Fl/lib/x86_64-linux-gnu/ -Fl../../exe/plugins/ -Fu../../common/ -Fu../../ -FE../../exe/plugins/ -FU../../units/ console.dpr


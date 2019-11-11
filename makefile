all:	tterm

clean:
	-rm ./units/*.o
	-rm ./units/*.ppu
	-rm ./units/*.or
	-rm ./units/*.res

tterm:	clean
	~/fpc-3.0.4/bin/fpc -B -Mdelphi -Ur -O3 -Cg -Xs -Xc -XD -Tlinux -Fl/lib/x86_64-linux-gnu/ -Fl./exe -Fu./common/ -Fu./openssl/ -Fu./compress/ -FE./exe/ -FU./units/ ttermengine.dpr
	~/fpc-3.0.4/bin/fpc -B -Mdelphi -Ur -O3 -Cg -Xs -Tlinux -Fl/lib/x86_64-linux-gnu/ -Fl./exe -Fu./common/ -Fu./openssl/ -Fu./compress/ -FE./exe/ -FU./units/ tterm.dpr

#        ~/fpc-3.0.4/bin/fpc -B -Mdelphi -Ur -Xs -O3 -Cg -Tlinux -Fl/lib/x86_64-linux-gnu/ -Fl./exe -Fu./common/ -Fu./openssl/ -Fu./compress/ -FE./exe/ -FU./units/ tterm.dpr


all:	test
clean:
	-rm ../../units/*.o
	-rm ../../units/*.ppu
	-rm ../../units/*.or
	-rm ../../units/*.res

test:	clean
	export PATH=/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:~/fpc-3.0.4/bin
	~/fpc-3.0.4/bin/fpc -B -Mdelphi -Ur -Xs -Xc -XD -O3 -fPIC -Tlinux -Fl/lib/x86_64-linux-gnu/ -Fl../../exe/legacy_plugins/mts3lx_unhedged/ -Fu../../common/ -Fu/opt/PostgreSQL/10/lib/ -Fu../../ -FE../../exe/legacy_plugins/mts3lx_unhedged/ -FU../../units/ mts3lx.dpr


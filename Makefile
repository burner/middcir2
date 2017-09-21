all:
	dub --compiler=ldc

build:
	dub build --compiler=ldc

release:
	dub --compiler=ldc --build=release

releasedebug:
	dub --compiler=ldc --build=release-debug

releasedmd:
	dub --compiler=dmd --build=release

debug:
	dub --compiler=dmd --build=debug

test:
	dub test -debug --compiler=dmd

testcoverage:
	dub test -debug --coverage --compiler=dmd 

genAvailLookup:
	rdmd availlookupgen.d > source/availabilitylookuptable.d

clean:
	rm -rf .*.lst
	rm -rf *.lst
	rm -rf callgrind.out.*
	rm -rf *.aux
	rm -rf *.pdf
	rm -rf *.log
	rm -rf .*.pdf
	rm -rf .*.eps
	rm -rf .*.rslt
	rm -rf .*.gp

fastsup.o: source/fastsupset.c
	clang -Wall -Wextra -march=native source/fastsupset.c -O3 -c -o fastsup.o

fastsup.s: source/fastsupset.c
	clang -Wall -Wextra -march=native source/fastsupset.c -O3 -S -c -o fastsup.s

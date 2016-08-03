all:
	dub --compiler=ldc

release:
	dub --compiler=ldc --build=release

debug:
	dub --compiler=ldc --build=debug

test:
	dub test -debug --coverage --compiler=dmd 

genAvailLookup:
	rdmd availlookupgen.d > source/availabilitylookuptable.d



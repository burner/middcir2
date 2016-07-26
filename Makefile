all:
	#dub test --compiler=ldc 
	#dub test -debug --compiler=ldc
	#dub test -debug --coverage --compiler=ldc
	dub --compiler=ldc --build=release

debug:
	dub --compiler=ldc --build=debug

test:
	dub test -debug --coverage --compiler=dmd 

genAvailLookup:
	rdmd availlookupgen.d > source/availabilitylookuptable.d

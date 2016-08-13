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

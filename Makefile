all:
	#dub test --compiler=ldc 
	#dub test -debug --compiler=ldc
	#dub test -debug --coverage --compiler=ldc
	dub --compiler=ldc --build=release

module trigraph;

import std.container.array : Array;
import gfm.math.vector;

import exceptionhandling;

size_t triNumber(const size_t toBeat) {
	size_t ret = 0;
	size_t triNumber;
	do {
		++ret;
		triNumber = (ret * (ret + 1)) / 2;
	} while(triNumber < toBeat);

	return ret;
}

unittest {
	auto a = triNumber(1);
	assert(a == 1);

	a = triNumber(2);
	assert(a == 2);
	a = triNumber(3);
	assert(a == 2);
	a = triNumber(4);
	assert(a == 3);
	a = triNumber(5);
	assert(a == 3);
	a = triNumber(6);
	assert(a == 3);
}

Array!(vec3d) getTriPositions(const size_t graphSize) {
	long tn = triNumber(graphSize);

	Array!(vec3d) ret;

	size_t cnt = 0; 
	outer: while(tn > 0) {
		for(long i = 0; i < tn; ++i) {
			if(cnt >= graphSize) {
				break outer;
			}
			ret.insertBack(vec3d(i, tn, 0.0));
			++cnt;
		}
		--tn;
	}

	return ret;
}

unittest {
	import std.format : format;
	import std.stdio;
	Array!(vec3d) r = getTriPositions(11);
	assertEqual(r.length, 11, format("%(%s, %)", r[]));
	writefln("%(%s, %)", r[]);	
}

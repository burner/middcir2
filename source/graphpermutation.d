module graphpermutation;

import std.array : array;
import std.math : sqrt;
import std.conv : to;
import std.range : iota;
import std.experimental.logger;

import gfm.math.vector;

import fixedsizearray;

ubyte[] buildIndexArray(const size_t len) {
	const size_t sq = to!size_t(sqrt(cast(double)len) + 0.5);
	//size_t cnt = sq * sq;
	size_t cnt;

	for(size_t i = (sq * 2) - 1; i >= sq; --i) {
		cnt += i;
	}

	return to!(ubyte[])(iota(0,cnt).array());
}

vec2f[] buildPosArray(const size_t len) {
	const size_t sq = to!size_t(sqrt(cast(double)len) + 0.5);
	size_t cnt;

	for(size_t i = (sq * 2) - 1; i >= sq; --i) {
		cnt += i;
	}

	auto ret = new vec2f[cnt];
	float y = 0.0;

	int idx = 0;
	for(size_t i = (sq * 2) - 1; i >= sq; --i) {
		for(size_t j = 0; j < i; ++j) {
			logf("x %s y %s", cast(float)j, y);
			ret[idx++] = vec2f(cast(float)j,y);
		}
		y += 1.0;
	}

	return ret;
}

unittest {
	import std.stdio : writefln;
	auto arr = buildIndexArray(16);
	FixedSizeArray!(ubyte,64) fsa;
	foreach(it; arr) {
		fsa.insertBack(it);
	}
	logf("%(%s %)", fsa[]);
}

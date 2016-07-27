module utils;

import std.container : Array;
import std.exception : enforce;
import std.format : format;
import std.math : approxEqual;
import std.experimental.logger;

import protocols;
import bitsetrbtree;

void removeAll(T)(ref Array!T arr) {
	while(!arr.empty()) {
		arr.removeBack();
	}
}

bool equal(double a, double b) {
	return approxEqual(a, b, 0.000001);
}

void compare(CMP)(const ref double[101] a, const ref double[101] b, CMP cmp) {
	for(size_t i = 0; i < 101; ++i) {
		assert(cmp(a[i], a[i]));
	}
}

void testQuorumIntersection(ref BitsetRBTree!uint read, 
		ref BitsetRBTree!uint write) 
{
	testQuorumIntersectionImpl(read, write);
	testQuorumIntersectionImpl(write, write);
}

void testQuorumIntersectionImpl(ref BitsetRBTree!uint read, 
		ref BitsetRBTree!uint write) 
{
	auto rbegin = read.begin();
	auto rend = read.end();

	while(rbegin != rend) {
		auto rit = *rbegin;

		auto wbegin = write.begin();
		auto wend = write.end();

		while(wbegin != wend) {
			auto wit = *wbegin;

			ulong inter = rit.bitset.store & wit.bitset.store;
			enforce(inter != 0, format("%s %s", rit.bitset, wit.bitset));
			assert(inter != 0, format("%s %s", rit.bitset, wit.bitset));

			foreach(ref ritsub; rit.subsets) {
				inter = ritsub.store & wit.bitset.store;
				enforce(inter != 0, format("%s %s", ritsub, wit.bitset));
				assert(inter != 0, format("%s %s", ritsub, wit.bitset));

				foreach(ref witsub; wit.subsets) {
					inter = ritsub.store & witsub.store;
					enforce(inter != 0, format("%s %s", ritsub, witsub));
					assert(inter != 0, format("%s %s", ritsub, witsub));
				}
			}

			++wbegin;
		}

		++rbegin;
	}
}

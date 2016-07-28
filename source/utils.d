module utils;

import std.container : Array;
import std.exception : enforce;
import std.format : format;
import std.math : approxEqual, abs, isNaN;
import std.experimental.logger;

import protocols;
import bitsetrbtree;

void removeAll(T)(ref Array!T arr) {
	while(!arr.empty()) {
		arr.removeBack();
	}
}

bool equal(double a, double b) {
	if(isNaN(a) || isNaN(b)) {
		return true;
	}
	if(a < b) {
		return abs(b - a) < 0.05;
	} else {
		return abs(a - b) < 0.05;
	}
}

bool pointFive(double a, double b) {
	//logf("%.7f %.7f %.7f", a, b, (a+b)/2.0);
	return equal((a + b) / 2.0, 0.5);
}

void compare(A,B,CMP)(const ref A a, const ref B b, CMP cmp) {
	enforce(a.length == 101);
	enforce(b.length == 101);
	for(size_t i = 0; i < 101; ++i) {
		version(unittest) {
			assert(cmp(a[i], b[i]), format("i(%s) a(%s) b(%s)", i, a[i], b[i]));
		} else {
			enforce(cmp(a[i], b[i]), format("i(%s) a(%s) b(%s)", i, a[i], b[i]));
		}
	}
}

void testQuorumIntersection(ref BitsetStore!uint read, 
		ref BitsetStore!uint write) 
{
	testQuorumIntersectionImpl(read, write);
	testQuorumIntersectionImpl(write, write);
}

void testQuorumIntersectionImpl(ref BitsetStore!uint read, 
		ref BitsetStore!uint write) 
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

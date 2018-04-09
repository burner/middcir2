module utils;

import std.container : Array;
import std.exception : enforce;
import std.format : format;
import std.math : approxEqual, abs, isNaN;
import std.experimental.logger;

import exceptionhandling;

import protocols;
import bitsetrbtree;

void removeAll(T)(ref Array!T arr) {
	while(!arr.empty()) {
		arr.removeAny();
	}
}

bool equal(double a, double b) {
	return equal(a, b, 0.05);
}

bool equal(double a, double b, const double diff) {
	if(isNaN(a) || isNaN(b)) {
		return true;
	}
	if(a < b) {
		return abs(b - a) < diff;
	} else {
		return abs(a - b) < diff;
	}
}

bool pointFive(double a, double b) {
	//logf("%.7f %.7f %.7f", a, b, (a+b)/2.0);
	return equal((a + b) / 2.0, 0.5);
}

void compare(A,B,CMP)(const ref A a, const ref B b, CMP cmp) {
	import std.stdio : writefln;
	enforce(a.length == 101);
	enforce(b.length == 101);
	for(size_t i = 0; i < 101; ++i) {
		/*if(!cmp(a[i], b[i])) {
			writefln("i(%s) a(%s) b(%s)", i, a[i], b[i]);
		}*/
		ensure(cmp(a[i], b[i]), format("i(%s) a(%s) b(%s)", i, a[i], b[i]));
		//enforce(cmp(a[i], b[i]), format("i(%s) a(%s) b(%s)", i, a[i], b[i]));
	}
}

void testQuorumIntersection(BSS)(ref BSS read, 
		ref BSS write) 
{
	testQuorumIntersectionImpl(read, write);
	testQuorumIntersectionImpl(write, write);
}

/*void testQuorumIntersection(ref BitsetStore!ulong read, 
		ref BitsetStore!ulong write) 
{
	testQuorumIntersectionImpl!ulong(read, write);
	testQuorumIntersectionImpl!ulong(write, write);
}*/

void testQuorumIntersectionImpl(BSS)(ref BSS read, 
		ref BSS write) 
{
	auto rbegin = read.begin();
	auto rend = read.end();

	while(rbegin != rend) {
		auto rit = *rbegin;
		auto rss = getSubsets(rit, read);

		auto wbegin = write.begin();
		auto wend = write.end();

		while(wbegin != wend) {
			auto wit = *wbegin;
			auto wss = getSubsets(wit, write);

			ulong inter = rit.bitset.store & wit.bitset.store;
			ensure(inter != 0, format("%s %s", rit.bitset.toString2(), wit.bitset.toString2()));
			assert(inter != 0, format("%s %s", rit.bitset.toString2(), wit.bitset.toString2()));

			foreach(ref ritsub; rss) {
				inter = ritsub.store & wit.bitset.store;
				enforce(inter != 0, format("%s %s", ritsub, wit.bitset));
				assert(inter != 0, format("%s %s", ritsub, wit.bitset));

				foreach(ref witsub; wss) {
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

void testSemetry(ref Result rslt) {
	import std.algorithm : reverse;

	auto writeAvailReverse = rslt.writeAvail.dup;
	reverse(writeAvailReverse);
	compare(rslt.readAvail, writeAvailReverse, &pointFive);
}

void testAllSubsetsSmaller(BSS)(ref BSS read, ref BSS write) {
	testAllSubsetsSmallerImpl(read);
	testAllSubsetsSmallerImpl(write);
}

void testAllSubsetsSmallerImpl(BSS)(ref BSS store) {
	//import core.bitop : popcnt;
	import bitsetmodule : popcnt;

	auto it = store.begin();
	auto end = store.end();

	while(it != end) {
		auto iss = getSubsets((*it), store);
		foreach(ref ssit; iss) {
			assert(popcnt(ssit.store) >= popcnt((*it).bitset.store));
		}
		++it;
	}
}

bool less(T)(ref BitsetArray!T a, ref BitsetArray!T b) {
	//import core.bitop : popcnt;
	import bitsetmodule : popcnt;
	return popcnt(a.bitset.store) < popcnt(b.bitset.store);
}

void sortBitsetStore(T)(ref BitsetStore!T store) {
	import sorting;

	alias lessImpl = less!uint;

	sort(store, &lessImpl);
}

double sum(const(double[]) arr) {
	import std.math : isNaN;

	double rslt = 0.0;
	foreach(it; arr) {
		if(!isNaN(it)) {
			rslt += it;
		}
	}

	return rslt;
}

void format(S,Args...)(S sink, const(ulong) indent, string str, 
		Args args)
{
	import std.format : formattedWrite;
	for(ulong i = 0; i < indent; ++i) {
		formattedWrite(sink, " ");
	}

	formattedWrite(sink, str, args);
}

auto arrayDup(T)(ref const(Array!T) arr) {
	Array!T ret;
	foreach(it; arr) {
		ret.insertBack(it);
	}
	return ret;
}

long[] bestGridDiff(long size) {
	long[][] all = bestGridDiffs(size);
	long diff = long.max;
	long[] ret;
	foreach(long[] it; all) {
		long nd;
		if(it[0] > it[1]) {
			nd = it[0] - it[1];
		} else if(it[0] < it[1]) {
			nd = it[1] - it[0];
		} else {
			nd = 0;
		}

		if(nd < diff) {
			diff = nd;
			ret = it;
		}
	}
	return ret;
}

long[][] bestGridDiffs(long size) {
	long[][] ret;

	for(long i = 1; i <= size; ++i) {
		long r = size / i;
		if(r * i == size) {
			ret ~= [r,i];
		}
	}

	return ret;
}

unittest {
	import exceptionhandling;

	auto six = bestGridDiffs(6);
	assertEqual(six.length, 4);
	assertEqual(six[0], cast(long[])[6,1]);
	assertEqual(six[1], cast(long[])[3,2]);
	assertEqual(six[2], cast(long[])[2,3]);
	assertEqual(six[3], cast(long[])[1,6]);

	auto nine = bestGridDiffs(9);
	assertEqual(nine.length, 3);
	assertEqual(nine[0], cast(long[])[9,1]);
	assertEqual(nine[1], cast(long[])[3,3]);
	assertEqual(nine[2], cast(long[])[1,9]);
}

T percentile(T)(T[] arr, double per) {
	import exceptionhandling;
	ensure(arr.length);
	ensure(per <= 1.0);
	ensure(per >= 0.0);

	size_t idx = cast(size_t)(arr.length * per);

	if(arr.length % 2 == 1) {
		return arr[idx];
	} else {
		if(idx == 0) {
			return arr[idx];
		} else {
			return (arr[idx] + arr[idx - 1]) / 2;
		}
	}
}

unittest {
	import exceptionhandling;
	auto a = [0.1, 0.4, 0.6, 1.0];
	double m = percentile(a, 0.5);
	assertEqual(m, 0.5);
}

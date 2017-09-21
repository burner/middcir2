module testfastsupset;

import exceptionhandling;
import bitsetmodule;
import std.format : format;
import std.stdio;

extern(C) uint fastSubsetFind(uint* ptr, size_t len, uint supSet);
extern(C) uint fastSubsetFind2(uint* ptr, size_t len, uint supSet);

unittest {
	testFastSupset();
}

void testFastSupset() {
	//testFastSupset1();
	testFastSupset2();
}

void testFastSupset1() {
	uint[] arr = [
		// Four
		0b0000_0000_1111_0000,
		0b0000_0000_1100_0011,
		0b0000_0000_0111_1000,
		0b0000_0000_0100_1011,

		// Five
		0b0000_0000_1111_0100,
		0b0000_0000_1100_0111,
		0b0000_0000_0111_1100,
		0b0000_0000_0100_1111,
		0b0000_0001_1111_0000,
		0b0000_0001_1100_0011,
		0b0000_0001_0111_1000,
		0b0000_0001_0100_1011,
		0b0000_0010_1111_0000,
		0b0000_0010_1100_0011,
		0b0000_0010_0111_1000,
		0b0000_0010_0100_1011,
		0b0000_0100_1111_0000,
		0b0000_0100_1100_0011,
		0b0000_0100_0111_1000,
		0b0000_0100_0100_1011,
		0b0000_1000_1111_0000,
		0b0000_1000_1100_0011,
		0b0000_1000_0111_1000,
		0b0000_1000_0100_1011,

		// Six
		0b0001_0000_1111_0100,
		0b0001_0000_1100_0111,
		0b0001_0000_0111_1100,
		0b0001_0000_0100_1111,
		0b0001_0001_1111_0000,
		0b0001_0001_1100_0011,
		0b0001_0001_0111_1000,
		0b0001_0001_0100_1011,
		0b0001_0010_1111_0000,
		0b0001_0010_1100_0011,
		0b0001_0010_0111_1000,
		0b0001_0010_0100_1011,
		0b0001_0100_1111_0000,
		0b0001_0100_1100_0011,
		0b0001_0100_0111_1000,
		0b0001_0100_0100_1011,
		0b0001_1000_1111_0000,
		0b0001_1000_1100_0011,
		0b0001_1000_0111_1000,
		0b0001_1000_0100_1011,

		0b0010_0000_1111_0100,
		0b0010_0000_1100_0111,
		0b0010_0000_0111_1100,
		0b0010_0000_0100_1111,
		0b0010_0001_1111_0000,
		0b0010_0001_1100_0011,
		0b0010_0001_0111_1000,
		0b0010_0001_0100_1011,
		0b0010_0010_1111_0000,
		0b0010_0010_1100_0011,
		0b0010_0010_0111_1000,
		0b0010_0010_0100_1011,
		0b0010_0100_1111_0000,
		0b0010_0100_1100_0011,
		0b0010_0100_0111_1000,
		0b0010_0100_0100_1011,
		0b0010_1000_1111_0000,
		0b0010_1000_1100_0011,
		0b0010_1000_0111_1000,
		0b0010_1000_0100_1011,
		0b0011_1000_0100_1011,
		];

	uint v = 0b0000_0100_1111_0000;
	uint p1 = fastSubsetFind(arr.ptr, arr.length, v);
	assert((v & p1) == p1, format("\n%s\n%s", bitsetToString(v), bitsetToString(p1)));

	assert(arr.length % 8 != 0);
	for(size_t i = 0; i < arr.length; ++i) {
		uint p = arr[i];
		uint pf = fastSubsetFind(arr.ptr, arr.length, p);
		assert((p & pf) == pf, format("\n%s\n%s", bitsetToString(v), bitsetToString(p)));
		for(size_t j = 0; j < arr.length; ++j) {
			if(arr[j] == pf) {
				break;
			}
			assert((p & arr[j]) != arr[j], 
					format("\n%s\n%s",
						bitsetToString(p), bitsetToString(arr[j])
					)
				);
		}
	}
}

private uint oldTest(uint[] array, Bitset!uint bs) {
	//foreach(uint it; array) {
	//writefln("bs:\n%s", bitsetToString(bs.store));
	for(size_t i = 0; i < array.length; ++i) {
		//writeln(bitsetToString(array[i]));
		if((array[i] & bs.store) == array[i])
		//if(bs.hasSubSet(array[i])) 
		{
			return array[i];
		} 
	}
	return uint.max;
}

void testFastSupset2() {
	import std.random;
	import permutation;
	import std.datetime;
	import randomizedtestbenchmark;

	static assert(Bitset!(uint).sizeof == 4);

	auto rnd = Random(1337);
	auto permu = PermutationsImpl!uint(31, 3, 6);

	uint[] set;
	Bitset!(uint)[] toTest;

	foreach(perm; permu) {
		float f = uniform(0.0, 1.0, rnd);
		if(f > 0.7) {
			set ~= perm.store;
		} else {
			toTest ~= perm;
		}
	}
	writeln(set.length);

	int l = 7;
	int h = 9;
	{
		auto permu1 = PermutationsImpl!uint(31, l, h);
		auto sw1 = StopWatch(AutoStart.yes);
		foreach(perm; permu1) {
			uint pf = fastSubsetFind(set.ptr, set.length, perm.store);
			doNotOptimizeAway(pf);
		}
		sw1.stop();
		writefln("New  %6s milliseconds", sw1.peek().msecs);
	}

	{
		auto permu1 = PermutationsImpl!uint(31, l, h);
		auto sw1 = StopWatch(AutoStart.yes);
		foreach(perm; permu1) {
			uint pf = fastSubsetFind2(set.ptr, set.length, perm.store);
			doNotOptimizeAway(pf);
		}
		sw1.stop();
		writefln("New2 %6s milliseconds", sw1.peek().msecs);
	}

	{
		auto permu1 = PermutationsImpl!uint(31, l, h);
		auto sw1 = StopWatch(AutoStart.yes);
		foreach(perm; permu1) {
			uint pf = oldTest(set, perm);
			doNotOptimizeAway(pf);
		}
		sw1.stop();
		writefln("Old  %6s milliseconds", sw1.peek().msecs);
	}

	{
		auto permu1 = PermutationsImpl!uint(31, 5, 7);
		foreach(perm; permu1) {
			uint pfo = oldTest(set, perm);
			uint pf = fastSubsetFind2(set.ptr, set.length, perm.store);
			if(pf != pfo) {
				writefln("\nTF %s\n\n\nC  %s\nD  %s",
						bitsetToString(perm.store),
						bitsetToString(pf),
						bitsetToString(pfo)
					);
				size_t idx = 0;
				foreach(it; set) {
					if(it == pf) {
						writeln("Found");
						break;
					}
					++idx;
				}
				writefln("%s\n%s\n%11d %s\n%11d %s\n%11s %s", idx, perm.hasSubSet(set[idx]),
						perm.store, bitsetToString(perm.store), 
						set[idx], bitsetToString(set[idx]),
						" ", bitsetToString(perm.store & set[idx])
					);
				throw new Exception("Foo");
			}
			doNotOptimizeAway(pf);
			doNotOptimizeAway(pfo);
		}
	}
}

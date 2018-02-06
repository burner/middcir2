module testfastsupset;

import exceptionhandling;
import bitsetmodule;
import std.format : format;
import std.stdio;

extern(C) uint fastSubsetFind(uint* ptr, size_t len, uint supSet);
extern(C) ushort fastSubsetFind2(ushort* ptr, size_t len, ushort supSet);

unittest {
	testFastSupset();
}

void testFastSupset() {
	testFastSupset1();
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
	assert((v & arr[p1]) == arr[p1], format("\n%s\n%s", bitsetToString(v),
				bitsetToString(arr[p1])));

	assert(arr.length % 8 != 0);
	for(size_t i = 0; i < arr.length; ++i) {
		uint p = arr[i];
		uint pf = fastSubsetFind(arr.ptr, arr.length, p);
		assert((p & arr[pf]) == arr[pf], format("\n%s\n%s", bitsetToString(v), bitsetToString(p)));
		for(size_t j = 0; j < arr.length; ++j) {
			if(arr[j] == arr[pf]) {
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
			return cast(uint)i;
		} 
	}
	return uint.max;
}

private ushort oldTest(ushort[] array, Bitset!ushort bs) {
	//foreach(uint it; array) {
	//writefln("bs:\n%s", bitsetToString(bs.store));
	for(size_t i = 0; i < array.length; ++i) {
		//writeln(bitsetToString(array[i]));
		if((array[i] & bs.store) == array[i])
		//if(bs.hasSubSet(array[i])) 
		{
			return cast(ushort)i;
		} 
	}
	return ushort.max;
}

void testFastSupset2() {
	import std.random;
	import permutation;
	import std.datetime.stopwatch;
	import randomizedtestbenchmark;

	static assert(Bitset!(ushort).sizeof == 2);

	int l = 10;
	int h = 15;

	auto rnd = Random(1337);
	auto permu = PermutationsImpl!ushort(16, 3, l-1);

	ushort[] set;
	Bitset!(ushort)[] toTest;

	foreach(perm; permu) {
		float f = uniform(0.0, 1.0, rnd);
		if(f > 0.7) {
			set ~= perm.store;
		} else {
			toTest ~= perm;
		}
	}
	writeln(set.length);

	/*{
		auto permu1 = PermutationsImpl!ushort(16, l, h);
		auto sw1 = StopWatch(AutoStart.yes);
		foreach(perm; permu1) {
			ushort pf = fastSubsetFind(set.ptr, set.length, perm.store);
			doNotOptimizeAway(pf);
		}
		sw1.stop();
		writefln("New  %6s milliseconds", sw1.peek().msecs);
	}*/

	{
		auto permu1 = PermutationsImpl!ushort(16, l, h);
		auto sw1 = StopWatch(AutoStart.yes);
		foreach(perm; permu1) {
			ushort pf = fastSubsetFind2(set.ptr, set.length, perm.store);
			doNotOptimizeAway(pf);
		}
		sw1.stop();
		writefln("New2 %6s nanosec", sw1.peek().total!("hnsecs")());
	}

	{
		auto permu1 = PermutationsImpl!ushort(16, l, h);
		auto sw1 = StopWatch(AutoStart.yes);
		foreach(perm; permu1) {
			ushort pf = oldTest(set, perm);
			doNotOptimizeAway(pf);
		}
		sw1.stop();
		writefln("Old  %6s nanosec", sw1.peek().total!("hnsecs")());
	}

	{
		auto permu1 = PermutationsImpl!ushort(16, l, h);
		foreach(perm; permu1) {
			ushort pfo = oldTest(set, perm);
			ushort pf = fastSubsetFind2(set.ptr, set.length, perm.store);
			if(pf != pfo) {
				writefln("\nTF %s\n\n\nC  %s\nD  %s",
						bitsetToString(perm.store),
						bitsetToString(set[pf]),
						bitsetToString(set[pfo])
					);
				size_t idx = 0;
				foreach(it; set) {
					if(it == set[pf]) {
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

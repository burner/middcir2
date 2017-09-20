module testfastsupset;

import exceptionhandling;
import bitsetmodule;
import std.format : format;
import std.stdio;

extern(C) uint fastSubsetFind(uint* ptr, size_t len, uint supSet);

unittest {
	testFastSupset();
	testFastSupset2();
}

void testFastSupset() {
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

void testFastSupset2() {
	import std.random;
	import permutation;

	auto rnd = Random(1337);
	auto permu = PermutationsImpl!uint(31, 6, 14);

	uint[] set;

	foreach(perm; permu) {
		float f = uniform(0.0, 1.0, rnd);
		if(f > 0.7) {
			set ~= perm.store;
		}
	}

	writefln("%s", set.length);
}

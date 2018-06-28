module chessboard;

import protocols;
import bitsetmodule;
import bitsetrbtree;
import std.experimental.logger;

private int[][] hori = [
[0,1,2],
[0,4,5],
[0,4,8],
[3,1,2],
[3,4,5],
[3,4,8],
[6,7,5],
[6,7,8],
[0,1,4,5],
[0,1,4,8],
[0,4,1,2],
[0,4,7,5],
[0,4,7,8],
[3,1,4,5],
[3,1,4,8],
[3,4,1,2],
[3,4,7,5],
[3,4,7,8],
[6,7,4,5],
[6,7,4,8],
[0,1,4,7,5],
[0,1,4,7,8],
[3,1,4,7,5],
[3,1,4,7,8],
[6,7,4,1,2]
];

private int[][] verti = [
[0,3,6],
[0,3,7],
[1,4,6],
[1,4,7],
[2,4,6],
[2,4,7],
[2,5,8],
[0,3,4,7],
[1,4,3,6],
[1,4,3,7],
[1,4,5,8],
[2,4,3,6],
[2,4,3,7],
[2,5,4,7],
[2,4,5,8],
[0,3,4,5,8],
[2,5,4,3,6],
[2,5,4,3,7]
];

void buildRead(Store)(ref Store store) {
	foreach(int[] h; hori) {
		Bitset!ushort perm = bitset!ushort(h);
		auto subsetRead = store.search(perm);
		if(!subsetRead.isNull()) {
			//logf("[%(%s, %)], %s %s", h, perm.toString2(),
			//		(*subsetRead).bitset.toString2());
			(*subsetRead).subsets ~= perm;
		} else {
			store.insert(perm, perm);
		}
	}
}

void buildWrite(Store)(ref Store store) {
	foreach(int[] h; hori) {
		Bitset!ushort hbs = bitset!ushort(h);
		foreach(int[] v; verti) {
			Bitset!ushort vbs = bitset!ushort(v);
			Bitset!ushort perm = hbs;
			perm.store = perm.store | vbs.store;

			auto subsetRead = store.search(perm);
			if(!subsetRead.isNull()) {
				continue;
			} else {
				store.insert(perm, perm);
			}
		}
	}
}

Result calcChessboard() {
	import std.conv : to;
	import std.traits : Unqual;
	import std.stdio : writefln;
	import permutation;
	import config;

	alias BitsetType = ushort;
	alias BSType = TypeFromSize!16;

	BitsetStore!BSType read;
	buildRead(read);
	BitsetStore!BSType write;
	buildWrite(write);

	alias BitsetStoreType = typeof(read);

	auto permu = PermutationsImpl!BitsetType(9, 3, 10);
	auto last = 0;
	foreach(perm; permu) {
		auto subsetRead = read.search(perm);
		if(!subsetRead.isNull()) {
			(*subsetRead).subsets ~= perm;

		}
		auto subsetWrite = write.search(perm);
		if(!subsetWrite.isNull()) {
			(*subsetWrite).subsets ~= perm;
		}
	}
	//logf("andBreak %s andWrite %s", andBreak, andWrite);
	read.toFile();
	write.toFile();

	auto tmpRet = calcAvailForTree!BitsetStoreType(to!int(9), read, write);
	//logf("after calcAvail");
	return tmpRet;
}

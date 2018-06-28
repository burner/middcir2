module chessboard;

import protocols;
import bitsetmodule;
import bitsetrbtree;
import graph;
import floydmodule;
import gfm.math.vector;
import std.stdio;
import std.array : array;
import std.experimental.logger;
import std.container.array;
import std.algorithm.searching : canFind;

/*private int[][] hori = [
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
];*/

void buildRead(Store)(ref Store store, int[][] vert, int[][] hori) {
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
	foreach(int[] h; vert) {
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

void buildWrite(Store)(ref Store store, int[][] horiAndVert) {
	foreach(int[] h; horiAndVert) {
		Bitset!ushort perm = bitset!ushort(h);
		auto subsetRead = store.search(perm);
		if(!subsetRead.isNull()) {
			logf("%s %s", perm.toString2(), (*subsetRead).bitset.toString2());
			continue;
		} else {
			store.insert(perm, perm);
		}
	}
}

Graph!16 straightGraph() {
	auto ret = Graph!16(9);
	ret.setNodePos(6, vec3d(0.0, 0.0, 0.0));
	ret.setNodePos(7, vec3d(1.0, 0.0, 0.0));
	ret.setNodePos(8, vec3d(2.0, 0.0, 0.0));

	ret.setNodePos(3, vec3d(0.0, 1.0, 0.0));
	ret.setNodePos(4, vec3d(1.0, 1.0, 0.0));
	ret.setNodePos(5, vec3d(2.0, 1.0, 0.0));

	ret.setNodePos(0, vec3d(0.0, 2.0, 0.0));
	ret.setNodePos(1, vec3d(1.0, 2.0, 0.0));
	ret.setNodePos(2, vec3d(2.0, 2.0, 0.0));

	ret.setEdge(0, 1);
	ret.setEdge(0, 4);
	ret.setEdge(1, 2);
	ret.setEdge(1, 4);
	ret.setEdge(1, 3);
	ret.setEdge(3, 4);
	ret.setEdge(4, 5);
	ret.setEdge(4, 7);
	ret.setEdge(6, 7);
	ret.setEdge(4, 8);
	ret.setEdge(7, 8);
	ret.setEdge(7, 5);

	return ret;
}

Graph!16 dottedGraph() {
	auto ret = Graph!16(9);
	ret.setNodePos(6, vec3d(0.0, 0.0, 0.0));
	ret.setNodePos(7, vec3d(1.0, 0.0, 0.0));
	ret.setNodePos(8, vec3d(2.0, 0.0, 0.0));

	ret.setNodePos(3, vec3d(0.0, 1.0, 0.0));
	ret.setNodePos(4, vec3d(1.0, 1.0, 0.0));
	ret.setNodePos(5, vec3d(2.0, 1.0, 0.0));

	ret.setNodePos(0, vec3d(0.0, 2.0, 0.0));
	ret.setNodePos(1, vec3d(1.0, 2.0, 0.0));
	ret.setNodePos(2, vec3d(2.0, 2.0, 0.0));

	ret.setEdge(0, 3);
	ret.setEdge(1, 4);
	ret.setEdge(1, 5);
	ret.setEdge(2, 5);
	ret.setEdge(3, 4);
	ret.setEdge(3, 6);
	ret.setEdge(3, 7);
	ret.setEdge(4, 5);
	ret.setEdge(4, 6);
	ret.setEdge(4, 2);
	ret.setEdge(4, 7);
	ret.setEdge(5, 8);

	return ret;
}

int[][] horiAndVert(int[][] hori, int[][] vert) {
	int[][] ret;
	foreach(int[] h; hori) {
		Bitset!ushort hbs = bitset!ushort(h);
		inner: foreach(int[] v; vert) {
			Bitset!ushort vbs = bitset!ushort(v);
			Bitset!ushort perm = hbs;
			perm.store = perm.store | vbs.store;
			auto t = toIntArray(perm);
			foreach(it; ret) {
				if(t == it) {
					continue inner;
				}
			}
			ret ~= t;
		}
	}
	return ret;
}

int[][] horizontalPaths(ref Graph!16 straight) {
	int[][] ret;
	auto f = floyd(straight);
	f.execute(straight);
	foreach(l; [0,3,6]) {
		foreach(r; [2,5,8]) {
			Array!int app;
			if(f.path(l, r, app)) {
				ret ~= app[].array;
			}
		}
	}
	return ret;
}

int[][] verticalPaths(ref Graph!16 dotted) {
	int[][] ret;
	auto f = floyd(dotted);
	f.execute(dotted);
	foreach(l; [0,1,2]) {
		foreach(r; [6,7,8]) {
			Array!int app;
			if(f.path(l, r, app)) {
				ret ~= app[].array;
			}
		}
	}
	return ret;
}

Bitset!(BST)[] intArrArrToBS(BST)(int[][] arr) {
	Bitset!(BST)[] ret;
	foreach(it; arr) {
		ret ~= bitset!BST(it);
	}
	return ret;
}

Result calcChessboard() {
	import std.conv : to;
	import std.traits : Unqual;
	import std.stdio : writefln;
	import permutation;
	import config;

	alias BitsetType = ushort;
	alias BSType = TypeFromSize!16;

	auto dotted = dottedGraph();
	{
		auto f = File("Results/Chessboard/dotted.tex", "w");
		auto ltw = f.lockingTextWriter();
		dotted.toTikz(ltw);
	}

	auto straight = straightGraph();
	{
		auto f = File("Results/Chessboard/straight.tex", "w");
		auto ltw = f.lockingTextWriter();
		straight.toTikz(ltw);
	}

	int[][] vert = verticalPaths(dotted);
	int[][] hori = horizontalPaths(straight);
	int[][] hav = horiAndVert(hori, vert);

	Bitset!(BitsetType)[] vertBS = intArrArrToBS!BSType(vert);
	Bitset!(BitsetType)[] horiBS = intArrArrToBS!BSType(hori);
	Bitset!(BitsetType)[] havBS = intArrArrToBS!BSType(hav);

	BitsetStore!BSType read;
	//buildRead(read, vert, hori);
	BitsetStore!BSType write;
	//buildWrite(write, hav);
	//writefln("vert\n%(%s\n%)", vert);
	//writefln("vert\n%(%s\n%)", vertBS);
	//writefln("hori\n%(%s\n%)", hori);
	//writefln("hori\n%(%s\n%)", horiBS);
	//writefln("hav\n%(%s\n%)", hav);
	//writefln("hav\n%(%s\n%)", havBS);

	alias BitsetStoreType = typeof(read);

	auto permu = PermutationsImpl!BitsetType(9, 3, 10);
	auto last = 0;
	foreach(perm; permu) {
		if(canFind(vertBS, perm) || canFind(horiBS, perm)) {
			read.insert(perm, perm);
		} else {
			auto subsetRead = read.search(perm);
			if(!subsetRead.isNull()) {
				(*subsetRead).subsets ~= perm;

			}
		}
		if(canFind(havBS, perm)) {
			write.insert(perm, perm);
		} else {
			auto subsetWrite = write.search(perm);
			if(!subsetWrite.isNull()) {
				(*subsetWrite).subsets ~= perm;
			}
		}
	}
	writeln(read);
	writeln(write);
	//logf("andBreak %s andWrite %s", andBreak, andWrite);

	auto tmpRet = calcAvailForTree!BitsetStoreType(to!int(9), read, write);
	//logf("after calcAvail");
	return tmpRet;
}

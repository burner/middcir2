module protocols.pathbased;

import core.bitop : popcnt;

import std.typecons : Flag;
import std.container.array : Array;
import std.experimental.logger;

import protocols;
import bitsetrbtree;
import graph;
import bitsetmodule;
import floydmodule;
import utils;

alias ValidPath = Flag!"ValidPath";

struct PathResult {
	Bitset!uint minPath;
	ValidPath validPath;
}

PathResult selectReadQuorum(ref const(Array!(Bitset!uint)) vert,
		ref const(Array!(Bitset!uint)) hori, ref const(Array!(Bitset!uint)) diagonal)
{
	auto ret = PathResult(bitsetAll!uint(), ValidPath.no);

	foreach(it; vert) {
		if(popcnt(it.store) < popcnt(ret.minPath.store)) {
			ret.minPath = it;
			ret.validPath = ValidPath.yes;
		}
	}

	foreach(it; hori) {
		if(popcnt(it.store) < popcnt(ret.minPath.store)) {
			ret.minPath = it;
			ret.validPath = ValidPath.yes;
		}
	}

	foreach(it; diagonal) {
		if(popcnt(it.store) < popcnt(ret.minPath.store)) {
			ret.minPath = it;
			ret.validPath = ValidPath.yes;
		}
	}

	return ret;
}

PathResult selectWriteQuorum(ref const(Array!(Bitset!uint)) vert,
		ref const(Array!(Bitset!uint)) hori, ref const(Array!(Bitset!uint)) diagonal)
{
	auto ret = PathResult(bitsetAll!uint(), ValidPath.no);

	foreach(it; vert) {
		foreach(jt; hori) {
			auto join = bitset!uint(it.store | jt.store);
			if(popcnt(join.store) < popcnt(ret.minPath.store)) {
				ret.minPath = join;
				ret.validPath = ValidPath.yes;
			}
		}
	}

	foreach(it; diagonal) {
		if(popcnt(it.store) < popcnt(ret.minPath.store)) {
			ret.minPath = it;
			ret.validPath = ValidPath.yes;
		}
	}

	return ret;
}

void testPathsBetween(ref const(Floyd) paths, ref const(Array!int) a, 
		ref const(Array!int) b, ref Array!(Bitset!uint) rslt, 
		ref Array!uint tmpPathStore)
{
	for(uint ai = 0; ai < a.length; ++ai) {
		for(uint bi = 0; bi < b.length; ++bi) {
			tmpPathStore.removeAll();
			if(paths.path(a[ai], b[bi], tmpPathStore)) {
				//logf("%s %s \"%(%s, %)\"", a[ai], b[bi], tmpPathStore[]);
				rslt.insertBack(bitset!uint(tmpPathStore));
			}
		}
	}

}

PathResult testDiagonal(ref const(Floyd) paths, const int bl,
		const int tr, ref Array!uint tmpPathStore)
{
	auto ret = PathResult(bitsetAll!uint(), ValidPath.no);

	tmpPathStore.removeAll();
	if(paths.path(bl, tr, tmpPathStore)) {
		ret.minPath = bitset!uint(tmpPathStore);
		ret.validPath = ValidPath.yes;
	}

	return ret;
}

Result calcACforPathBased(ref Floyd paths, ref const(Graph!32) graph, 
		const(Array!int) bottom, const(Array!int) top, const(Array!int) left, 
		const(Array!int) right, const(Array!(int[2])) diagonalPairs, 
		ref BitsetStore!uint read, ref BitsetStore!uint write, const uint upto)
{
	import std.conv : to;
	Array!uint tmpPathStore;

	Array!(Bitset!uint) verticalPaths;
	Array!(Bitset!uint) horizontalPaths;
	Array!(Bitset!uint) diagonalPaths;

	for(uint perm = 0; perm < upto; ++perm) {
		paths.execute(graph, bitset(perm));
		//writefln("%4d, %s", perm, paths);

		verticalPaths.removeAll();
		horizontalPaths.removeAll();
		diagonalPaths.removeAll();

		testPathsBetween(paths, top, bottom, verticalPaths, tmpPathStore);	
		testPathsBetween(paths, left, right, horizontalPaths, tmpPathStore);	
		//writefln("%(%s %)", verticalPaths[]);
		//writefln("%(%s %)", horizontalPaths[]);

		foreach(ref int[2] diagonalPair; diagonalPairs) {
			PathResult dia = testDiagonal(paths, diagonalPair[0],
					diagonalPair[1], tmpPathStore
			);

			if(dia.validPath == ValidPath.yes) {
				diagonalPaths.insertBack(dia.minPath);
			}
		}

		PathResult readQuorum = selectReadQuorum(verticalPaths,
				horizontalPaths, diagonalPaths
		);
		PathResult writeQuorum = selectWriteQuorum(verticalPaths,
				horizontalPaths, diagonalPaths
		);

		if(readQuorum.validPath == ValidPath.yes) {
			//writefln("read  %b %b", readQuorum.minPath.store, perm);
			read.insert(readQuorum.minPath, bitset!uint(perm));
		}

		if(writeQuorum.validPath == ValidPath.yes) {
			//writefln("write %b %b", writeQuorum.minPath.store, perm);
			write.insert(writeQuorum.minPath, bitset!uint(perm));
		}
	}

	logf("%s", upto);
	return calcAvailForTree(to!int(upto), read, write);
}

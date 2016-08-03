module protocols.pathbased;

import core.bitop : popcnt;

import std.typecons : Flag;
import std.container.array : Array;

import bitsetmodule;
import floydmodule;
import utils;

alias ValidPath = Flag!"ValidPath";

struct PathResult {
	Bitset!uint minPath;
	ValidPath validPath;
}

static PathResult selectReadQuorum(ref const(Array!(Bitset!uint)) vert,
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

static PathResult selectWriteQuorum(ref const(Array!(Bitset!uint)) vert,
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

static void testPathsBetween(ref const(Floyd) paths, ref const(Array!int) a, 
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

static PathResult testDiagonal(ref const(Floyd) paths, const int bl,
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

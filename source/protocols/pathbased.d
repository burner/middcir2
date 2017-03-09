module protocols.pathbased;

//import core.bitop : popcnt;

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

struct PathResult(BitsetType) {
	Bitset!(BitsetType) minPath;
	ValidPath validPath;
}

PathResult!BitsetType selectReadQuorum(BitsetType)(ref const(Array!(Bitset!BitsetType)) vert,
		ref const(Array!(Bitset!BitsetType)) hori, ref const(Array!(Bitset!BitsetType)) diagonal)
{
	auto ret = PathResult!BitsetType(bitsetAll!BitsetType(), ValidPath.no);

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

PathResult!BitsetType selectWriteQuorum(BitsetType)(ref const(Array!(Bitset!BitsetType)) vert,
		ref const(Array!(Bitset!BitsetType)) hori, ref const(Array!(Bitset!BitsetType)) diagonal)
{
	auto ret = PathResult!BitsetType(bitsetAll!BitsetType(), ValidPath.no);

	foreach(it; vert) {
		foreach(jt; hori) {
			auto join = bitset!BitsetType(it.store | jt.store);
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

void testPathsBetween(BitsetType,F)(ref const(F) paths, ref const(Array!int) a, 
		ref const(Array!int) b, ref Array!(Bitset!BitsetType) rslt, 
		ref Array!BitsetType tmpPathStore)
{
	for(uint ai = 0; ai < a.length; ++ai) {
		for(uint bi = 0; bi < b.length; ++bi) {
			tmpPathStore.removeAll();
			if(paths.path(a[ai], b[bi], tmpPathStore)) {
				//logf("%s %s \"%(%s, %)\"", a[ai], b[bi], tmpPathStore[]);
				rslt.insertBack(bitset!BitsetType(tmpPathStore));
			}
		}
	}

}

PathResult!BitsetType testDiagonal(BitsetType,F)(ref const(F) paths, const int bl,
		const int tr, ref Array!BitsetType tmpPathStore)
{
	auto ret = PathResult!BitsetType(bitsetAll!BitsetType(), ValidPath.no);

	tmpPathStore.removeAll();
	if(paths.path(bl, tr, tmpPathStore)) {
		ret.minPath = bitset!BitsetType(tmpPathStore);
		ret.validPath = ValidPath.yes;
	}

	return ret;
}

void testEmptyIntersection(ref const(Array!int) a, ref const(Array!int) b) {
	import std.format : format;
	foreach(it; a[]) {
		foreach(jt; b[]) {
			if(it == jt) {
				throw new Exception(
						format("a and b both hold element %d", it)
				);
			}
		}
	}
}

void testEmptyIntersection(ref const(Array!(int[2])) a) {
	import std.format : format;
	foreach(it; a[]) {
		if(it[0] == it[1]) {
			throw new Exception(
					format("a has element where both subelements are %d", it[0])
			);
		}
	}
}

Result calcACforPathBasedFast(BitsetType,F,G)(ref F paths, ref const(G) graph, 
		const(Array!int) bottom, const(Array!int) top, const(Array!int) left, 
		const(Array!int) right, const(Array!(int[2])) diagonalPairs, 
		ref BitsetStore!BitsetType read, ref BitsetStore!BitsetType write,
		const uint numNodes)
{
	import std.conv : to;
	import std.stdio : writefln;
	import permutation;
	import config;

	Array!BitsetType tmpPathStore;

	Array!(Bitset!BitsetType) verticalPaths;
	Array!(Bitset!BitsetType) horizontalPaths;
	Array!(Bitset!BitsetType) diagonalPaths;

	auto permu = PermutationsImpl!BitsetType(
		numNodes,
		getConfig().permutationStart(),
		getConfig().permutationStop(numNodes)
	);
	foreach(perm; permu) {
		//logf("%s %s", permu.numNodes, perm);
		auto subsetRead = read.search(perm);
		if(!subsetRead.isNull()) {
			(*subsetRead).subsets ~= perm;
		}
		auto subsetWrite = write.search(perm);
		if(!subsetWrite.isNull()) {
			(*subsetWrite).subsets ~= perm;
		}

		if(!subsetRead.isNull() && !subsetWrite.isNull()) {
			continue;
		}

		paths.execute(graph, perm);

		verticalPaths.removeAll();
		horizontalPaths.removeAll();
		diagonalPaths.removeAll();

		testPathsBetween!BitsetType(paths, top, bottom, verticalPaths, 
			tmpPathStore);	
		testPathsBetween!BitsetType(paths, left, right, horizontalPaths, 
			tmpPathStore);	

		foreach(ref int[2] diagonalPair; diagonalPairs) {
			PathResult!BitsetType dia = testDiagonal!BitsetType(paths, 
				diagonalPair[0], diagonalPair[1], tmpPathStore
			);

			if(dia.validPath == ValidPath.yes) {
				diagonalPaths.insertBack(dia.minPath);
			}
		}

		if(subsetRead.isNull()) {
			PathResult!BitsetType readQuorum = selectReadQuorum!BitsetType(
					verticalPaths, horizontalPaths, diagonalPaths
			);

			if(readQuorum.validPath == ValidPath.yes) {
				read.insert(readQuorum.minPath, perm);
			}
		}

		if(subsetWrite.isNull()) {
			PathResult!BitsetType writeQuorum = selectWriteQuorum!BitsetType(
					verticalPaths, horizontalPaths, diagonalPaths
			);

			if(writeQuorum.validPath == ValidPath.yes) {
				write.insert(writeQuorum.minPath, perm);
			}
		}
	}

	return calcAvailForTree!BitsetType(to!int(numNodes), read, write);
}

Result calcACforPathBased(BitsetType,F,G)(ref F paths, ref const(G) graph, 
		const(Array!int) bottom, const(Array!int) top, const(Array!int) left, 
		const(Array!int) right, const(Array!(int[2])) diagonalPairs, 
		ref BitsetStore!BitsetType read, ref BitsetStore!BitsetType write, const uint numNodes)
{
	import std.conv : to;
	import std.stdio : writefln;
	import permutation;
	import config;

	Array!BitsetType tmpPathStore;

	Array!(Bitset!BitsetType) verticalPaths;
	Array!(Bitset!BitsetType) horizontalPaths;
	Array!(Bitset!BitsetType) diagonalPaths;

	auto permu = PermutationsImpl!BitsetType(
		numNodes,
		getConfig().permutationStart(),
		getConfig().permutationStop(numNodes)
	);
	//auto permu = PermutationsImpl!BitsetType(numNodes);
	foreach(perm; permu) {
		//logf("%s %s", permu.numNodes, perm);
		paths.execute(graph, perm);

		verticalPaths.removeAll();
		horizontalPaths.removeAll();
		diagonalPaths.removeAll();

		testPathsBetween!BitsetType(paths, top, bottom, verticalPaths, 
			tmpPathStore);	
		testPathsBetween!BitsetType(paths, left, right, horizontalPaths, 
			tmpPathStore);	

		foreach(ref int[2] diagonalPair; diagonalPairs) {
			PathResult!BitsetType dia = testDiagonal!BitsetType(paths, 
				diagonalPair[0], diagonalPair[1], tmpPathStore
			);

			if(dia.validPath == ValidPath.yes) {
				diagonalPaths.insertBack(dia.minPath);
			}
		}

		PathResult!BitsetType readQuorum = selectReadQuorum!BitsetType(
				verticalPaths, horizontalPaths, diagonalPaths
		);
		PathResult!BitsetType writeQuorum = selectWriteQuorum!BitsetType(
				verticalPaths, horizontalPaths, diagonalPaths
		);

		if(readQuorum.validPath == ValidPath.yes) {
			read.insert(readQuorum.minPath, perm);
		}

		if(writeQuorum.validPath == ValidPath.yes) {
			write.insert(writeQuorum.minPath, perm);
		}
	}

	return calcAvailForTree!BitsetType(to!int(numNodes), read, write);
}

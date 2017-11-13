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

PathResult!BitsetType selectReadQuorum(BitsetType)(
		ref const(Array!(Bitset!BitsetType)) vert,
		ref const(Array!(Bitset!BitsetType)) hori, 
		ref const(Array!(Bitset!BitsetType)) diagonal)
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

PathResult!BitsetType selectWriteQuorum(BitsetType)(
		ref const(Array!(Bitset!BitsetType)) vert,
		ref const(Array!(Bitset!BitsetType)) hori, 
		ref const(Array!(Bitset!BitsetType)) diagonal)
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

/*bool isNullTest(BitsetStoreType,T)(ref T t) {
	import std.traits : Unqual;
	static if(is(Unqual!BitsetStoreType == BitsetArrayFlat!uint)
				|| is(Unqual!BitsetStoreType == BitsetArrayFlat!ushort)
				|| is(Unqual!BitsetStoreType == BitsetArrayFlat!ulong)) 
	{
		return t == T.max;
	} else {
		return t.isNull;
	}
}

void append(BitsetStoreType,T,A)(ref BitsetStoreType bst, ref T t, A a) {
	import std.traits : Unqual;
	static if(is(Unqual!BitsetStoreType == BitsetArrayFlat!uint)
				|| is(Unqual!BitsetStoreType == BitsetArrayFlat!ushort)
				|| is(Unqual!BitsetStoreType == BitsetArrayFlat!ulong)) 
	{
		logf("%s %s", bst.keys[t].store, bst.superSets.length);
		bst.superSets[bst.keys[t].store] ~= a;
	} else {
		(*t).subsets ~= a;
	}
}*/

Result calcACforPathBasedFast(BitsetStoreType,BitsetType,F,G)(ref F paths, 
		ref const(G) graph, const(Array!int) bottom, const(Array!int) top,
		const(Array!int) left, const(Array!int) right,
	   	const(Array!(int[2])) diagonalPairs, ref BitsetStoreType read, 
		ref BitsetStoreType write, const uint numNodes)
{
	import std.conv : to;
	import std.traits : Unqual;
	import std.stdio : writefln;
	import permutation;
	import config;

	Array!BitsetType tmpPathStore;

	Array!(Bitset!BitsetType) verticalPaths;
	Array!(Bitset!BitsetType) horizontalPaths;
	Array!(Bitset!BitsetType) diagonalPaths;

	Bitset!BitsetType topTest = bitset!BitsetType(top);
	Bitset!BitsetType bottomTest = bitset!BitsetType(bottom);
	Bitset!BitsetType leftTest = bitset!BitsetType(left);
	Bitset!BitsetType rightTest = bitset!BitsetType(right);
	size_t andBreak;
	size_t andWrite;

	auto permu = PermutationsImpl!BitsetType(
		numNodes,
		getConfig().permutationStart(),
		getConfig().permutationStop(numNodes)
	);
	auto last = 0;
	foreach(perm; permu) {
		auto cur = popcnt(perm.store);
		/*static if(is(Unqual!BitsetStoreType == BitsetArrayArrayRC!uint)
				|| is(Unqual!BitsetStoreType == BitsetArrayArrayRC!ushort)
				|| is(Unqual!BitsetStoreType == BitsetArrayArrayRC!ulong)) 
		{
			if(cur > last+2) {
				logf("to file %s", cur);
				read.toFile();
				write.toFile();
				foreach(ref it; read[]) {
					assert(it.subsets.length == 0);
				}
				foreach(ref it; write[]) {
					assert(it.subsets.length == 0);
				}
				last = cur;
			}
		}*/
		//logf("%s %s", permu.numNodes, graph.length);
		bool tPossible = (topTest.store & perm.store) != 0;
		bool bPossible = (bottomTest.store & perm.store) != 0;
		bool lPossible = (leftTest.store & perm.store) != 0;
		bool rPossible = (rightTest.store & perm.store) != 0;

		bool vPossible = tPossible && bPossible;
		bool hPossible = lPossible && rPossible;

		if(!vPossible && !hPossible) {
			++andBreak;
			continue;
		}

		auto subsetRead = read.search(perm);
		if(!subsetRead.isNull()) {
		//if(!isNullTest!(BitsetStoreType)(subsetRead)) {
			//logf("%s", perm);
			(*subsetRead).subsets ~= perm;
			//append(read, subsetRead, perm);

		}
		auto subsetWrite = write.search(perm);
		if(!subsetWrite.isNull()) {
		//if(!isNullTest!(BitsetStoreType)(subsetWrite)) {
			//logf("%s", perm);
			(*subsetWrite).subsets ~= perm;
			//append(write, subsetWrite, perm);
		}

		if(!subsetRead.isNull() && !subsetWrite.isNull()) {
		//if(!isNullTest!(BitsetStoreType)(subsetRead)
				//&& !isNullTest!(BitsetStoreType)(subsetWrite))
		//{
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
		//if(isNullTest!BitsetStoreType(subsetRead)) {
			PathResult!BitsetType readQuorum = selectReadQuorum!BitsetType(
					verticalPaths, horizontalPaths, diagonalPaths
			);

			if(readQuorum.validPath == ValidPath.yes) {
				read.insert(readQuorum.minPath, perm);
			}
		}

		if(!vPossible || !hPossible) {
			++andWrite;
		}
		if(subsetWrite.isNull() && vPossible && hPossible) {
		//if(isNullTest!BitsetStoreType(subsetWrite) && vPossible && hPossible) {
			PathResult!BitsetType writeQuorum = selectWriteQuorum!BitsetType(
					verticalPaths, horizontalPaths, diagonalPaths
			);

			if(writeQuorum.validPath == ValidPath.yes) {
				write.insert(writeQuorum.minPath, perm);
			}
		}
	}
	//logf("andBreak %s andWrite %s", andBreak, andWrite);
	read.toFile();
	write.toFile();

	auto tmpRet = calcAvailForTree!BitsetStoreType(to!int(numNodes), read, write);
	//logf("after calcAvail");
	return tmpRet;
}

Result calcACforPathBased(BitsetStoreType,BitsetType,F,G)(ref F paths, 
		ref const(G) graph, const(Array!int) bottom, const(Array!int) top, 
		const(Array!int) left, const(Array!int) right, 
		const(Array!(int[2])) diagonalPairs, ref BitsetStoreType read, 
		ref BitsetStoreType write, const uint numNodes)
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

	return calcAvailForTree!BitsetStoreType(to!int(numNodes), read, write);
}

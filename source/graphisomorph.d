module graphisomorph;

import graph;
import fixedsizearray;

void fillStores(int Size)(ref FixedSizeArray!(byte, 32)[32] store, 
		const Graph!Size g)
{
	for(size_t i = 0; i < g.length; ++i) {
		store[g.nodes[i].count()].insertBack(cast(byte)i);
	}
}

/** If aStores and bStores do not have the same amount of elements A and B can
  not be isomorph.
*/
bool testIsomorphPossibility(ref const(FixedSizeArray!(byte, 32)[32]) aStores,
		ref const(FixedSizeArray!(byte, 32)[32]) bStores)
{
	for(size_t i = 0; i < 32; ++i) {
		if(aStores[i].length != bStores[i].length) {
			return false;
		}
	}
	return true;
}

bool areGraphsIsomorph(int Size)(const Graph!Size a, const Graph!Size b) {
	import std.algorithm : nextPermutation;
	import std.stdio;
	import fixedsizearray;

	if(a.length != b.length) {
		//writeln("LEN");
		return false;
	}

	FixedSizeArray!(byte, 32)[32] aStores;
	FixedSizeArray!(byte, 32)[32] bStores;

	fillStores(aStores, a);
	fillStores(aStores, a);

	if(testIsomorphPossibility(aStores, bStores)) {
		//writeln("INDIVIDUAL LEN");
		return false;
	}

	FixedSizeArray!(byte,32) perm;
	for(byte i = 0; i < a.length; ++i) {
		perm.insertBack(i);
	}

	do {
		//writefln("%(%2d %)", perm[]);
		// cur permutation of A must have equal length elements to B
		size_t idx = 0;
		inner: foreach(it; perm[]) {
			// A and B must have the same number of edges
			if(a.nodes[it].count() != b.nodes[idx].count()) {
				//writefln("NODE COUNT");
				goto next;
			}

			// The edges of A and B must point to the same vertex when using
			// perm
			size_t lowIdx = a.nodes[it].lowestBit();
			while(lowIdx != size_t.max) {
				if(!b.nodes[idx].test(perm[lowIdx])) {
					//writefln("NODE FAIL");
					goto next;
				}
				lowIdx = a.nodes[it].lowestBit(cast(size_t)(lowIdx + 1UL));
			}
			++idx;
		}
		return true;
		next:
	} while(nextPermutation(perm[]));

	return false;
}

unittest {
	auto six = makeSix!16();
	assert(areGraphsIsomorph(six, six));	

	auto nine = makeNine!16();
	assert(!areGraphsIsomorph(six, nine));	
	assert(areGraphsIsomorph(nine, nine));	
}

unittest {
	auto a = Graph!16(6);
	a.setEdge(0,5);
	a.setEdge(0,4);
	a.setEdge(1,4);
	a.setEdge(2,3);

	// 0 1 5 3 4 2
	// 0 1 2 3 4 5
	auto b = Graph!16(6);
	b.setEdge(0,2);
	b.setEdge(0,4);
	b.setEdge(1,4);
	b.setEdge(5,3);

	assert(areGraphsIsomorph(a, b));
}

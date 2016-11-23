module graphisomorph;

import graph;
import fixedsizearray;

void fillStores(int Size)(ref FixedSizeArray!(byte, 32)[32] store, 
		const Graph!Size g)
{
	for(size_t i = 0; i < g.length; ++i) {
		store[g[i].count()].insertBack(cast(byte)i);
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
	import fixedsizearray;

	if(a.length != b.length) {
		return false;
	}

	FixedSizeArray!(byte, 32)[32] aStores;
	FixedSizeArray!(byte, 32)[32] bStores;

	fillStores(aStores, a);
	fillStores(aStores, a);

	if(!testIsomorphPossibility(aStores, bStores)) {
		return false;
	}

	FixedSizeArray!(byte,32) perm;
	for(byte i = 0; i < this.length; ++i) {
		perm.insertBack(i);
	}

	do {
		// cur permutation of A must have equal length elements to B
		size_t idx = 0;
		inner: foreach(it; perm[]) {
			// A and B must have the same number of edges
			if(a.nodes[it].count() != b[idx].count()) {
				goto next;
			}

			// The edges of A and B must point to the same vertex when using
			// perm
			size_t lowIdx = a.nodes[it].lowestBit();
			while(lowIdx != size_t.max) {
				if(!b[idx].test(perm[lowIdx])) {
					goto next;
				}
				lowIdx = a.nodes[it].lowestBit(lowIdx + 1UL);
			}
		}
		return true;
		next:
	} while(nextPermutation(perm[]));

	return false;
}

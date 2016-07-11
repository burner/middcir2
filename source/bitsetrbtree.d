module bitsetrbtree;

import rbtree;
import bitset;

bool bitsetLess(T)(const BitsetArray!T l, const BitsetArray!T r) {
	return l.bs.store < r.bs.store;
}

bool bitsetEqual(T)(const BitsetArray!T l, const BitsetArray!T r) {
	return r.bs.hasSubSet(r.bs);
}

struct BitsetArray(T) {
	Bitset!T bs;
	Bitset!(T)[] subsets;
}

alias BitsetRBTree(T) = RBTree!(BitsetArray!T, bitsetLess!T, bitsetEqual!T);

unittest {
	BitsetRBTree!ushort t;
}

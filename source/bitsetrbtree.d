module bitsetrbtree;

import rbtree;
import bitsetmodule;
import std.typecons : isIntegral;

bool bitsetLess(T)(const BitsetArray!T l, const BitsetArray!T r) {
	return l.bitset.store < r.bitset.store;
}

bool bitsetEqual(T)(const BitsetArray!T l, const BitsetArray!T r) {
	return r.bitset.hasSubSet(l.bitset);
}

struct BitsetArray(T) {
	Bitset!T bitset;
	Bitset!(T)[] subsets;

	this(T value) {
		this(Bitset!T(value));
	}

	this(Bitset!T value) {
		this.bitset = value;
		this.subsets.reserve(32);
	}

	void toString(scope void delegate(const(char)[]) sink) const {
		import std.format : formattedWrite;
		formattedWrite(sink, "%b [%(%s %)]", this.bitset.store, this.subsets);
	}
}

BitsetArray!T bitsetArray(T)(T t) if(isIntegral!T) {
	return BitsetArray!T(bitset(t));
}

BitsetArray!(T.StoreType) bitsetArray(T)(T t) if(!isIntegral!T) {
	return BitsetArray!(T.StoreType)(t);
}

alias BitsetRBTree(T) = RBTree!(BitsetArray!T, bitsetLess!T, bitsetEqual!T);

unittest {
	import std.stdio : writeln;
	BitsetRBTree!ushort t;
	auto a = Bitset!(ushort)(cast(ushort)(0b0000_1111_0000_1111));
	auto abs = bitsetArray(a);
	t.insert(abs);

	auto it = t.search(abs);
	assert(it !is null);
	
	auto b = Bitset!(ushort)(cast(ushort)(0b0000_1111_0110_1111));
	assert(b.hasSubSet(it.getData().bitset));

	auto c = Bitset!(ushort)(cast(ushort)(0b0000_1111_0000_1101));
	assert(!c.hasSubSet(it.getData().bitset));

	(*it).subsets ~= b;

	auto it2 = t.search(abs);
	assert(it2 !is null);
	assert((*it2).subsets.length == 1);
	assert((*it2).subsets[0] == b);

	t.insert(BitsetArray!(ushort)(c));
	assert(t.length == 2);

	auto d = Bitset!(ushort)(cast(ushort)(0b0000_1111_1111_1111));
	t.insert(bitsetArray(c));
	writeln(t.toString());
}

module bitsetrbtree;

import rbtree;
import bitsetmodule;
import std.typecons : isIntegral, Nullable;

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
		//this.subsets.reserve(32);
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

//alias BitsetRBTree(T) = RBTree!(BitsetArray!T, bitsetLess!T, bitsetEqual!T);

struct BitsetRBTree(T) {
	RBTree!(BitsetArray!T, bitsetLess!T, bitsetEqual!T) tree;

	void insert(T t) {
		auto bs = Bitset!T(t);
		this.insert(bs);
	}

	void insert(Bitset!T bs) {
		auto bsa = bitsetArray(bs);
		auto it = this.tree.search(bsa);
		if(it !is null) {
			(*it).subsets ~= bs;
		} else {
			this.tree.insert(bsa);
		}
	}

	Nullable!(BitsetArray!(T)*) search(Bitset!T bs) {
		auto a = bitsetArray(bs);
		auto tmp = this.tree.search(a);
		if(tmp !is null) {
			return Nullable!(BitsetArray!(T)*)(&tmp.getData());
		} else {
			return Nullable!(BitsetArray!(T)*).init;
		}
	}

	@property size_t length() const {
		return this.tree.length;
	}

	string toString() const {
		return this.tree.toString();
	}	
}

unittest {
	import std.stdio : writeln;
	BitsetRBTree!ushort tree;
	auto a = Bitset!(ushort)(cast(ushort)(0b0000_1111_0000_1111));
	tree.insert(a);

	auto it = tree.search(a);
	assert(!it.isNull());
	
	auto b = Bitset!(ushort)(cast(ushort)(0b0000_1111_0110_1111));
	assert(b.hasSubSet(it.get().bitset));

	auto c = Bitset!(ushort)(cast(ushort)(0b0000_1111_0000_1101));
	assert(!c.hasSubSet(it.get().bitset));

	it.get().subsets ~= b;

	auto it2 = tree.search(a);
	assert(it2 !is null);
	assert((*it2).subsets.length == 1);
	assert((*it2).subsets[0] == b);

	tree.insert(c);
	assert(tree.length == 2);

	auto d = Bitset!(ushort)(cast(ushort)(0b0000_1111_1111_1111));
	tree.insert(d);
	writeln(tree.toString());
}

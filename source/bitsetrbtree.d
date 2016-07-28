module bitsetrbtree;

import std.container.array : Array;
import std.typecons : isIntegral, Nullable;

import rbtree;
import bitsetmodule;

alias BitsetStore(T) = BitsetArrayArray!(T);
//alias BitsetStore(T) = BitsetRBTree!(T); TODO: This seams to be incorrect

bool bitsetLess(T)(const BitsetArray!T l, const BitsetArray!T r) {
	return l.bitset.store < r.bitset.store;
}

bool bitsetEqual(T)(const BitsetArray!T l, const BitsetArray!T r) {
	return r.bitset.hasSubSet(l.bitset);
}

struct BitsetArray(T) {
	Bitset!T bitset;
	Array!(Bitset!(T)) subsets;

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

	auto begin() {
		return this.tree.begin();
	}

	auto end() {
		return this.tree.end();
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
	//writeln(tree.toString());
}

unittest {
	import std.stdio : writeln;
	import std.conv : to;
	import std.random : uniform;
	import core.bitop;

	BitsetRBTree!ushort tree;
	foreach(it; 0 .. ushort.max) {
		auto t = to!ushort(uniform(0,ushort.max));
		if(popcnt(t) > 6) {
			tree.insert(t);
		}
	}
	//writeln(tree.toString());

	auto be = tree.begin();
	auto en = tree.end();
	while(be != en) {
		//writeln((*be).bitset);
		++be;
	}
}

struct BitsetArrayArrayIterator(T) {
	BitsetArrayArray!(T)* ptr;
	long curPos;

	this(BitsetArrayArray!(T)* ptr, long curPos = 0) {
		this.ptr = ptr;
		this.curPos = curPos;
	}

	void opUnary(string s)() if(s == "++") { increment(); }
	void opUnary(string s)() if(s == "--") { decrement(); }
	ref BitsetArray!(T) opUnary(string s)() if(s == "*") { return getData(); }

	ref BitsetArray!(T) getData() {
		return (*this.ptr).array[this.curPos];
	}

	void increment() {
		this.curPos++;
	}

	void decrement() {
		this.curPos--;
	}

	bool opEqual(const BitsetArrayArrayIterator!T rhs) {
		return this.ptr == rhs.ptr && this.curPos == rhs.curPos;
	}

	@property BitsetArray!(T) front() {
		return this.getData();
	}

	@property bool empty() {
		return this.curPos >= (*this.ptr).length;
	}

	void popFront() {
		this.increment();
	}
}

struct BitsetArrayArray(T) {
	Array!(BitsetArray!(T)) array;

	void insert(T t) {
		auto bs = Bitset!T(t);
		this.insert(bs);
	}

	void insert(Bitset!T bs) {
		auto it = this.search(bs);
		if(!it.isNull()) {
			(*it).subsets ~= bs;
		} else {
			this.array.insert(bitsetArray(bs));
		}
	}

	Nullable!(BitsetArray!(T)*) search(Bitset!T bs) {
		auto a = bitsetArray(bs);
		foreach(ref it; this.array) {
			if(bs.hasSubSet(it.bitset)) {
				return typeof(return)(&it);
			} 
		}
		return typeof(return).init;
	}

	auto begin() {
		return BitsetArrayArrayIterator!T(&this, 0);
	}

	auto end() {
		return BitsetArrayArrayIterator!T(&this, this.length);
	}

	@property size_t length() const {
		return this.array.length;
	}

	string toString() const {
		import std.array : appender;
		import std.format : formattedWrite;
		auto app = appender!(string)();
		foreach(ref it; this.array) {
			formattedWrite(app, "%s\n", it);
		}

		return app.data;
	}	

	ref BitsetArray!(T) opIndex(const size_t idx) {
		return this.array[idx];
	}
}
unittest {
	import std.stdio : writeln;
	BitsetArrayArray!ushort array;
	auto a = Bitset!(ushort)(cast(ushort)(0b0000_1111_0000_1111));
	array.insert(a);

	auto it = array.search(a);
	assert(!it.isNull());
	
	auto b = Bitset!(ushort)(cast(ushort)(0b0000_1111_0110_1111));
	assert(b.hasSubSet(it.get().bitset));

	auto c = Bitset!(ushort)(cast(ushort)(0b0000_1111_0000_1101));
	assert(!c.hasSubSet(it.get().bitset));

	it.get().subsets ~= b;

	auto it2 = array.search(a);
	assert(it2 !is null);
	assert((*it2).subsets.length == 1);
	assert((*it2).subsets[0] == b);

	array.insert(c);
	assert(array.length == 2);

	auto d = Bitset!(ushort)(cast(ushort)(0b0000_1111_1111_1111));
	array.insert(d);

	auto iter = array.begin();
	auto end = array.end();

	int i = 0;
	while(iter != end) {
		assert((*iter).bitset == array[i].bitset);
		++iter;
		++i;
	}
}

module bitsetrbtree;

import std.container.array : Array;
import std.exception : enforce;
import std.typecons : isIntegral, Nullable;
import std.format : format;
import std.stdio;
import std.experimental.logger;

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
	//Array!(Bitset!(T)) subsets;
	Bitset!(T)[] subsets;

	this(T value) {
		this(Bitset!T(value));
	}

	this(Bitset!T value) {
		this.bitset = value;
	}

	void toString(scope void delegate(const(char)[]) sink) const {
		import std.format : formattedWrite;
		this.bitset.toString2(sink);
		//formattedWrite(sink, "%b len(%s) [", this.bitset.store,
		formattedWrite(sink, " len(%s) [", this.subsets.length);
		foreach(ref it; this.subsets) {
			formattedWrite(sink, "%s ", it.toString2());
		}
		formattedWrite(sink, "]");
	}

	auto dup() const {
		import std.traits;

		Unqual!(typeof(this)) ret;
		ret.bitset = this.bitset;
		ret.subsets = this.subsets.dup;
		return ret;
	}
}

BitsetArray!T bitsetArray(T)(T t) if(isIntegral!T) {
	return BitsetArray!T(bitset(t));
}

BitsetArrayRC!T bitsetArrayRC(T)(T t) if(isIntegral!T) {
	return BitsetArrayRC!T(bitset(t));
}

BitsetArray!(T.StoreType) bitsetArray(T)(T t) if(!isIntegral!T) {
	return BitsetArray!(T.StoreType)(t);
}

BitsetArrayRC!(T.StoreType) bitsetArrayRC(T)(T t) if(!isIntegral!T) {
	return BitsetArrayRC!(T.StoreType)(t);
}

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

struct BitsetArrayArrayIterator(T,S) {
	S* ptr;
	long curPos;

	this(S* ptr, long curPos = 0) {
		this.ptr = ptr;
		this.curPos = curPos;
	}

	void opUnary(string s)() if(s == "++") { increment(); }
	void opUnary(string s)() if(s == "--") { decrement(); }
	ref T opUnary(string s)() if(s == "*") { return getData(); }

	ref T getData() {
		return (*this.ptr).array[cast(size_t)this.curPos];
	}

	void increment() {
		this.curPos++;
	}

	void decrement() {
		this.curPos--;
	}

	bool opEqual(const(BitsetArrayArrayIterator!(T,S)) rhs) {
		return this.ptr == rhs.ptr && this.curPos == rhs.curPos;
	}

	@property T front() {
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
	import exceptionhandling;
	import config;
	Array!(BitsetArray!(T)) array;

	void insert(Bitset!T key, Bitset!T value) {
		auto it = this.search(key);
		if(!it.isNull()) {
			assert(value != (*it).bitset, format("bs(%b) it(%b)", value.store,
					(*it).bitset.store
			));
			(*it).subsets ~= value;
		} else {
			if(getConfig().permutationStart == -1) {
				assert(key == value, format("%s %s", key, value));
				//ensure(key == value);
			}
			this.array.insert(bitsetArray(key));
		}
	}

	void insertUnique(Bitset!T key) {
		auto it = this.search(key);
		if(!it.isNull()) {
			if(key == (*it).bitset) {
				return;
			}

			foreach(ss; (*it).subsets) {
				if(key == ss) {
					return;
				}
			}

			(*it).subsets ~= key;
		} else {
			this.array.insert(bitsetArray(key));
		}
	}

	void insert(T t) {
		auto bs = Bitset!T(t);
		this.insert(bs);
	}

	void insert(Bitset!T bs) {
		auto it = this.search(bs);
		if(!it.isNull()) {
			//writefln("%b %b", (*it).bitset.store, bs.store);
			// TODO figure out if this is really a valid assertion
			assert(bs != (*it).bitset, format("bs(%b) it(%b)", bs.store,
					(*it).bitset.store
			));
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

	void toFile() { }

	auto begin() {
		return BitsetArrayArrayIterator!(BitsetArray!(T),typeof(this))(&this, 0);
	}

	auto end() {
		return BitsetArrayArrayIterator!(BitsetArray!(T),typeof(this))(&this, this.length);
	}

	auto opSlice() const {
		return this.array[];
	}

	auto opSlice(const size_t low, const size_t high) const {
		return this.array[low .. high];
	}

	@property size_t length() const {
		return this.array.length;
	}

	string toString() const {
		import std.array : appender;
		import std.format : formattedWrite;
		auto app = appender!(string)();
		foreach(ref it; this.array[]) {
			formattedWrite(app, "%s\n", it);
		}

		return app.data;
	}	

	ref BitsetArray!(T) opIndex(const size_t idx) {
		return this.array[idx];
	}

	auto dup() const {
		import std.traits : Unqual;
		Unqual!(typeof(this)) ret;
		foreach(it; this.array[]) {
			ret.array.insertBack(it.dup);
		}
		return ret;
	}

	void toFile(string prefix) {
	}
}

unittest {
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

struct BitsetArrayRC(T) {
	import std.format : format;

	Bitset!T bitset;
	Array!(Bitset!(T)) subsets;

	this(T value) {
		this(Bitset!T(value));
	}

	this(Bitset!T value) {
		this.bitset = value;
	}

	void toString(scope void delegate(const(char)[]) sink) const {
		import std.format : formattedWrite;
		this.bitset.toString2(sink);
		//formattedWrite(sink, "%b len(%s) [", this.bitset.store,
		formattedWrite(sink, " len(%s) [", this.subsets.length);
		foreach(ref it; this.subsets) {
			formattedWrite(sink, "%s ", it.toString2());
		}
		formattedWrite(sink, "]");
	}

	auto dup() const {
		import std.traits;
		import utils : arrayDup;

		Unqual!(typeof(this)) ret;
		ret.bitset = this.bitset;
		ret.subsets = arrayDup(this.subsets);
		return ret;
	}

	void toFile(string prefix) {
		import std.format : formattedWrite;
		string fn = format("%s%d.subsets", prefix, this.bitset.store);
		auto f = File(fn, "a");
		//logf("%s", fn);

		auto ltw = f.lockingTextWriter();
		foreach(it; this.subsets) {
			formattedWrite(ltw, "%d ", it.store);
		}

		this.subsets.clear();
	}

	Array!(Bitset!(T)) subsetsFromFile(string prefix) const {
		import std.algorithm.iteration : splitter;
		import std.file : readText;
		import std.string : strip;
		import std.conv : to;
		auto t = readText(format("%s%d.subsets", prefix, this.bitset.store)).strip();
		Array!(Bitset!(T)) ret;
		foreach(it; t.splitter(' ')) {
			ret.insertBack(Bitset!(T)(to!T(it)));
		}
		return ret;
	}
}

auto getSubsets(BSA,BitsetStoreType)(auto ref BSA bsa, 
		auto ref BitsetStoreType tree) 
{
	import std.traits : Unqual;
	static if(is(Unqual!BSA == BitsetArray!uint)
				|| is(Unqual!BSA == BitsetArray!ushort)
				|| is(Unqual!BSA == BitsetArray!ulong)) 
	{
		return bsa.subsets;
	} else static if(is(Unqual!BSA == BitsetArrayRC!uint)
				|| is(Unqual!BSA == BitsetArrayRC!ushort)
				|| is(Unqual!BSA == BitsetArrayRC!ulong)) 
	{
		return bsa.subsetsFromFile(tree.prefix);
	}
}

struct BitsetArrayArrayRC(T) {
	import exceptionhandling;
	import config;
	Array!(BitsetArrayRC!(T)) array;
	string prefix;

	this(string prefix) {
		this.prefix = prefix;
	}

	void insert(Bitset!T key, Bitset!T value) {
		auto it = this.search(key);
		if(!it.isNull()) {
			assert(value != (*it).bitset, format("bs(%b) it(%b)", value.store,
					(*it).bitset.store
			));
			(*it).subsets ~= value;
		} else {
			if(getConfig().permutationStart == -1) {
				assert(key == value, format("%s %s", key, value));
				//ensure(key == value);
			}
			this.array.insert(bitsetArrayRC(key));
		}
	}

	void insert(T t) {
		auto bs = Bitset!T(t);
		this.insert(bs);
	}

	void insert(Bitset!T bs) {
		auto it = this.search(bs);
		if(!it.isNull()) {
			//writefln("%b %b", (*it).bitset.store, bs.store);
			// TODO figure out if this is really a valid assertion
			assert(bs != (*it).bitset, format("bs(%b) it(%b)", bs.store,
					(*it).bitset.store
			));
			(*it).subsets ~= bs;
		} else {
			this.array.insert(bitsetArrayRC(bs));
		}
	}

	Nullable!(BitsetArrayRC!(T)*) search(Bitset!T bs) {
		auto a = bitsetArray(bs);
		foreach(ref it; this.array) {
			if(bs.hasSubSet(it.bitset)) {
				return typeof(return)(&it);
			} 
		}
		return typeof(return).init;
	}

	auto begin() {
		return BitsetArrayArrayIterator!(BitsetArrayRC!(T),typeof(this))(&this, 0);
	}

	auto end() {
		return BitsetArrayArrayIterator!(BitsetArrayRC!(T),typeof(this))(&this, this.length);
	}

	auto opSlice() const {
		return this.array[];
	}

	auto opSlice(const size_t low, const size_t high) const {
		return this.array[low .. high];
	}

	@property size_t length() const {
		return this.array.length;
	}

	string toString() const {
		import std.array : appender;
		import std.format : formattedWrite;
		auto app = appender!(string)();
		foreach(ref it; this.array[]) {
			formattedWrite(app, "%s\n", it);
		}

		return app.data;
	}	

	ref BitsetArrayRC!(T) opIndex(const size_t idx) {
		return this.array[idx];
	}

	auto dup() const {
		import std.traits : Unqual;
		Unqual!(typeof(this)) ret;
		foreach(it; this.array[]) {
			ret.array.insertBack(it.dup);
		}
		return ret;
	}

	void toFile() {
		import std.file : mkdirRecurse;
		import std.string : lastIndexOf;
		ptrdiff_t folder = this.prefix.lastIndexOf('.');
		if(folder == -1) {
			folder = this.prefix.length;
		}
		mkdirRecurse(this.prefix[0 .. folder]);
		//logf("toFile %s", this.array.length);
		foreach(it; this.array[]) {
			//logf("%s", it.bitset.store);
			it.toFile(this.prefix);
		}
	}
}

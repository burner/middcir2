module bitsetrbtree;

import std.container.array : Array;
import std.exception : enforce;
import std.typecons : isIntegral, Nullable;
import std.format : format;
import std.stdio;
import std.experimental.logger;

import config;
import rbtree;
import bitsetmodule;

alias BitsetStore(T) = BitsetArrayArray!(T);
//alias BitsetStore(T) = BitsetArrayFlat!(T);
//alias BitsetStore(T) = BitsetRBTree!(T); TODO: This seams to be incorrect

bool bitsetLess(T)(const BitsetArray!T l, const BitsetArray!T r) {
	return l.bitset.store < r.bitset.store;
}

bool bitsetEqual(T)(const BitsetArray!T l, const BitsetArray!T r) {
	return r.bitset.hasSubSet(l.bitset);
}

align(8)
struct BitsetArray(T) {
	align(8) {
	Bitset!T bitset;
	Array!(Bitset!(T)) subsets;
	//Bitset!(T)[] subsets;
	}

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
		//ret.subsets = this.subsets.dup;
		foreach(ref it; this.subsets[]) {
			ret.subsets ~= it;
		}
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

align(8):
struct BitsetArrayArray(T) {
	import exceptionhandling;
	align(8) {
	Array!(BitsetArray!(T)) array;
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

align(8)
struct BitsetArrayRC(T) {
	import std.format : format;

	align(8) {
	Bitset!T bitset;
	Array!(Bitset!(T)) subsets;
	}

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

		//this.subsets.clear();
		Array!(Bitset!(T)) tmp;
		this.subsets = tmp;
	}

	Array!(Bitset!(T)) subsetsFromFile(string prefix) const {
		import std.algorithm.iteration : splitter;
		import std.file : readText;
		import std.string : strip;
		import std.conv : to;
		auto t = readText(format("%s%d.subsets", prefix, this.bitset.store))
			.strip();
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
	} else static if(is(Unqual!BSA == BitsetArrayFlat!uint)
				|| is(Unqual!BSA == BitsetArrayFlat!ushort)
				|| is(Unqual!BSA == BitsetArrayFlat!ulong)) 
	{
		return bsa.subsets;
	} else static if(is(Unqual!BSA == BitsetArrayFlatItem!uint)
				|| is(Unqual!BSA == BitsetArrayFlatItem!ushort)
				|| is(Unqual!BSA == BitsetArrayFlatItem!ulong)) 
	{
		return bsa.subsets;
	} else {
		static assert(false, BSA.stringof);
	}
}

align(8)
struct BitsetArrayArrayRC(T) {
	import exceptionhandling;
	import config;
	align(8) {
	Array!(BitsetArrayRC!(T)) array;
	string prefix;
	}

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

	bool insertUnique(Bitset!T key) {
		auto it = this.search(key);
		if(!it.isNull()) {
			logf(LogLevel.error, "%s already exists", key.store);
			return false;
		} else {
			this.array.insert(bitsetArrayRC(key));
			return true;
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
		return BitsetArrayArrayIterator!(BitsetArrayRC!(T),typeof(this))
			(&this, 0);
	}

	auto end() {
		return BitsetArrayArrayIterator!(BitsetArrayRC!(T),typeof(this))
			(&this, this.length);
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
		foreach(ref it; this.array[]) {
			//logf("%s", it.bitset.store);
			it.toFile(this.prefix);
		}
	}
}

struct BitsetArrayFlatItem(T) {
	BitsetArrayFlat!(T)* flat;
	ulong idx;

	this(BitsetArrayFlat!(T)* flat, ulong idx) {
		this.flat = flat;
		this.idx = idx;
	}

	@property Bitset!T bitset() {
		return (*this.flat).keys[this.idx];
	}

	@property const(Bitset!T) bitset() const {
		return (*this.flat).keys[this.idx];
	}

	@property ref Bitset!(T)[] subsets() {
		//logf("key %s %s", this.idx, (*this.flat).keys.length);
		//logf("super %s %s", (*this.flat).keys[idx].store, (*this.flat).superSets.length);
		return (*this.flat).superSets[(*this.flat).keys[this.idx].store];
	}

	@property ref const(Bitset!(T)[]) subsets() const {
		//logf("%s %s", (*this.flat).keys[idx].store, (*this.flat).superSets.length);
		return (*this.flat).superSets[(*this.flat).keys[this.idx].store];
	}

	@property bool isNull() const {
		return this.idx == ulong.max;
	}

	auto opUnary(string s)() if(s == "*") { return this; }

	auto dup() {
		return typeof(this)(this.flat, this.idx);
	}
}

struct BitsetArrayFlatIterator(T,S) {
	import std.traits : Unqual;
	S* ptr;
	long curPos;
	long endPos = long.max;

	this(S* ptr, long curPos) {
		this.ptr = ptr;
		this.curPos = curPos;
		this.endPos = ulong.max;
	}

	this(S* ptr, size_t start, size_t end) {
		this(ptr, cast(long)start);
		this.endPos = cast(long)endPos;
	}

	void opUnary(string s)() if(s == "++") { increment(); }
	void opUnary(string s)() if(s == "--") { decrement(); }
	BitsetArrayFlatItem!T opUnary(string s)() if(s == "*") { return getData(); }

	BitsetArrayFlatItem!T getData() {
		return BitsetArrayFlatItem!T(cast(Unqual!(S)*)this.ptr, cast(ulong)this.curPos);
	}

	void increment() {
		this.curPos++;
	}

	void decrement() {
		this.curPos--;
	}

	bool opEqual(const(BitsetArrayFlatIterator!(T,S)) rhs) {
		//return this.ptr is rhs.ptr && this.curPos == rhs.curPos;
		return this.curPos == rhs.curPos;
	}

	@property BitsetArrayFlatItem!T front() {
		return this.getData();
	}

	@property bool empty() {
		return this.curPos >= (*this.ptr).length
			|| this.curPos >= this.endPos;
	}

	void popFront() {
		this.increment();
	}

}

extern(C) uint fastSubsetFind(uint* ptr, size_t len, uint supSet);
extern(C) ushort fastSubsetFind2(ushort* ptr, size_t len, ushort supSet);
extern(C) uint fastSubsetFindIdx(uint* ptr, size_t len, uint supSet);
extern(C) ushort fastSubsetFindIdx2(ushort* ptr, size_t len, ushort supSet);

align(8) struct BitsetArrayFlat(T) {
	import std.algorithm.comparison : min, max;
	Bitset!(T)[] keys;
	Bitset!(T)[][] superSets;

	static auto opCall() {
		BitsetArrayFlat!T ret;
		//ret.superSets = new Bitset!(T)[][](max(ushort.max, T.max/4096), 0);
		static if(is(T == ushort)) {
			const toAlloc = ushort.max;
		} else static if(is(T == uint)) {
			const toAlloc = cast(uint)(1)<<20;
		} else static if(is(T == ulong)) {
			const toAlloc = cast(ulong)(1)<<37;
		} else {
			static assert(false, T.stringof);
		}

		//logf("%s", toAlloc);
		ret.superSets = new Bitset!(T)[][](toAlloc, 0);
		//logf("superSets size %s", ret.superSets.length);
		if(ret.superSets.length == 0) {
			throw new Exception("foo");
		}
		return ret;
	}

	void insert(Bitset!T key, Bitset!T value) {
		T it = this.searchInternal(key);
		if(it != T.max) {
			//assert(value != (*it).bitset, format("bs(%b) it(%b)", value.store,
			//		(*it).bitset.store
			//));
			this.superSets[it] ~= value;
		} else {
			if(getConfig().permutationStart == -1) {
				assert(key == value, format("%s %s", key, value));
				//ensure(key == value);
			}
			this.keys ~= key;
			//this.array.insert(bitsetArrayRC(key));
		}
	}

	void insert(T t) {
		auto bs = Bitset!T(t);
		this.insert(bs);
	}

	void insert(Bitset!T bs) {
		T it = this.searchInternal(bs);
		if(it != T.max) {
			this.superSets[it] ~= bs;
		} else {
			this.keys ~= bs;
		}
	}

	bool insertUnique(Bitset!T key) {
		T it = this.searchInternal(key);
		if(it != T.max) {
			foreach(jt; this.superSets[it]) {
				if(jt == key) {
					return false;
				}
			}
			this.superSets[it] ~= key;
			return true;
		} else {
			this.keys ~= key;
			return true;
		}
	}

	T searchInternal(Bitset!T bs) {
		static if(is(T == ulong)) {
			for(size_t i = 0; i < this.keys.length; ++i) {
				if((this.keys[i].store & bs.store) == this.keys[i].store)
				{
					//return this.keys[i].store;
					return i;
				} 
			}
			return ulong.max;
		} else static if(is(T == uint)) {
			/*for(size_t i = 0; i < this.keys.length; ++i) {
				if((this.keys[i].store & bs.store) == this.keys[i].store)
				{
					//return this.keys[i].store;
					return cast(uint)i;
				} 
			}
			return uint.max;*/
			T ret = fastSubsetFindIdx(cast(uint*)this.keys.ptr, this.keys.length,
					bs.store
				);
			//logf("found idx %s in %s", ret, this.keys.length);
			return ret;
		} else static if(is(T == ushort)) {
			/*for(size_t i = 0; i < this.keys.length; ++i) {
				if((this.keys[i].store & bs.store) == this.keys[i].store)
				{
					//return this.keys[i].store;
					return cast(ushort)i;
				} 
			}
			return ushort.max;*/
			T ret = fastSubsetFindIdx2(cast(ushort*)this.keys.ptr, this.keys.length,
					bs.store
				);
			logf("found idx %s in %s", ret, this.keys.length);
			return ret;
		} else {
			static assert(false, "Can't search with type " ~ T.stringof);
		}
	}

	BitsetArrayFlatItem!T search(Bitset!T bs) {
		//logf("\n%s\n", bs);
		//logf("\n%(%s\n%)", this.keys[]);
		T f = this.searchInternal(bs);
		//logf("found %s", f);
		if(f == T.max) {
			return BitsetArrayFlatItem!T(&this, ulong.max);
		} else {
			return BitsetArrayFlatItem!T(&this, cast(ulong)f);
		}
	}

	auto begin() {
		return BitsetArrayFlatIterator!(T,typeof(this))(&this, 0);
	}

	auto end() {
		return BitsetArrayFlatIterator!(T,typeof(this))(&this, this.keys.length);
	}

	auto opSlice() {
		return this.begin();
	}

	auto opSlice(const size_t low, const size_t high) const {
		return BitsetArrayFlatIterator!(T,typeof(this))(&this, low, high);
	}

	@property size_t length() const {
		return this.keys.length;
	}

	string toString() const {
		return "";
	}	

	/*ref BitsetArrayRC!(T) opIndex(const size_t idx) {
		return this.array[idx];
	}*/

	auto dup() {
		import std.traits : Unqual;
		Unqual!(typeof(this)) ret;
		ret.keys = this.keys.dup;
		ret.superSets = this.superSets.dup;
		return ret;
	}

	void toFile() {
	}
}

// LGPL 3 or higher Robert Burner Schadek rburners@gmail.com
module bitsetmodule;

import std.stdio;
import std.typecons : isIntegral, isUnsigned;
import std.range : isRandomAccessRange;
import std.container : Array;

import bitfiddle;

immutable size_t[256] bits_in_uint8 = [
0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
];

pragma(inline, true)
pure size_t countImpl(const ubyte n) {
	return bits_in_uint8[n];
}

pragma(inline, true)
pure size_t countImpl(const ushort n) {
	return bits_in_uint8[n & 0xFFU] + bits_in_uint8[(n >> 8) & 0xFFU];
}

pragma(inline, true)
pure size_t countImpl(const uint n) {
	return bits_in_uint8[n & 0xFFU] + bits_in_uint8[(n >> 8) & 0xFFU] + 
		bits_in_uint8[(n >> 16) & 0xFFU] + bits_in_uint8[(n >> 24) & 0xFFU];
}

pragma(inline, true)
pure size_t countImpl(const ulong n) {
	return bits_in_uint8[n & 0xFFU] + bits_in_uint8[(n >> 8) & 0xFFU] + 
		bits_in_uint8[(n >> 16) & 0xFFU] + bits_in_uint8[(n >> 24) & 0xFFU] +
		bits_in_uint8[(n >> 32) & 0xFFU] + bits_in_uint8[(n >> 40) & 0xFFU] +
		bits_in_uint8[(n >> 48) & 0xFFU] + bits_in_uint8[(n >> 56) & 0xFFU];
}

pure int popcnt(const(ushort) v) {
	static import core.bitop;
	return core.bitop.popcnt(cast(ushort)v);
}

pure int popcnt(const(uint) v) {
	static import core.bitop;
	return core.bitop.popcnt(cast(uint)v);
}

pure int popcnt(const(ulong) v) {
	//static import core.bitop;
	//return core.bitop.popcnt(cast(ulong)v);
	return cast(int)countImpl(v);
}

void getBitsSet(B,A)(const auto ref B bitset, ref A store) {
	for(int i = 0; i < B.StoreType.sizeof * 8; ++i) {
		if(bitset.test(i)) {
			store.insertBack(i);
		}
	}
}

unittest {
	import fixedsizearray;
	import exceptionhandling;

	auto toTest = [0,5,10,31];
	Bitset!uint bs;
	foreach(it; toTest) {
		bs.set(it);
	}

	FixedSizeArray!(int,32) fsa;
	getBitsSet(bs, fsa);

	size_t i = 0;
	foreach(it; fsa[]) {
		assertEqual(it, toTest[i]);
		++i;
	}
}

Bitset!T bitset(T)(T t) if(isIntegral!T) {
	return Bitset!T(t);
}

Bitset!T bitset(T,R)(ref const(Array!R) r) if(isIntegral!T) {
	Bitset!T ret;

	foreach(ref it; r) {
		ret.set(cast(size_t)it);
	}

	return ret;
}

import std.traits : isArray;

Bitset!T bitset(T,A)(A arr) if(isArray!A) {
	Bitset!T ret;
	foreach(it; arr) {
		ret.set(it);
	}
	return ret;
}

unittest {
	int[] arr = [0, 4, 6, 8, 31];
	Array!uint a;
	a.insertBack(arr);

	auto bs = bitset!uint(a);
	foreach(it; arr) {
		assert(bs.test(it));
	}
}

template TypeFromSize(int Size) {
	static if(Size == 8) {
		alias TypeFromSize = ubyte;
	} else static if(Size == 16) {
		alias TypeFromSize = ushort;
	} else static if(Size == 32) {
		alias TypeFromSize = uint;
	} else static if(Size == 64) {
		alias TypeFromSize = ulong;
	} else {
		static assert(false);
	}
}

Bitset!T bitsetAll(T)() {
	Bitset!T ret;
	ret.set();
	return ret;
}

struct Bitset(Store) if(isIntegral!Store && isUnsigned!Store) {
	Store store = 0;
	alias StoreType = Store;

	// constructor
	this(Store s) {
		this.store = s;
	}

	pragma(inline, true)
	bool opIndex(const size_t idx) const {
		return testBit(this.store, idx);
	}

	// access
	
	bool test(const size_t idx) const {
		if(idx > Store.sizeof * 8) {
			throw new Exception("You cannot access passed the size of the Bitset");
		} else {
			return this[idx];
		}
	}

	size_t size() const {
		return Store.sizeof * 8;
	}

	pragma(inline, true)
	size_t count() const {
		import core.bitop : popcnt;
		//return countImpl(this.store);	
		return popcnt(cast(uint)this.store);
	}

	// modify

	void opIndexAssign(const bool value, const size_t idx) {
		this.store = setBit(this.store, idx, value);
	}
	
	Bitset!Store set() {
		this.store = Store.max;
		return this;
	}

	Bitset!Store set(const size_t idx, const bool value = true) {
		this.store = setBit(this.store, idx, value);

		return this;
	}
	
	Bitset!Store reset() {
		this.store = 0;

		return this;
	}

	Bitset!Store reset(const size_t idx) {
		this.store = resetBit(this.store, idx);

		return this;
	}
	
	Bitset!Store flip() {
		this.store = cast(StoreType)(~this.store);

		return this;
	}

	Bitset!Store flip(const size_t idx) {
		this.store = flipBit(this.store, idx);

		return this;
	}

	// compare
	
	bool opEquals(const ref Bitset!Store rhs) const {
		return this.store == rhs.store;
	}

	bool all() const {
		return this.store == Store.max;
	}

	bool any() const {
		return this.store != 0;
	}
	
	bool none() const {
		return this.store == 0;
	}

	bool hasSubSet(const ref Bitset!Store rhs) const {
		return this.hasSubSet(rhs.store);
	}

	bool hasSubSet(const Store rhs) const {
		//writefln("rhs %s\nstr %s\naft %s", 
		//		bitsetToString(rhs),
		//		bitsetToString(this.store), 
		//		bitsetToString(rhs & this.store)
		//	);
		return (rhs & this.store) == rhs;
	}

	size_t lowestBit() const {
		import core.bitop : bsf;
		if(this.store == 0) {
			return size_t.max;
		} else {
			return bsf(this.store);
		}
	}

	unittest {
		auto b = Bitset!uint(0b0001);
		assert(b.lowestBit() == 0);

		b = Bitset!uint(0b1000);
		assert(b.lowestBit() == 3);

		b = Bitset!uint(0b0000);
		assert(b.lowestBit() == size_t.max);
	}

	size_t lowestBit(const size_t belowBit) const {
		import std.stdio;
		import core.bitop : bsf;

		uint mask;
		if(belowBit == 0) {
			mask = uint.max;
		} else {
			mask = ~((1U << (belowBit)) - 1U);
		}
		uint nv = cast(uint)(this.store & mask);
		//writefln("%3d %032b %032b", belowBit, mask, nv);

		if(nv == 0) {
			return size_t.max;
		} else {
			return bsf(nv);
		}
	}

	string toString2() const {
		import std.array : appender;
		auto app = appender!string();
		this.toString2(app);

		return app.data;
	}

	void toString2(S)(S sink) const {
		import std.format : formattedWrite;	
		formattedWrite(sink, "(");
		bool first = true;
		for(size_t i = 0; i < Store.sizeof * 8; ++i) {
			if(this.test(i)) {
				if(!first) {
					formattedWrite(sink, ",", i);
				}
				formattedWrite(sink, "%d", i);
				first = false;
			}
		}
		formattedWrite(sink, ")");
	}

	string toString() const {
		import std.array : appender;
		auto app = appender!string();
		this.toString(app);

		return app.data;
	}

	void toString(S)(S sink) const {
		/*bool first = true;
		Store v = this.store;
		for(int i = 0; i < this.size() / 4 && v != cast(Store)(0); ++i) {
			if(!first) {
				formattedWrite(sink, "_");
			} else {
				first = false;
			}

			auto mask = (cast(ulong)(1) << 4) -1;
			formattedWrite(sink, "%04b", v & mask);
			v = v >> 4;
		}*/
		//formattedWrite(sink, "%4b", this.store);
		bitsetToString(sink, this.store);
	}
}

string bitsetToString(I)(I bs) {
	import std.array : appender;
	auto app = appender!string();
	bitsetToString(app, bs);
	return app.data;
}

void bitsetToString(S,I)(auto ref S sink, I bs) {
	import std.format : formattedWrite;	
	formattedWrite(sink, "0b");
	
	const ulong mask = 0b0000_0000_0000_0000_0000_0000_0000_1111;
	const ulong sets  = I.sizeof * 2;

	ulong bitfield = cast(ulong)bs;

	for (size_t i = 0; i < sets; ++i) 
	{
		if (i > 0)
		{
			formattedWrite(sink, "_");
		}

		ulong shift = (sets - i - 1) * 4UL;
		
		formattedWrite(sink, "%04b", (bitfield >> shift) & mask);
	}
}

unittest {
	import std.meta : AliasSeq;
	foreach(T; AliasSeq!(ubyte,ushort,uint,ulong)) {
		Bitset!T store;
		assert(store == store);
		store[2] = true;
		store[4] = true;
		assert(store == store);
		assert(store[2]);
		assert(store.test(2));
		assert(!store.test(1));
		assert(store.count() == 2);
		assert(store.any());
		assert(!store.none());
		assert(!store.all());

		Bitset!T store2;
		assert(store != store2);
		store2[2] = true;

		assert(store.hasSubSet(store2));
		assert(!store2.hasSubSet(store));

		store2[2] = false;
		store2[4] = true;

		assert(store.hasSubSet(store2));
	}
}

unittest {
	Bitset!ubyte bs;
	bs.flip(2);
	assert(bs.test(2));
}

unittest {
	import std.meta : AliasSeq;
	import std.format : format;
	import std.experimental.logger;
	foreach(T; AliasSeq!(ubyte,ushort,uint,ulong)) {
		Bitset!T store;
		for(int i = 0; i < store.size(); ++i) {
			Bitset!T bs;
			bs.flip(i);
			for(int j = 0; j < i; ++j) {
				assert(!bs.test(j), format("%s %s %s", i, j, bs));
			}
			assert(bs.test(i));
			for(int j = i+1; j < i; ++j) {
				assert(!bs.test(j));
			}
		}
	}
}

unittest {
	import std.meta : AliasSeq;
	import std.format : format;
	foreach(T; AliasSeq!(ubyte,ushort,uint,ulong)) {
		Bitset!T v;
		v.set();
		for(int i = 0; i < v.size(); ++i) {
			assert(v.test(i), format("%s %d %b", T.stringof, i, v.store));
		}
	}
}


unittest {
	import std.meta : AliasSeq;
	import std.format : format;
	import std.experimental.logger;
	foreach(T; AliasSeq!(/*ubyte,ushort,*/uint,ulong)) {
		Bitset!T store;
		store.set();
		for(int i = 0; i < store.size(); ++i) {
			assert(store.test(i));
		}

		for(int k = 0; k < store.size(); ++k) {
			store.reset(k);
			assert(!store.test(k));
			for(int j = 0; j < k; ++j) {
				assert(!store.test(j));
			}
			store.flip(k);
			assert(store.test(k));

			for(int j = 0; j < k; ++j) {
				assert(!store.test(j), format("k %3d j %3d %032b", k, j, store.store));
			}
			store.flip(k);
			assert(!store.test(k));
		}
		store.flip();
		for(int i = 0; i < store.size(); ++i) {
			assert(store.test(i));
		}
	}
}

unittest {
	import std.conv : to;
	import std.format : format;
	import std.meta : AliasSeq;
	auto b = Bitset!uint(0b1001);
	assert(b.lowestBit(0) == 0, to!string(b.lowestBit(0)));
	assert(b.lowestBit(2) == 3, to!string(b.lowestBit(2)));
	assert(b.lowestBit(5) == size_t.max, to!string(b.lowestBit(5)));

	foreach(T; AliasSeq!(ubyte,uint,ushort)) {
		auto c = Bitset!T(T.max);
		for(int i = 0; i < T.sizeof * 8; ++i) {
			assert(c.lowestBit(i) == i, 
				format("%s %s %s", T.stringof, i, to!string(c.lowestBit(i)))
			);
		}
	}

	b = Bitset!uint(0b_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10_10);
	for(int i = 0; i < 32; ++i) {
		if(i % 2 == 0) {
			assert(b.lowestBit(i) == i + 1);
		} else {
			assert(b.lowestBit(i) == i);
		}
	}

	b = Bitset!uint(0b_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01_01);
	for(int i = 0; i < 31; ++i) {
		if(i % 2 == 0) {
			assert(b.lowestBit(i) == i);
		} else {
			assert(b.lowestBit(i) == i + 1, format("%s %s", i, b.lowestBit(i)));
		}
	}
}

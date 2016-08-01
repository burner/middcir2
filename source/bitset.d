// LGPL 3 or higher Robert Burner Schadek rburners@gmail.com
module bitsetmodule;

import std.stdio;
import std.typecons : isIntegral, isUnsigned;

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

Bitset!T bitset(T)(T t) if(isIntegral!T) {
	return Bitset!T(t);
}

struct Bitset(Store) if(isIntegral!Store && isUnsigned!Store) {
	Store store = 0;
	alias StoreType = Store;

	// constructor
	this(Store s) {
		this.store = s;
	}

	bool opIndex(const size_t idx) const {
		return testBit(this.store, idx);
	}

	// access
	
	pragma(inline, true)
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
		return countImpl(this.store);	
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
		this.store = ~this.store;

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
		return (rhs & this.store) == rhs;
	}

	void toString(scope void delegate(const(char)[]) sink) const {
		import std.format : formattedWrite;
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
		formattedWrite(sink, "%4b", this.store);
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

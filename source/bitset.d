// LGPL 3 or higher Robert Burner Schadek rburners@gmail.com

import std.stdio;

immutable size_t[256] bits_in_uint8 = [
0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
];

pure size_t countImpl(const ubyte n) {
	return bits_in_uint8[n];
}

pure size_t countImpl(const ushort n) {
	return bits_in_uint8[n & 0xFFU] + bits_in_uint8[(n >> 8) & 0xFFU];
}

pure size_t countImpl(const uint n) {
	return bits_in_uint8[n & 0xFFU] + bits_in_uint8[(n >> 8) & 0xFFU] + 
		bits_in_uint8[(n >> 16) & 0xFFU] + bits_in_uint8[(n >> 24) & 0xFFU];
}

pure size_t countImpl(const ulong n) {
	return bits_in_uint8[n & 0xFFU] + bits_in_uint8[(n >> 8) & 0xFFU] + 
		bits_in_uint8[(n >> 16) & 0xFFU] + bits_in_uint8[(n >> 24) & 0xFFU] +
		bits_in_uint8[(n >> 32) & 0xFFU] + bits_in_uint8[(n >> 40) & 0xFFU] +
		bits_in_uint8[(n >> 48) & 0xFFU] + bits_in_uint8[(n >> 56) & 0xFFU];
}

struct Bitset(Store) {
	Store store = 0;

	// constructor
	bool opIndex(const size_t idx) const {
		return cast(bool)(this.store & (1<<idx));
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

	size_t count() const {
		return countImpl(this.store);	
	}

	// modify

	void opIndexAssign(const bool value, const size_t idx) {
		this.set(idx, value);
	}
	
	Bitset!Store set() {
		this.store = Store.max;
		return this;
	}

	Bitset!Store set(const size_t idx, const bool value = true) {
		this.store ^= (-cast(int)value ^ this.store) & (1 << idx);

		return this;
	}
	
	Bitset!Store reset() {
		this.store = 0;

		return this;
	}

	Bitset!Store reset(const size_t idx) {
		if(idx > (Store.sizeof * 8u)) {
			throw new Exception("out of bound access to Bitset");
		} else {
			this.store &= ~(1<<idx);
		}

		return this;
	}
	
	Bitset!Store flip() {
		this.store = ~this.store;

		return this;
	}

	Bitset!Store flip(const size_t idx) {
		if(idx > (Store.sizeof * 8)) {
			throw new Exception("out of bound access to Bitset");
		} else {
			this.store ^= (1<<idx);
		}

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
		return (rhs.store & this.store) == rhs.store;
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

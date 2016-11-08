module bitsettrie;

import std.stdio;

import bitsetmodule;

import bitsetrbtree : BitsetArray;

class TrieNode(T) {
	const(size_t) bitSetPos;
	long arrayIdx;

	TrieNode!(T)[T.sizeof * 8] follow;

	this(size_t bitSetPos, long bitSetArrayIdx) {
		this.bitSetPos = bitSetPos;
		this.arrayIdx = bitSetArrayIdx;
	}

	void insert(ref Trie!T trie, const(Bitset!T) bs) {
		if(this.arrayIdx != -1) {
			trie.array[this.arrayIdx].subsets ~= bs;
		} else {
			const lp = bs.lowestBit(this.bitSetPos + 1);

			if(lp == size_t.max) {
				this.arrayIdx = trie.array.length;
				trie.array ~= BitsetArray!T(bs);
			} else {
				if(this.follow[lp] is null) {
					this.follow[lp] = new TrieNode!T(lp, -1);
				}

				this.follow[lp].insert(trie, bs);
			}
		}
	}

	void toString(S)(S sink, ref const(Trie!T) trie, const(ulong) indent) const {
		if(indent == 0) {
			format(sink, indent, "%02d:", this.bitSetPos);
		} else {
			format(sink, indent, "%2d:", this.bitSetPos);
		}
		if(this.arrayIdx != -1) {
			format(sink, 0, "%s [", trie.array[this.arrayIdx].bitset.toString2());
			foreach(it; trie.array[this.arrayIdx].subsets) {
				format(sink, 0, "%s ", it.toString2());
			}
			format(sink, 0, "]");
		}
		format(sink, 0, "\n");

		foreach(it; this.follow) {
			if(it !is null) {
				it.toString(sink, trie, indent + 1);
			}
		}
	}
}

struct Trie(T) {
	import bitsetrbtree : BitsetArrayArrayIterator;
	import std.container.array : Array;

	TrieNode!(T)[T.sizeof * 8] follow;

	Array!(BitsetArray!T) array;

	void insert(const(Bitset!T) bs) {
		assert(bs.any());

		const lowBit = bs.lowestBit(0);
		if(this.follow[lowBit] is null) {
			this.follow[lowBit] = new TrieNode!T(lowBit, -1);
		}

		this.follow[lowBit].insert(this, bs);
	}

	auto begin() {
		return BitsetArrayArrayIterator!(T,typeof(this))(&this, 0);
	}

	auto end() {
		return BitsetArrayArrayIterator!(T,typeof(this))(&this, this.array.length);
	}

	@property size_t length() const {
		return this.array.length;
	}

	string toString() const {
		import std.array : appender;
		auto app = appender!string();
		this.toString(app);
		return app.data;
	}

	void toString(S)(S sink) const {
		for(int i = 0; i < T.sizeof * 8; ++i) {
			if(this.follow[i] !is null) {
				//format(sink, 0, "%2d:\n", i);
				this.follow[i].toString(sink, this, 0);
			}
		}
	}
}

private void format(S,Args...)(S sink, const(ulong) indent, string str, 
		Args args)
{
	import std.format : formattedWrite;
	for(ulong i = 0; i < indent; ++i) {
		formattedWrite(sink, " ");
	}

	formattedWrite(sink, str, args);
}

unittest {
	import std.stdio;
	import bitsetrbtree : BitsetArrayArray;

	auto td = [
		Bitset!ushort(0b0000_1100_0000_1100),
		Bitset!ushort(0b0000_1000_0000_1100),
		Bitset!ushort(0b0001_1000_0000_1100),
		Bitset!ushort(0b0001_1100_0000_1100),
		Bitset!ushort(0b0001_1100_0000_1100),
	];

	Trie!ushort t; 
	BitsetArrayArray!ushort baa;

	foreach(it; td) {
		t.insert(it);
		baa.insert(it);
	}
	writeln(t.toString());
	writeln(baa.toString());
}

unittest {
	import std.random : uniform, randomShuffle, Random;
	import std.stdio;
	import bitsetrbtree : BitsetArrayArray;
	import exceptionhandling;

	auto tmp = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];

	auto rnd = Random(1337);

	Trie!ushort t; 
	BitsetArrayArray!ushort baa;

	for(int i = 4; i < 9; ++i) {
		for(int j = 0; j < i * 2; ++j) {
			randomShuffle(tmp, rnd);

			auto bs = bitset!ushort(tmp[0 .. i]);
			t.insert(bs);
			baa.insert(bs);
		}
	}

	writeln(t.toString(), "\n\n\n\n", baa.toString());

	cast(void)assertEqual(t.array.length, baa.array.length);

	import std.algorithm.sorting : sort;
	sort!"a.bitset.store < b.bitset.store"(t.array[]);
	sort!"a.bitset.store < b.bitset.store"(baa.array[]);

	int idx = 0;
	foreach(it; t.array[]) {
		assert(it.bitset == baa[idx].bitset);
		assert(it.subsets.length == baa[idx].subsets.length);
		foreach(jdx, jt; it.subsets) {
			assert(jt == baa[idx].subsets[jdx]);
		}
		++idx;
	}
}

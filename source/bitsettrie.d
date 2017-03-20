module bitsettrie;

import std.stdio;

import bitsetmodule;
import bitsetrbtree : BitsetArray;
import utils : format;

class TrieNode(T) {
	const(size_t) bitSetPos;
	long arrayIdx;

	TrieNode!(T)[T.sizeof * 8] follow;

	this(size_t bitSetPos, long bitSetArrayIdx) {
		this.bitSetPos = bitSetPos;
		this.arrayIdx = bitSetArrayIdx;
	}

	void insert(ref Trie!T trie, const(Bitset!T) bs) {
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

	long search(const(Bitset!T) bs) const {
		if(this.arrayIdx != -1) {
			return this.arrayIdx;
		} else {
			for(size_t i = bs.lowestBit(this.bitSetPos); 
					i != size_t.max; i = bs.lowestBit(i + 1))
			{
				//writefln("i %d", i);
				if(this.follow[i] !is null) {
					long id = this.follow[i].search(bs);
					if(id != -1) {
						return id;
					}
				}
			}

			return -1;
		}
	}

	void sanityCheck() const {
		foreach(idx, it; follow) {
			if(it !is null) {
				assert(it.bitSetPos == idx);
				it.sanityCheck();
			}
		}
	}

	void toString(S)(S sink, ref const(Trie!T) trie, const(ulong) indent) const {
		if(indent == 0) {
			format(sink, indent, "%03d:", this.bitSetPos);
		} else {
			format(sink, indent, "%02d:", this.bitSetPos);
		}
		if(this.arrayIdx != -1) {
			format(sink, 0, "%s [", trie.array[cast(size_t)this.arrayIdx].bitset.toString2());
			foreach(it; trie.array[cast(size_t)this.arrayIdx].subsets) {
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

	TrieNode!(T)[T.sizeof * 8][T.sizeof * 8] follow;

	Array!(BitsetArray!T) array;

	long bluntForceSearch(const(Bitset!T) bs) const {
		long idx = 0;
		foreach(it; this.array[]) {
			if(bs.hasSubSet(it.bitset)) {
				return idx;
			}
			++idx;
		}
		return -1;
	}

	long search(const(Bitset!T) bs) const {
		import std.format : format;

		long id = -1;
		outer: for(size_t j = 0; j < follow.length; ++j) {
			for(size_t i = bs.lowestBit(0); 
					i != size_t.max; i = bs.lowestBit(i + 1))
			{
				if(follow[j][i] !is null) {
					id = follow[j][i].search(bs);
					if(id != -1) {
						const bFS = this.bluntForceSearch(bs);
						assert(bFS != -1);
						assert(this.array[cast(size_t)bFS].bitset.count() ==
								this.array[cast(size_t)id].bitset.count(),
							format("\nbs  %s\nid  %s\nbFS %s", 
								bs.toString2(),
								this.array[cast(size_t)id].bitset.toString2(),
								this.array[cast(size_t)bFS].bitset.toString2()
							)
						);
						//this.array[id].subsets ~= bs;
						break outer;
					}
				}
			}
		}
		return id;
	}

	void insert(const(Bitset!T) bs) {
		import std.format : format;
		assert(bs.any());


		//writefln("\tnew search %s", bs.toString2());
		/*long id = -1;
		outer: for(size_t j = 0; j < follow.length; ++j) {
			for(size_t i = bs.lowestBit(0); 
					i != size_t.max; i = bs.lowestBit(i + 1))
			{
				if(follow[j][i] !is null) {
					id = follow[j][i].search(bs);
					if(id != -1) {
						const bFS = this.bluntForceSearch(bs);
						assert(bFS != -1);
						assert(this.array[bFS].bitset.count() ==
								this.array[id].bitset.count(),
							format("\nbs  %s\nid  %s\nbFS %s", 
								bs.toString2(),
								this.array[id].bitset.toString2(),
								this.array[bFS].bitset.toString2()
							)
						);
						this.array[id].subsets ~= bs;
						break outer;
					}
				}
			}
		}*/

		long id = this.search(bs);
		if(id != -1) {
			this.array[cast(size_t)id].subsets ~= bs;
		} else {
			long ne = bs.lowestBit(0);
			const count = bs.count();
			if(this.follow[cast(size_t)count][cast(size_t)ne] is null) {
				this.follow[cast(size_t)count][cast(size_t)ne] = new TrieNode!T(cast(size_t)ne, -1);
			}
			this.follow[cast(size_t)count][cast(size_t)ne].insert(this, bs);
		}
		//this.sanityCheck();
	}

	void sanityCheck() const {
		foreach(idx, it; follow) {
			foreach(jdx, jt; it) {
				if(jt !is null) {
					assert(jt.bitSetPos == jdx);
					jt.sanityCheck();
				}
			}
		}

		foreach(it; this.array[]) {
			foreach(jt; it.subsets[]) {
				assert(jt.hasSubSet(it.bitset));
			}
		}
	}

	auto begin() {
		return BitsetArrayArrayIterator!(BitsetArray!T,typeof(this))(&this, 0);
	}

	auto end() {
		return BitsetArrayArrayIterator!(BitsetArray!T,typeof(this))(&this, this.array.length);
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
			format(sink, 0, "Size %s\n", i);
			for(int j = 0; j < T.sizeof * 8; ++j) {
				if(this.follow[i][j] !is null) {
					//format(sink, 0, "%2d:\n", i);
					this.follow[i][j].toString(sink, this, 0);
				}
			}
		}
	}

	string toString2() const {
		import std.array : appender;
		import std.format : formattedWrite;
		auto app = appender!string();

		foreach(it; this.array[]) {
			formattedWrite(app, "%s\n", it);	
		}

		return app.data;
	}
}

unittest {
	import std.stdio;
	import bitsetrbtree : BitsetArrayArray;
	import std.algorithm.comparison : max;

	auto td = [
		Bitset!ushort(0b0000_1000_0000_1100),
		Bitset!ushort(0b0000_1100_0000_1100),
		Bitset!ushort(0b0001_1000_0000_1100),
		Bitset!ushort(0b0001_1100_0000_1100),
		Bitset!ushort(0b0001_1100_0000_1100),
	];

	Trie!ushort t; 
	BitsetArrayArray!ushort baa;

	size_t minBits = 0;
	foreach(it; td) {
		size_t mb = it.count();
		assert(mb >= minBits);
		minBits = max(mb, minBits);
		t.insert(it);
		baa.insert(it);
	}
	//writeln(t.toString());
	//writeln(baa.toString());
}

unittest {
	import std.stdio;
	import bitsetrbtree : BitsetArrayArray;
	import std.algorithm.comparison : max;

	auto td = [
		Bitset!ushort(0b0000_0000_1001_0000),
		Bitset!ushort(0b0000_0000_0111_0000),
		Bitset!ushort(0b0000_0000_0001_1100),
		Bitset!ushort(0b0000_0000_0011_0100),
		Bitset!ushort(0b0000_0000_0101_0100),
		Bitset!ushort(0b0000_0001_1000_0100),
	];

	Trie!ushort t; 
	BitsetArrayArray!ushort baa;

	size_t minBits = 0;
	foreach(it; td) {
		size_t mb = it.count();
		assert(mb >= minBits);
		minBits = max(mb, minBits);
		t.insert(it);
		baa.insert(it);
	}
	//writeln(t.toString());
	//writeln(baa.toString());
}

unittest {
	import std.stdio;
	import bitsetrbtree : BitsetArrayArray;
	import std.algorithm.comparison : max;

	auto td = [
		Bitset!ushort(0b0000_0001_0101_0010),
		Bitset!ushort(0b0100_0011_0101_1110),
	];

	Trie!ushort t; 
	BitsetArrayArray!ushort baa;

	size_t minBits = 0;
	foreach(it; td) {
		size_t mb = it.count();
		assert(mb >= minBits);
		minBits = max(mb, minBits);
		t.insert(it);
		baa.insert(it);
	}
	//writeln(t.toString());
	//writeln(baa.toString());
}

unittest {
	import std.stdio;
	import bitsetrbtree : BitsetArrayArray;
	import std.algorithm.comparison : max;

	auto td = [
		Bitset!ushort(0b0101_0100_0001_1100),
		Bitset!ushort(0b1101_0100_1011_1000),
		Bitset!ushort(0b1101_0100_1011_1100),
	];

	Trie!ushort t; 
	BitsetArrayArray!ushort baa;

	size_t minBits = 0;
	foreach(it; td) {
		size_t mb = it.count();
		assert(mb >= minBits);
		minBits = max(mb, minBits);
		t.insert(it);
		baa.insert(it);
	}
	//writeln(t.toString());
	//writeln(baa.toString());
}

unittest {
	import std.random : uniform, randomShuffle, Random;
	import std.stdio;
	import std.format : format;
	import bitsetrbtree : BitsetArrayArray;
	import exceptionhandling;

	auto tmp = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];

	auto rnd = Random(1337);

	Trie!ushort t; 
	BitsetArrayArray!ushort baa;

	for(int i = 6; i < 16; ++i) {
		for(int j = 0; j < i * 4; ++j) {
			randomShuffle(tmp, rnd);

			auto bs = bitset!ushort(tmp[0 .. i]);
			t.insert(bs);
			baa.insert(bs);
		}
	}

	//writeln(t.toString(), "\n\n\n\n", baa.toString());
	//writeln(t.toString2(), "\n\n\n\n", baa.toString());

	assertEqual(t.array.length, baa.array.length);

	import std.algorithm.sorting : sort;
	sort!"a.bitset.store < b.bitset.store"(t.array[]);
	sort!"a.bitset.store < b.bitset.store"(baa.array[]);

	Bitset!ushort[][ushort.sizeof * 8] trieSort;
	Bitset!ushort[][ushort.sizeof * 8] baaSort;

	int sumTrie = 0;
	int sumBaa = 0;
	int idx = 0;
	foreach(it; t.array[]) {
		cast(void)assertEqual(it.bitset, baa[idx].bitset);
		sumTrie += 1 + it.subsets.length;
		sumBaa += 1 + baa[idx].subsets.length;

		long ts = it.bitset.count();
		trieSort[cast(size_t)ts] ~= it.bitset;
		foreach(jt; it.subsets) {
			trieSort[cast(size_t)ts] ~= jt;
		}

		long bc = baa[cast(size_t)idx].bitset.count();
		baaSort[cast(size_t)bc] ~= baa[cast(size_t)idx].bitset;
		foreach(jt; baa[cast(size_t)idx].subsets) {
			baaSort[cast(size_t)bc] ~= jt;
		}

		++idx;
	}

	cast(void)assertEqual(sumTrie, sumBaa);

	foreach(jdx, it; trieSort) {
		//cast(void)assertEqual(it.length, baaSort[jdx].length);
		//writefln("%2d %5d %5d", jdx, it.length, baaSort[jdx].length);
	}
	//writefln("   %5d %5d", sumTrie, sumBaa);

	foreach(i, it; baaSort) {
		if(i > 0) {
			foreach(jt; it) {
				for(int j = 0; j < i; ++j) {
					foreach(kt; baaSort[j]) {
						assert(!jt.hasSubSet(kt),
							format("i %d j %d\njt %s\nkt %s", i, j, 
								jt.toString2(), kt.toString2()
							)
						);
					}
				}
			}
		}
	}

	foreach(i, it; trieSort) {
		if(i > 0) {
			foreach(jt; it) {
				for(int j = 0; j < i; ++j) {
					foreach(kt; trieSort[j]) {
						assert(!jt.hasSubSet(kt),
							format("i %d j %d\njt %s\nkt %s", i, j, 
								jt.toString2(), kt.toString2()
							)
						);
					}
				}
			}
		}
	}
}

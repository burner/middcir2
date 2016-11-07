module bitsettrie;

import bitsetmodule;

import bitsetrbtree : BitsetArray;

class TrieNode(int Size) {
	private alias BitSet = Bitset!(TypeFromSize!Size);
	const(size_t) bitSetPos;
	long bitSetArrayIdx;
	Bitset!(TypeFromSize!Size)[] subsets;

	TrieNode!(Size)[Size] follow;

	this(size_t bitSetPos, long bitSetArrayIdx) {
		this.bitSetPos = bitSetPos;
		this.bitSetArrayIdx = bitSetArrayIdx;
	}

	void insert(const(size_t) pos, const(BitSet) bs, ref Trie!Size trie) {
		const lowPos = bs.lowestBit(pos);
		if(this.bitSetArrayIdx != -1 || lowPos == size_t.max) {
			if(trie.bitsetStore[this.bitSetArrayIdx].bitset != bs) {
				trie.bitsetStore[this.bitSetArrayIdx].subsets ~= bs;
			}
			return;
		}

		if(this.follow[lowPos] is null) {
			const arrayIdx = trie.bitsetStore.length;
			trie.bitsetStore ~= BitsetArray!(TypeFromSize!Size)(bs);
			this.follow[lowPos] = new TrieNode!Size(lowPos, arrayIdx);
		}

		this.follow[lowPos].insert(lowPos + 1, bs, trie);
	}

	void toString(S)(S sink, ref const(Trie!Size) trie, const(ulong) indent) const {
		format(sink, indent, "%s: [", 
			trie.bitsetStore[this.bitSetArrayIdx].bitset.toString()
		);

		foreach(ref it; trie.bitsetStore[this.bitSetArrayIdx].subsets) {
			format(sink, 0, "%s, ", it.toString());
		}
		format(sink, 0, "]\n");
		
		for(int i = 0; i < Size; ++i) {
			if(this.follow[i] !is null) {
				format(sink, indent, "%s:\n", i);
				this.follow[i].toString(sink, trie, indent + 1);
			}
		}
	}
}

struct Trie(int Size) {
	private alias BitSet = Bitset!(TypeFromSize!Size);
	TrieNode!(Size)[Size] follow;

	BitsetArray!(TypeFromSize!Size)[] bitsetStore;

	void insert(const(BitSet) bs) {
		assert(bs.any());

		const lowBit = bs.lowestBit(0);
		if(this.follow[lowBit] is null) {
			const arrayIdx = this.bitsetStore.length;
			this.bitsetStore ~= BitsetArray!(TypeFromSize!Size)(bs);
			this.follow[lowBit] = new TrieNode!(Size)(0, arrayIdx);
		}

		this.follow[lowBit].insert(lowBit + 1, bs, this);
	}

	void toString(S)(S sink) const {
		for(int i = 0; i < Size; ++i) {
			if(this.follow[i] !is null) {
				format(sink, 0, "%s:\n", i);
				this.follow[i].toString(sink, this, 1);
			}
		}
	}

	string toString() const {
		import std.array : appender;
		auto app = appender!string();
		this.toString(app);
		return app.data;
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
	Trie!16 t;
	t.insert(Bitset!ushort(0b0000_1100_0000_1100));
	t.insert(Bitset!ushort(0b0000_1100_0000_1000));
	t.insert(Bitset!ushort(0b0000_0100_0000_1100));
	t.insert(Bitset!ushort(0b0000_1110_0000_1000));
	t.insert(Bitset!ushort(0b0001_1100_0000_1000));
	writeln(t.toString());
}

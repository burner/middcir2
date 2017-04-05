module permutation;

import bitsetmodule;
import std.experimental.logger;

alias Permutation = PermutationImpl!uint;

struct PermutationImpl(BitsetType) {
	static if(is(BitsetType == uint)) {
		alias Integer = int;
	} else static if(is(BitsetType == ulong)) {
		alias Integer = long;
	}
	Integer N;
   	Integer R;
	Integer[] curr;

	/** nN how many total, nR how many to select */
	this(int nN, int nR) {
		//logf("n %d r %d", nN, nR);
		import std.array;
		this.empty = (nN < 1 || nR > nN); 
		this.generated = 0;
		this.N = nN;
		this.R = nR;

		this.curr = new Integer[nR];
		for(int c = 0; c < nR; ++c) {
	 		this.curr[c] = c;
		}
	}

	~this() {
		destroy(this.curr);
	}

	// true while there are more solutions
	bool empty;
	
	// count how many generated
	Integer generated;

	@property Bitset!BitsetType front() const {
		Bitset!BitsetType ret;
		foreach(it; this.curr) {
			ret.set(cast(size_t)it);
		}
		return ret;
	}
		
	void popFront() {
		// find what to increment
		this.empty = true;
		for(Integer i = R - 1; i >= 0; --i) {
			if(this.curr[cast(size_t)i] < N - R + i) {
				Integer j = this.curr[cast(size_t)i] + 1;
				while(i < R) {
					this.curr[cast(size_t)i] = j;
					++i;
					++j;
				}
				this.empty = false;
				++this.generated;
				break;
			}
		}
	}
}

alias Permutations = PermutationsImpl!uint;

struct PermutationsImpl(BitsetType) {
	const int numNodes;
	int curNodes;
	const int stopCount;

	PermutationImpl!BitsetType cur;

	this(const int numNodes, const int startCnt, const int stopCnt) {
		//logf("%s %s %s", numNodes, startCnt, stopCnt);
		this.numNodes = numNodes;
		this.curNodes = startCnt;
		this.stopCount = stopCnt;

		this.cur = PermutationImpl!BitsetType(this.numNodes, this.curNodes);
		//logf("c %d n %d", this.curNodes, this.numNodes);
	}

	this(const int numNodes) {
		this(numNodes, 1, numNodes);
	}

	@property bool empty() const {
		//logf("cn %d sC+1 %d", this.curNodes, this.stopCount+1);
		return (this.curNodes >= this.numNodes && this.cur.empty)
			|| (this.curNodes >= this.stopCount + 1/*&& this.cur.empty*/)
			;
	}

	@property Bitset!BitsetType front() const {
		return this.cur.front;
	}

	void popFront() {
		this.cur.popFront();
		if(this.cur.empty) {
			++this.curNodes;
			this.cur = PermutationImpl!BitsetType(this.numNodes, this.curNodes);
			//logf("c %d n %d", this.curNodes, this.numNodes);
		}
	}
}

unittest {
	import exceptionhandling;
	auto perm = Permutations(3);
	int cnt = 0;
	foreach(it; perm) {
		++cnt;
	}
	cast(void)assertEqual(cnt, 7);
}

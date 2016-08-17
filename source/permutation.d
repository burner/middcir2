module permutation;

import bitsetmodule;

struct Permutation {
	import fixedsizearray;
	int N;
   	int R;
	FixedSizeArray!(int,32) curr;

	/** nN how many total, nR how many to select */
	this(int nN, int nR) {
		this.empty = (nN < 1 || nR > nN); 
		this.generated = 0;
		this.N = nN;
		this.R = nR;

		for(byte c = 0; c < nR; ++c) {
	 		curr.insertBack(c);
		}
	}

	// true while there are more solutions
	bool empty;
	
	// count how many generated
	int generated;

	@property Bitset!uint front() const {
		Bitset!uint ret;
		foreach(it; this.curr[]) {
			ret.set(it);
		}
		return ret;
	}
		
	void popFront() {
		// find what to increment
		this.empty = true;
		for(int i = R - 1; i >= 0; --i) {
			if(this.curr[i] < N - R + i) {
				int j = this.curr[i] + 1;
				while (i <= R) {
					this.curr[i++] = j++;
				}
				this.empty = false;
				++this.generated;
				break;
			}
		}
	}
}

struct Permutations {
	const int numNodes;
	int curNodes;

	Permutation cur;

	this(const int numNodes) {
		this.numNodes = numNodes;
		this.curNodes = 1;

		this.cur = Permutation(this.numNodes, this.curNodes);
	}

	@property bool empty() const {
		return this.curNodes >= this.numNodes && this.cur.empty;
	}

	@property Bitset!uint front() const {
		return this.cur.front;
	}

	void popFront() {
		this.cur.popFront();
		if(this.cur.empty) {
			++this.curNodes;
			this.cur = Permutation(this.numNodes, this.curNodes);
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

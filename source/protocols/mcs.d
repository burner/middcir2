module protocols.mcs;

import std.stdio;
import std.conv;
import core.bitop : popcnt;
import std.math;
import std.format;

double availability(T,S)(const T bitSet, const S numNodes, double p) pure {
	const bitsSet = popcnt(bitSet);
	//return binomial(numNodes, bitsSet) * pow(p, bitsSet) * pow((1.0 - p), numNodes - bitsSet);
	return pow(p, bitsSet) * pow((1.0 - p), numNodes - bitsSet);
}

long binomial(long n, long k) pure {
	long c = 1; 
	if(k > n-k) {
		k = n-k;	/* take advantage of symmetry */
	}
	for(long i = 1; i <= k; i++, n--) {
		if(c/i > long.max/n) throw new Exception("binomial overflow");	/* return 0 on overflow */
		c = c/i * n + c%i * n / i;	/* split c*n/i into (c/i*i + c%i)*n/i */
	}
	return c;
}

struct MCS {
	import bitsetrbtree;

	int numNodes;
	const int majority;

	BitsetRBTree!uint tree;

	this(int nn) {
		this.numNodes = nn;
		this.majority = this.numNodes / 2 + 1;
	}

	void testAll() {
		const upTo = 1 << numNodes;
		for(uint it = 0; it < upTo; ++it) {
			if(popcnt(it) > this.majority) {
				tree.insert(it);
			}
		}
	}

	double[] calcP(const double stepCount = 0.01, const double fromP = 0.0, 
			const double toP = 1.0) 
	{
		assert(toP > fromP);
		this.testAll();
		const retSize = to!size_t((toP - fromP) / stepCount) + 1u;
		const retSizeD = to!double(retSize);
		double[] ret = new double[retSize];
		bool[] test = new bool[retSize];
		ret[] = 0.0;

		auto it = this.tree.begin();
		auto end = this.tree.end();

		while(it != end) {
			test[] = false;
			for(size_t idx = 0; idx < retSize; ++idx) {
				double step = stepCount * idx;
				assert(!test[idx]);
				test[idx] = true;

				const bsa = *it;
				ret[idx] += availability(bsa.bitset.store, this.numNodes, step);

				foreach(jt; bsa.subsets) {
					ret[idx] += availability(jt.store, this.numNodes, step);
				}
			}
			foreach(idx, jt; test) {
				assert(jt, format("%s", idx));
			}
			++it;
		}

		return ret;
	}
}

unittest {
	auto mcs = MCS(10);
	auto rslt = mcs.calcP();
	foreach(idx, it; rslt) {
		if(idx > 10) {
			assert(!approxEqual(it, 0.0, 0.0000000002), format("%s", idx));
		}
	}
}

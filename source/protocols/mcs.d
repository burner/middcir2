module protocols.mcs;

import protocols;

import std.stdio;
import std.conv;
import core.bitop : popcnt;
import std.math;
import std.format;
import std.experimental.logger;

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

	const int numNodes;
	const int majority;
	const int half;

	this(int nn) {
		this.numNodes = nn;
		this.majority = this.numNodes / 2 + 1;
		this.half = this.numNodes / 2;

		logf("numNodes %s majority %s half %s", this.numNodes, this.majority,
				this.half
		);
	}

	BitsetRBTree!uint testAll(int atLeast) {
		BitsetRBTree!uint tree;

		const upTo = 1 << numNodes;
		logf("upTo %s", upTo);
		for(uint it = 0; it < upTo; ++it) {
			if(popcnt(it) >= atLeast) {
				tree.insert(it);
			}
		}

		return tree;
	}

	Result calcP(const double stepCount = 0.01, const double fromP = 0.0, 
			const double toP = 1.0) 
	{
		assert(toP > fromP);

		auto ret = Result();

		{
			auto readTree = this.testAll(this.half);

			auto it = readTree.begin();
			auto end = readTree.end();

			bool[101] test;
			while(it != end) {
				test[] = false;
				for(size_t idx = 0; idx < 101; ++idx) {
					double step = stepCount * idx;
					assert(!test[idx]);
					test[idx] = true;

					const bsa = *it;
					ret.readAvail[idx] += availability(bsa.bitset.store, this.numNodes, step);

					foreach(jt; bsa.subsets) {
						ret.readAvail[idx] += availability(jt.store, this.numNodes, step);
					}
				}
				foreach(idx, jt; test) {
					assert(jt, format("%s", idx));
				}
				++it;
			}
		}

		{
			auto writeTree = this.testAll(this.majority);

			auto it = writeTree.begin();
			auto end = writeTree.end();

			bool[101] test;
			while(it != end) {
				test[] = false;
				for(size_t idx = 0; idx < 101; ++idx) {
					double step = stepCount * idx;
					assert(!test[idx]);
					test[idx] = true;

					const bsa = *it;
					ret.writeAvail[idx] += availability(bsa.bitset.store, this.numNodes, step);

					foreach(jt; bsa.subsets) {
						ret.writeAvail[idx] += availability(jt.store, this.numNodes, step);
					}
				}
				foreach(idx, jt; test) {
					assert(jt, format("%s", idx));
				}
				++it;
			}
		}

		return ret;
	}
}

struct MCSFormula {
	const int numNodes;
	const int majority;

	this(int nn) {
		this.numNodes = nn;
		this.majority = this.numNodes / 2 + 1;
	}

	Result calcP(const double stepCount = 0.01, const double fromP = 0.0, 
			const double toP = 1.0) 
	{
		assert(toP > fromP);
		//const retSize = to!size_t((toP - fromP) / stepCount) + 1u;
		//double[] ret = new double[retSize];
		//bool[] test = new bool[retSize];
		//ret[] = 0.0;

		auto ret = Result();

		/*for(size_t idx = 0; idx < retSize; ++idx) {
			double step = stepCount * idx;
			assert(!test[idx]);
			test[idx] = true;
		}

		foreach(idx, jt; test) {
			assert(jt, format("%s", idx));
		}*/
		assert(false);
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

module protocols.mcs;

import std.stdio;
import std.conv;
import std.math;
import std.format;
import std.experimental.logger;

import protocols;
import math;

struct MCS {
	import bitsetrbtree;

	const int numNodes;
	const int majority;
	const int half;

	this(int nn) {
		this.numNodes = nn;
		this.majority = this.numNodes / 2 + 1;
		this.half = to!int((this.numNodes / 2.0)+0.51);

		/*logf("numNodes %s majority %s half %s", this.numNodes, this.majority,
				this.half
		);*/
	}

	BitsetRBTree!uint testAll(int atLeast) {
		import core.bitop : popcnt;
		BitsetRBTree!uint tree;

		const upTo = 1 << numNodes;
		for(uint it = 0; it < upTo; ++it) {
			if(popcnt(it) >= atLeast) {
				tree.insert(it);
			}
		}

		return tree;
	}

	Result calcP(const double stepCount = 0.01) {

		auto ret = Result();

		{
			auto readTree = this.testAll(this.half);

			auto it = readTree.begin();
			auto end = readTree.end();

			bool[101] test;
			while(it != end) {
				test[] = false;
				for(int idx = 0; idx < 101; ++idx) {
					double step = stepCount * idx;
					assert(!test[idx]);
					test[idx] = true;

					const bsa = *it;

					ret.readAvail[idx] += availability(bsa.bitset, this.numNodes, step);

					foreach(jt; bsa.subsets) {
						ret.readAvail[idx] += availability(jt, this.numNodes, step);
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
					ret.writeAvail[idx] += availability(bsa.bitset, this.numNodes, step);

					foreach(jt; bsa.subsets) {
						ret.writeAvail[idx] += availability(jt, this.numNodes, step);
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

	string name() const pure {
		return format("MCS %s", this.numNodes);
	}
}

struct MCSFormula {
	const int numNodes;
	const int majority;
	const int half;

	this(int nn) {
		this.numNodes = nn;
		this.majority = this.numNodes / 2 + 1;
		this.half = to!int((this.numNodes / 2.0)+0.51);
	}

	Result calcP(const double stepCount = 0.01) {
		auto ret = Result();

		const nn = this.numNodes+1;
		for(int idx = 0; idx < 101; ++idx) {
			const double p = stepCount * idx;
			//logf("%2d %.5f", idx, p);
			for(int avail = this.half; avail < nn; ++avail) {
				const bino = binomial(this.numNodes, avail);
				const av = availability(avail, this.numNodes, p);
				//logf("%2d %4d %.15f", avail, bino, av);
				ret.readAvail[idx] += bino * av;
			}

			for(int avail = this.majority; avail < nn; ++avail) {
				const bino = binomial(this.numNodes, avail);
				ret.writeAvail[idx] += 
					 bino * availability(avail, this.numNodes, p);
			}
		}


		return ret;
	}

	string name() const pure {
		return format("MCSFormula %s", this.numNodes);
	}
}

unittest {
	auto mcs = MCS(10);
	auto rslt = mcs.calcP();
}

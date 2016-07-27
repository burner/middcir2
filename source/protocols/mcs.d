module protocols.mcs;

import std.stdio;
import std.conv;
import std.math;
import std.format;
import std.experimental.logger;

import protocols;
import math;
import utils;

struct MCS {
	import bitsetrbtree;

	const int numNodes;
	const int majority;
	const int half;
	BitsetRBTree!uint read;
	BitsetRBTree!uint write;

	this(int nn) {
		this.numNodes = nn;
		this.majority = this.numNodes / 2 + 1;
		this.half = to!int((this.numNodes / 2.0)+0.51);
	}

	void testAll(ref BitsetRBTree!uint tree, int atLeast) {
		import core.bitop : popcnt;

		const upTo = 1 << numNodes;
		for(uint it = 0; it < upTo; ++it) {
			if(popcnt(it) >= atLeast) {
				tree.insert(it);
			}
		}
	}

	Result calcP(const double stepCount = 0.01) {
		this.testAll(this.read, this.half);
		this.testAll(this.write, this.majority);

		return calcAvailForTree(this.numNodes, this.read, this.write);
	}

	string name() const pure {
		return format("MCS %s", this.numNodes);
	}
}

unittest {
	int mcsN = 6;
	auto mcs = MCS(mcsN);
	auto mcsRslt = mcs.calcP();
	testQuorumIntersection(mcs.read, mcs.write);

	auto mcsF = MCSFormula(mcsN);
	auto mcsFRslt = mcsF.calcP();

	compare(mcsFRslt.readAvail, mcsRslt.readAvail, &equal);
	compare(mcsFRslt.writeAvail, mcsRslt.writeAvail, &equal);
	compare(mcsFRslt.readCosts, mcsRslt.readCosts, &equal);
	compare(mcsFRslt.writeCosts, mcsRslt.writeCosts, &equal);
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
			for(int avail = this.half; avail < nn; ++avail) {
				const bino = binomial(this.numNodes, avail);
				const av = availability(this.numNodes, avail, idx, stepCount);
				ret.readAvail[idx] += bino * av;
			}

			for(int avail = this.majority; avail < nn; ++avail) {
				const bino = binomial(this.numNodes, avail);
				ret.writeAvail[idx] += 
					 bino * availability(this.numNodes, avail, idx, stepCount);
			}
		}

		for(size_t idx = 1; idx < 101; ++idx) {
			ret.writeCosts[idx] = this.majority;
			ret.readCosts[idx] = this.half;
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

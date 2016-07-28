module protocols;

import std.container : Array;
import std.experimental.logger;

import bitsetrbtree;

struct Result {
	double[101] readAvail;
	double[101] writeAvail;

	double[101] readCosts;
	double[101] writeCosts;

	static Result opCall() {
		Result ret;
		ret.readAvail[] = 0.0;
		ret.writeAvail[] = 0.0;
		ret.readCosts[] = 0.0;
		ret.writeCosts[] = 0.0;
		return ret;
	}
}

Result calcAvailForTree(const int numNodes,
		ref BitsetStore!uint read, ref BitsetStore!uint write)
{
	auto ret = Result();
	calcAvailForTreeImpl(numNodes, read, ret.readAvail, ret.readCosts);
	calcAvailForTreeImpl(numNodes, write, ret.writeAvail, ret.writeCosts);

	return ret;
}

private void calcAvailForTreeImpl(const int numNodes,
		ref BitsetStore!uint tree, ref double[101] avail,
	   	ref double[101] costs)
{
	import std.format : format;
	import std.algorithm.sorting : sort;
	import core.bitop : popcnt;

	import config : stepCount;
	import math : availability, binomial, isNaN;

	auto it = tree.begin();
	auto end = tree.end();

	size_t numQuorums = 0;

	bool[101] test;
	while(it != end) {
		const bsa = *it;

		numQuorums += 1;
		numQuorums += bsa.subsets.length;

		test[] = false;
		for(int idx = 0; idx < 101; ++idx) {
			double step = stepCount * idx;
			assert(!test[idx]);
			test[idx] = true;

			const availBsa = availability(numNodes, bsa.bitset, idx, stepCount);
			const minQuorumNodeCnt = popcnt(bsa.bitset.store);

			avail[idx] += availBsa;

			double bino = binomial(numNodes, minQuorumNodeCnt);
			costs[idx] += minQuorumNodeCnt * availBsa;

			foreach(jt; bsa.subsets) {
				auto availJt = availability(numNodes, jt, idx, stepCount);
				avail[idx] += availJt;
				costs[idx] += minQuorumNodeCnt * availJt;
			}
		}
		foreach(idx, jt; test) {
			if(!jt) {
				throw new Exception(format("%s", idx));
			}
		}
		++it;
	}

	for(int idx = 0; idx < 101; ++idx) {
		costs[idx] /= avail[idx];
	}
}

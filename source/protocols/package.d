module protocols;

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
		ref BitsetRBTree!uint read, ref BitsetRBTree!uint write)
{
	auto ret = Result();
	calcAvailForTreeImpl(numNodes, read, ret.readAvail, ret.readCosts);
	calcAvailForTreeImpl(numNodes, write, ret.writeAvail, ret.writeCosts);

	return ret;
}

private void calcAvailForTreeImpl(const int numNodes,
		ref BitsetRBTree!uint tree, ref double[101] avail,
	   	ref double[101] costs)
{
	import config : stepCount;
	import math : availability;
	import std.format : format;

	auto it = tree.begin();
	auto end = tree.end();

	bool[101] test;
	while(it != end) {
		test[] = false;
		for(int idx = 0; idx < 101; ++idx) {
			double step = stepCount * idx;
			assert(!test[idx]);
			test[idx] = true;

			const bsa = *it;

			avail[idx] += availability(numNodes, bsa.bitset, idx, stepCount);

			foreach(jt; bsa.subsets) {
				avail[idx] += availability(numNodes, jt, idx, stepCount);
			}
		}
		foreach(idx, jt; test) {
			if(!jt) {
				throw new Exception(format("%s", idx));
			}
		}
		++it;
	}
}

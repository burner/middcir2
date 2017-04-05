module graphmeasures;

import std.experimental.logger;
import std.traits;
import std.range;
import graph;
import floydmodule;
import fixedsizearray;

struct DiameterResult {
	double average;
	double median;
	double max;
}

DiameterResult diameter(int Size)(ref Graph!Size graph) {
	import std.algorithm.sorting : sort;
	import std.algorithm.iteration : sum;
	FloydImpl!Size floyd;
	floyd.init(graph);
	floyd.execute(graph);

	DiameterResult rslt;
	FixedSizeArray!(size_t,64) store;
	FixedSizeArray!(uint,64) tmpPathStore;

	for(uint i = 0; i < graph.length; ++i) {
		for(uint j = i; j < graph.length; ++j) {
			tmpPathStore.removeAll();
			if(floyd.path(i, j, tmpPathStore)) {
				store.insertBack(tmpPathStore.length);
			}
		}
	}

	auto s = store[];
	static assert(hasAssignableElements!(typeof(s)));
	static assert(isRandomAccessRange!(typeof(s)));
	static assert(hasSlicing!(typeof(s)));
	sort(s);
	logf("%(%s %)", store[]);

	return DiameterResult(
		cast(double)(sum(store[])) / store.length,
		store.length % 2 == 1 ? store[store.length / 2] :
			cast(double)(store[store.length / 2] + 
			store[(store.length / 2) + 1]) / 2.0,
		store[store.length - 1]
	);
}

unittest {
	auto g = makeSix!32();
	auto r = diameter(g);
	logf("%s", r);
}

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
	//logf("%(%s %)", store[]);

	return DiameterResult(
		cast(double)(sum(store[])) / store.length,
		store.length % 2 == 1 ? store[store.length / 2] :
			cast(double)(store[store.length / 2] + 
			store[(store.length / 2) + 1]) / 2.0,
		store[store.length - 1]
	);
}

unittest {
	import exceptionhandling;
	{
		auto g = makeSix!32();
		auto r = diameter(g);
		assertEqual(r.average, 2.42857);
		assertEqual(r.median, 2.0);
		assertEqual(r.max, 4.0);
	}

	{
		auto g = makeTwoTimesTwo();
		auto r = diameter(g);
		assertEqual(r.average, 2.0);
		assertEqual(r.median, 2.0);
		assertEqual(r.max, 2.0);
	}

	{
		auto g = makeNine!32();
		auto r = diameter(g);
		assertEqual(r.average, 2.62222);
		assertEqual(r.median, 2.0);
		assertEqual(r.max, 4.0);
	}

	{
		auto g = makeLineOfFour();
		auto r = diameter(g);
		assertEqual(r.average, 2.4);
		assertEqual(r.median, 2.0);
		assertEqual(r.max, 4.0);
	}

	{
		auto g = makeLine!16(5);
		auto r = diameter(g);
		assertEqual(r.max, 5.0);
		assertEqual(r.average, 2.66667);
		assertEqual(r.median, 2.0);
	}
}

double computeConnectivity(int Size)(ref Graph!Size graph) {
	import std.container.array;
	import bitsetmodule;
	import permutation;

	alias BitsetTypeType = TypeFromSize!Size;
	alias BitsetType = Bitset!BitsetTypeType;

	auto permu = PermutationsImpl!BitsetTypeType(cast(int)graph.length);
	auto paths = floyd!(typeof(graph),Size)(graph);

	BitsetType one;
	one.set();
	foreach(perm; permu) {
		BitsetType avail = BitsetType(one.store ^ perm.store);
		paths.execute(graph, avail);
		for(uint ai = 0; ai < graph.length; ++ai) {
			for(uint bi = ai + 1; bi < graph.length; ++bi) {
				if(!paths.pathExists(ai, bi)) {
					return avail.flip().count();
				}
			}
		}
	}	

	return graph.length;
}

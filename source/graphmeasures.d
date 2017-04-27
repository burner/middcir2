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
	double min;
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
		cast(double)(store.length % 2 == 1 ? store[store.length / 2] :
			cast(double)(store[store.length / 2] + 
			store[(store.length / 2) + 1]) / 2.0),
		cast(double)store.front,
		cast(double)store.back
	);
}

unittest {
	import exceptionhandling;
	{
		auto g = makeSix!32();
		auto r = diameter(g);
		assertEqual(r.average, 2.42857);
		assertEqual(r.min, 2.0);
		assertEqual(r.median, 2.0);
		assertEqual(r.max, 4.0);
	}

	{
		auto g = makeTwoTimesTwo();
		auto r = diameter(g);
		assertEqual(r.average, 2.0);
		assertEqual(r.median, 2.0);
		assertEqual(r.min, 2.0);
		assertEqual(r.max, 2.0);
	}

	{
		auto g = makeNine!32();
		auto r = diameter(g);
		assertEqual(r.average, 2.62222);
		assertEqual(r.min, 2.0);
		assertEqual(r.median, 2.0);
		assertEqual(r.max, 4.0);
	}

	{
		auto g = makeLineOfFour();
		auto r = diameter(g);
		assertEqual(r.average, 2.4);
		assertEqual(r.median, 2.0);
		assertEqual(r.min, 2.0);
		assertEqual(r.max, 4.0);
	}

	{
		auto g = makeLine!16(5);
		auto r = diameter(g);
		assertEqual(r.max, 5.0);
		assertEqual(r.average, 2.66667);
		assertEqual(r.median, 2.0);
		assertEqual(r.min, 2.0);
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

struct DegreeResult {
	double average;
	double median;
	double min;
	double max;
}

DegreeResult degree(int Size)(ref Graph!Size graph) {
	import std.container.array : Array;
	import std.algorithm.sorting : sort;
	import std.algorithm.iteration : sum;

	Array!(double) tmp;
	tmp.reserve(graph.length);

	for(size_t i; i < graph.length; ++i) {
		tmp.insertBack(cast(double)(graph.getAdjancy(i).count));
	}

	sort(tmp[]);

	DegreeResult ret;
	ret.min = tmp.front;
	ret.max = tmp.back;
	ret.average = sum(tmp[]) / tmp.length;
	if(graph.length % 2 == 0) {
		ret.median = (tmp[graph.length / 2] + tmp[(graph.length / 2) + 1]) 
			/ 2.0;
	} else {
		ret.median = tmp[graph.length / 2];
	}

	return ret;
}

unittest {
	auto g = genTestGraph!16();	
	DegreeResult dgr = degree(g);

	assert(dgr.average <= dgr.max);
	assert(dgr.average >= dgr.min);

	for(size_t i; i < g.length; ++i) {
		assert(g.getAdjancy(i).count() >= dgr.min);
		assert(g.getAdjancy(i).count() <= dgr.max);
	}
}

struct BetweennessCentrality {
	double average;
	double median;
	double min;
	double max;
}

BetweennessCentrality betweennessCentrality(int Size)(ref Graph!Size graph) {
	import std.container.array;
	import std.algorithm.sorting : sort;
	import std.algorithm.iteration : sum;
	import bitsetmodule;
	import utils : removeAll;

	alias BitsetTypeType = TypeFromSize!Size;
	alias BitsetType = Bitset!BitsetTypeType;

	auto paths = floyd!(typeof(graph),Size)(graph);
	Array!(size_t) store;
	for(size_t i; i < graph.length; ++i) {
		store.insertBack(0);
	}
	Array!(uint) tmpPath;

	BitsetType one;
	one.set();
	paths.execute(graph, one);

	for(uint i; i < graph.length; ++i) {
		for(uint j; j < graph.length; ++j) {
			for(uint k = j + 1; k < graph.length; ++k) {
				tmpPath.removeAll();
				if(paths.path(j, k, tmpPath)) {
					for(size_t n = 1; n < tmpPath.length - 1; ++n) {
						if(tmpPath[n] == i) {
							store[tmpPath[n]]++;
							break;
						}
					}					
				}
			}
		}
	}

	sort(store[]);

	BetweennessCentrality ret;
	ret.average = sum(store[]) / cast(double)graph.length;
	ret.min = cast(double)store.front;
	ret.max = cast(double)store.back;
	if(graph.length % 2 == 0) {
		ret.median = (store[graph.length / 2] + store[(graph.length / 2) + 1]) 
			/ 2.0;
	} else {
		ret.median = store[graph.length / 2];
	}

	return ret;
}

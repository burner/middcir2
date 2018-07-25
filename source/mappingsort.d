module mappingsort;

import std.array : appender, empty, back, front;
import std.traits : EnumMembers;
import std.container.array;
import std.algorithm.sorting : sort;
import std.algorithm.iteration : sum;
import std.stdio;
import std.experimental.logger;

import exceptionhandling;

import mapping;
import bitsetmodule;
import graph;
import graphmeasures;
import math;
import floydmodule;

enum Feature {
	DiaMin,
	DiaMax,
	DiaAvg,
	DiaMode,
	DiaMedian,
	Dgr,
	BC
}

struct VertexStat {
	double[EnumMembers!Feature.length] features;
	int id;
}

int[] sortForMappingByFeature(G)(auto ref G from, auto ref G to, 
		Feature[] sortBy) 
{
	ensure(from.length == to.length);
	VertexStat[] f = sortVerticesByFeature(from, sortBy);
	VertexStat[] t = sortVerticesByFeature(to, sortBy);

	int[] ret = new int[from.length];
	for(size_t i = 0; i < ret.length; ++i) {
		ret[f[i].id] = t[i].id;
	}
	return ret;
}

VertexStat[] sortVerticesByFeature(G)(auto ref G g, Feature[] sortBy) {
	import graphmeasures;
	assert(!sortBy.empty);

	VertexStat[] ret;
	auto f = floyd(g);
	f.execute(g);
	for(int i = 0; i < g.length; ++i) {
		VertexStat cur;
		cur.id = i;
		size_t[] paths;
		for(int j = 0; j < g.length; ++j) {
			if(i == j) {
				continue;
			}
			Array!int p;
			if(f.path(i, j, p)) {
				paths ~= p.length;
			}
		}
		ensure(!paths.empty);
		sort(paths);
		cur.features[Feature.DiaMin] = paths.front;
		cur.features[Feature.DiaMax] = paths.back;
		cur.features[Feature.DiaAvg] = sum(paths) / cast(double)(paths.length);
		cur.features[Feature.DiaMode] = cast(double)(computeMode(paths).max);
		cur.features[Feature.DiaMedian] = computeMedian(paths);
		cur.features[Feature.Dgr] = g.nodes[i].count();
		cur.features[Feature.BC] = betweenessCentrality(g, i);
		ret ~= cur;
	}

	sort!(delegate(VertexStat a, VertexStat b) {
		import std.math : approxEqual;
		foreach(ftr; sortBy) {
			if(approxEqual(a.features[ftr], b.features[ftr])) {
				continue;
			} else if(a.features[ftr] < b.features[ftr]) {
				return true;
			} else {
				return false;
			}
		}
		return false;
	})(ret);
	return ret;
}

void testLatticeMappingSort() {
	Graph!32 g = makeNine!32();
	testLatticeMappingSort(3, 3, g);
}

void testLatticeMappingSort(G)(int c, int r, G pnt) {
	import std.conv : to;
	import std.format : format;
	import std.algorithm : map, joiner;
	import protocols.lattice;
	import protocols;
	import plot.gnuplot;
	import plot;
	{
		auto f = File("Results/mappingsort_tlp/pnt.tex", "w");
		auto ltw = f.lockingTextWriter();
		pnt.toTikz(ltw);
	}

	auto tl = LatticeImpl!32(c, r);
	{
		auto f = File("Results/mappingsort_tlp/lnt.tex", "w");
		auto ltw = f.lockingTextWriter();
		tl.getGraph().toTikz(ltw);
	}
	auto tlRslt = tl.calcAC();
	auto rsltTL = ResultPlot(tl.name(), tlRslt);

	auto mapping = Mappings!(32,32)(tl.graph, pnt, QTF(1.0), ROW(0.5));
	auto mapRslt = mapping.calcAC(tl.read, tl.write);

	auto ftrList = [ Feature.DiaMin, Feature.DiaMax, Feature.DiaAvg, Feature.DiaMode, Feature.DiaMedian,
			Feature.Dgr, Feature.BC
		];

	Feature[][] ftrs;
	foreach(i; ftrList) {
		ftrs ~= [i];
		foreach(j; ftrList) {
			if(i != j) {
				ftrs ~= [i, j];
			}
		}
	}	

	foreach(ftr; ftrs) {
		string ftrStr = ftr.map!(a => to!string(a)).joiner("_").to!string();
		logf("\"%s\"", ftrStr);

		VertexStat[] stTL = sortVerticesByFeature(tl.getGraph(), ftr);
		VertexStat[] stPnt = sortVerticesByFeature(pnt, ftr);
		assert(stTL.length == stPnt.length);
		logf("TL\n%(%3s\n%)", stTL);
		logf("PNT\n%(%3s\n%)", stPnt);

		int[] mappings = new int[stTL.length];
		foreach(idx, it; stPnt) {
			mappings[it.id] = stTL[idx].id;
		}
		logf("Mapping %(%2d %)", mappings);

		auto mapDirect = new Mapping!(32,32)(tl.getGraph(), pnt, mappings);
		auto mapDirectRslt = mapDirect.calcAC(tl.read, tl.write);
		logf("awr %s", mapDirectRslt.awr());
		logf("optimal mapping %s awr %s", mapping.bestMapping().mapping[], 
				mapRslt.awr()
			);

		gnuPlot(format("Results/mappingsort_tlp/%s", ftrStr),  "",
				rsltTL, 
				ResultPlot("BestMap", mapping.bestResult()),
				ResultPlot("SortMap", mapDirectRslt)
			);
	}
}

unittest {
	import protocols.lattice;

	auto sb = [Feature.BC, Feature.DiaMin];

	auto g = genTestGraph!(16)();
	VertexStat[] vs = sortVerticesByFeature(g, sb);
	logf("%s %(%s\n%)", __LINE__, vs);

	auto tlp = LatticeImpl!16(4,4);

	auto tlpLnt = tlp.getGraph();
	VertexStat[] vs2 = sortVerticesByFeature(tlpLnt, sb);
	logf("%s %(%s\n%)", __LINE__, vs2);

	int[] r = sortForMappingByFeature(g, tlpLnt, sb);
	logf("%(%s, %)", r);
}

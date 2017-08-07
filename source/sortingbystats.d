module sortingbystats;

import std.container.array;
import std.algorithm.sorting : sort;

import exceptionhandling;
import permutation;

import statsanalysis : GraphStats, GraphWithProperties, loadGraphs;
//import learning;
import learning2;

void sortMappedQP(int Size)(string jsonFileName) {
	Array!(GraphWithProperties!Size) graphs = loadGraphs!Size(jsonFileName);
	ensure(graphs.length > 0);
	const size_t numNodes = graphs[0].graph.length;

	string[3] protocols = ["MCS", "Lattice", "Grid"];

	OptimalMappings!(Size)[3] rslts; 
	foreach(idx, proto; protocols) {
		rslts[idx] = loadResults(graphs, jsonFileName, proto, graphs[0].graph.length);
	}

	foreach(ref it; rslts) {
		it.validate();
	}

	auto permu = Permutations(cast(int)cstatsArray.length, 
			1, cast(int)cstatsArray.length
			//1, 2
		);
	//formattedWrite(ltw, "\\part{%s}\n", protocol);
	//formattedWrite(ltw, "\\chapter{Permutations}\n");
	foreach(perm; permu) {
		auto mm = new MMCStat!32();
		for(int j = 0; j < cstatsArray.length; ++j) {
			if(perm.test(j)) {
				mm.insertIStat(cstatsArray[j]);
			}
		}
		foreach(idx, ref rslt; rslts) {
			foreach(ref OptMapData!Size om; rslt.data[]) {
				Array!(GraphStats!Size) tmp;
				foreach(ref GraphStats!Size gs; om.values[]) {
					tmp.insertBack(gs);
				}
				sortMappedQP!Size(tmp, mm);
				toLatexSortMapped!Size(tmp, mm, protocols[idx], "");
			}
		}
	}
}

void toLatexSortMapped(int Size)(ref Array!(GraphStats!Size) rslt,
		const(MMCStat!Size) mm, const(string) protocol, const(string) prefix)
{

}

void sortMappedQP(int Size)(ref Array!(GraphStats!Size) rslt,
		const(MMCStat!Size) mm) 
{
	sort!((a,b) => mm.less(a,b))(rslt[]);
}

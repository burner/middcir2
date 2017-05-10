module statsanalysis;

import std.container.array;
import std.experimental.logger;
import std.stdio : File;
import std.meta : AliasSeq;
import stdx.data.json.parser;
import stdx.data.json.value;

import graphmeasures;
import graph;
import protocols;

alias Measures(int Size) = 
	AliasSeq!(
		//DiameterAverage!Size, DiameterMedian!Size, DiameterMax!Size
		Connectivity!Size,
		DegreeAverage!Size, DegreeMedian!Size, DegreeMin!Size, DegreeMax!Size,
		BetweenneesAverage!Size, BetweenneesMedian!Size, BetweenneesMin!Size, BetweenneesMax!Size
	);

struct Connectivity(int Size) {
	static immutable string XLabel = "Connectivity";
	static immutable string sortPredicate = "a.graph.connectivity < b.graph.connectivity";
	static auto select(const(GraphStats!Size) g) {
		import std.math : isNaN;
		assert(!isNaN(g.graph.connectivity));
		return g.graph.connectivity;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.connectivity;
	}
}

struct DiameterAverage(int Size) {
	static immutable string XLabel = "DiameterAverage";
	static immutable string sortPredicate = "a.graph.diameter.average < b.graph.diameter.average";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.diameter.average;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.diameter.average;
	}
}

struct DiameterMedian(int Size) {
	static immutable string XLabel = "DiameterMedian";
	static immutable string sortPredicate = "a.graph.diameter.median < b.graph.diameter.median";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.diameter.median;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.diameter.median;
	}
}

struct DiameterMax(int Size) {
	static immutable string XLabel = "DiameterMax";
	static immutable string sortPredicate = "a.graph.diameter.max < b.graph.diameter.max";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.diameter.max;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.diameter.max;
	}
}

struct DiameterMin(int Size) {
	static immutable string XLabel = "DiameterMin";
	static immutable string sortPredicate = "a.graph.diameter.min < b.graph.diameter.min";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.diameter.min;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.degree.min;
	}
}

struct DegreeAverage(int Size) {
	static immutable string XLabel = "DegreeAverage";
	static immutable string sortPredicate = "a.graph.degree.average < b.graph.degree.average";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.degree.average;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.degree.average;
	}
}

struct DegreeMedian(int Size) {
	static immutable string XLabel = "DegreeMedian";
	static immutable string sortPredicate = "a.graph.degree.median < b.graph.degree.median";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.degree.median;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.degree.median;
	}
}

struct DegreeMin(int Size) {
	static immutable string XLabel = "DegreeMin";
	static immutable string sortPredicate = "a.graph.degree.min < b.graph.degree.min";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.degree.min;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.degree.min;
	}
}

struct DegreeMax(int Size) {
	static immutable string XLabel = "DegreeMax";
	static immutable string sortPredicate = "a.graph.degree.max < b.graph.degree.max";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.degree.max;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.degree.average;
	}
}

struct BetweenneesAverage(int Size) {
	static immutable string XLabel = "BetweenneesAverage";
	static immutable string sortPredicate = "a.graph.betweenness.average < b.graph.betweenness.average";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.betweenness.average;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.betweenness.average;
	}
}

struct BetweenneesMedian(int Size) {
	static immutable string XLabel = "BetweenneesMedian";
	static immutable string sortPredicate = "a.graph.betweenness.median < b.graph.betweenness.median";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.betweenness.median;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.betweenness.median;
	}
}

struct BetweenneesMin(int Size) {
	static immutable string XLabel = "BetweenneesMin";
	static immutable string sortPredicate = "a.graph.betweenness.min < b.graph.betweenness.min";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.betweenness.min;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.betweenness.min;
	}
}

struct BetweenneesMax(int Size) {
	static immutable string XLabel = "BetweenneesMax";
	static immutable string sortPredicate = "a.graph.betweenness.max < b.graph.betweenness.max";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.betweenness.max;
	}
	static auto select(const(GraphWithProperties!Size) g) {
		return g.betweenness.max;
	}
}

immutable readOverWriteLevel = [0.01, 0.1, 0.25, 0.50, 0.75, 0.90, 0.99];

struct LNTDimensions {
	size_t width;
	size_t height;

	bool opEquals(const LNTDimensions other) const {
		return this.width == other.width && this.height == other.height;
	}
}

unittest {
	auto a = LNTDimensions(1,2);
	auto b = LNTDimensions(2,1);

	assert(a == a);
	assert(a != b);
}

enum ResultArraySelect : size_t {
	ReadAvail,
	WriteAvail,
	ReadCosts,
	WriteCosts
}

struct GraphStats(int Size) {
	GraphWithProperties!(Size)* graph;
	Result[7] results;

	this(GraphWithProperties!(Size)* g, string filename, string protocol,
			LNTDimensions dim) 
	{
		this.graph = g;
		this.loadResults(this.graph.graph.id, filename, "_row_", protocol, dim);
		this.loadResults(this.graph.graph.id, filename, "_rowc_", protocol,
				dim);
	}

	this(const(GraphStats!(Size)) old) {
		this.graph = cast(typeof(this.graph))old.graph;
		for(size_t i = 0; i < results.length; ++i) {
			this.results[i] = old.results[i].dup;
		}
	}

	ref const(double[101]) getData(const size_t idx, const ResultArraySelect type) const {
		final switch(type) {
			case ResultArraySelect.ReadAvail:
				return this.results[idx].readAvail;
			case ResultArraySelect.WriteAvail:
				return this.results[idx].writeAvail;
			case ResultArraySelect.ReadCosts:
				return this.results[idx].readCosts;
			case ResultArraySelect.WriteCosts:
				return this.results[idx].writeCosts;
		}
	}

	void add(ref const(GraphStats!Size) other) {
		for(size_t i = 0; i < results.length; ++i) {
			this.results[i].readAvail[] += other.results[i].readAvail[];
			this.results[i].writeAvail[] += other.results[i].writeAvail[];
			this.results[i].readCosts[] += other.results[i].readCosts[];
			this.results[i].writeCosts[] += other.results[i].writeCosts[];
		}
	}

	void div(int count) {
		for(size_t i = 0; i < results.length; ++i) {
			this.results[i].readAvail[] /= cast(double)count;
			this.results[i].writeAvail[] /= cast(double)count;
			this.results[i].readCosts[] /= cast(double)count;
			this.results[i].writeCosts[] /= cast(double)count;
		}
	}

	void loadResults(long id, string filename, string availOrCosts, 
			string protocol, LNTDimensions dim) 
	{
		import std.file : dirEntries, SpanMode, readText;
		import std.format : format;
		import std.algorithm.iteration : filter;
		import std.algorithm.searching : canFind;
		import std.range : lockstep;
		string folderName = format("%s_Results/%05d/", filename, id);
		string dimString = format("%dx%d", dim.width, dim.height);

		foreach(idx, it; readOverWriteLevel) {
			string s = format("%.2f", it);
			auto filesAvail = dirEntries(folderName, SpanMode.depth)
				.filter!(f =>
					canFind(f.name, "data") 
					&& canFind(f.name, availOrCosts) 
					&& canFind(f.name, protocol)
					&& canFind(f.name, s)
					&& canFind(f.name, dimString)
					&& canFind(f.name, "_avail")
				);
			auto filesCosts = dirEntries(folderName, SpanMode.depth)
				.filter!(f =>
					canFind(f.name, "data") 
					&& canFind(f.name, availOrCosts) 
					&& canFind(f.name, protocol)
					&& canFind(f.name, s)
					&& canFind(f.name, dimString)
					&& canFind(f.name, "_costs")
				);
			foreach(a, c; lockstep(filesAvail, filesCosts)) {
				logf("\n\t%s\n\t%s", a, c);
				this.results[idx] = Result(readText(a), readText(c));	
				//logf("readAvail %(%.5f, %)", this.results[idx].readAvail[]);
				//logf("writeAvail %(%.5f, %)", this.results[idx].writeAvail[]);
				//logf("readCosts %(%.5f, %)", this.results[idx].readCosts[]);
				//logf("writeCosts %(%.5f, %)", this.results[idx].writeCosts[]);
			}
		}
	}
}

struct Data(int Size) {
	LNTDimensions key;
	Array!(GraphStats!Size) values;
}

struct GraphStatss(int Size) {
	Array!(Data!Size) data;

	void sort(alias Pred)() {
		static import std.algorithm.sorting;
		foreach(ref it; this.data[]) {
			std.algorithm.sorting.sort!(Pred)(it.values[]);
		}
	}
}

struct ProtocolStats(int Size) {
	GraphStatss!Size mcs;
	GraphStatss!Size grid;
	GraphStatss!Size lattice;

	void sort(alias Pred)() {
		this.mcs.sort!Pred();
		this.grid.sort!Pred();
		this.lattice.sort!Pred();
	}
}

struct GraphWithProperties(int Size) {
	import graphmeasures;
	Graph!Size graph;
	DiameterResult diameter;
	DegreeResult degree;
	BetweennessCentrality betweenness;
	double connectivity;

	this(const(JSONValue) j) {
		this.graph = Graph!Size(j);
		this.diameter = computeDiameter!Size(this.graph);
		this.connectivity = computeConnectivity(this.graph);
		this.degree = computeDegree(this.graph);
		this.betweenness = betweennessCentrality(this.graph);
	}
}

Array!(GraphWithProperties!Size) loadGraphs(int Size)(string filename) {
	import std.file : readText;
	typeof(return) ret;
	auto j = toJSONValue(readText(filename));
	foreach(it; j["graphs"].get!(JSONValue[])) {
		ret.insertBack(GraphWithProperties!Size(it));
	}

	return ret;
}

Array!LNTDimensions genDims(const long numNodes) {
	import utils : bestGridDiffs;
	long[][] dimms = bestGridDiffs(numNodes);
	Array!LNTDimensions ret;
	foreach(long[] d; dimms) {
		/*if(d[0] == 1 || d[1] == 1) {
			continue;
		}*/
		ret.insertBack(LNTDimensions(d[0], d[1]));
	}
	return ret;
}

ProtocolStats!(Size) loadResultss(int Size)(Array!(GraphWithProperties!Size) graphs,
	   	string filename)
{
	const long numNodes = graphs[0].graph.length;
	typeof(return) ret;
	ret.mcs = loadResults!Size(graphs, filename, "MCS", numNodes);
	ret.grid = loadResults!Size(graphs, filename, "Grid", numNodes);
	ret.lattice = loadResults!Size(graphs, filename, "Lattice", numNodes);
	return ret;
}

GraphStatss!(Size) loadResults(int Size)(Array!(GraphWithProperties!Size) graphs,
	   	string filename, string protocol, const long numNodes)
{
	import std.format : format;
	import std.file : exists;
	typeof(return) ret;
	Array!LNTDimensions dims = genDims(numNodes);
	foreach(ref dim; dims[]) {
		ret.data.insertBack(Data!(Size)(dim, Array!(GraphStats!Size)()));
		foreach(ref g; graphs[]) {
			auto fn = format("%s_Results/%05d", filename, g.graph.id);
			if(!exists(fn)) {
				continue;
			}
			//logf("%s", fn);
			ret.data.back.values.insertBack(GraphStats!(Size)(&g, filename, protocol, dim));
		}
	}
	return ret;
}

Data!Size uniqueGraphs(int Size,Selector)(const(GraphStatss!Size) old,
	   	const(LNTDimensions) dim)
{
	return uniqueGraphsImpl1!(Size,Selector)(old, dim);
}

Data!Size uniqueGraphsImpl2(int Size,Selector)(
		const(GraphStatss!Size) old, const(LNTDimensions) dim)
{
	import std.math : approxEqual;
	Data!Size ret;
	foreach(ref it; old.data[]) {
		if(it.key == dim) {
			ret.key = it.key;
			foreach(ref jt; it.values[]) {
				if(ret.empty) {
					ret.values.insertBack(GraphStats!Size(jt));
				} else {
					if(approxEqual(Selector.select(ret.values.back), Selector.select(jt))) {
						//logf("dup %.10f %.10f", Selector.select(ret.back), Selector.select(it));
					} else {
						ret.values.insertBack(GraphStats!Size(jt));
					}
				}
			}
		}
	}
	return ret;
}

Data!Size uniqueGraphsImpl1(int Size,Selector)(
		const(GraphStatss!Size) old, const(LNTDimensions) dim)
{
	import std.math : approxEqual;
	Data!Size ret;
	int addCount = 1;
	foreach(ref it; old.data[]) {
		if(it.key == dim) {
			ret.key = it.key;
			foreach(ref jt; it.values[]) {
				if(ret.values.empty) {
					ret.values.insertBack(GraphStats!Size(jt));
				} else {
					if(approxEqual(Selector.select(ret.values.back),
								Selector.select(jt))) 
					{
						//logf("dup");
						ret.values.back.add(jt);	
						++addCount;
					} else {
						ret.values.back.div(addCount);
						addCount = 1;
						ret.values.insertBack(GraphStats!Size(jt));
					}
				}
			}
		}
	}
	if(addCount > 1) {
		ret.values.back.div(addCount);
	}
	return ret;
}

void statsAna(int Size)(string jsonFileName) {
	import std.format : format;
	import std.math : isNaN;
	import statsanalysisoutput;

	string outdir = format("%s_Ana/", jsonFileName);
	Array!(GraphWithProperties!Size) graphs = loadGraphs!Size(jsonFileName);
	logf("%(%s %)", graphs[]);
	assert(graphs.length > 0);
	Array!LNTDimensions dims = genDims(graphs[0].graph.length);
	//ProtocolStats!(Size) rslts = loadResultss(graphs, jsonFileName);
	ProtocolStats!(Size) rslts;

	//assert(rslt.mcs.data.length == rslt.lattice.data.length);
	//assert(rslt.grid.data.length == rslt.lattice.data.length);

	//Array!LNTDimensions dims = genDims(graphs[0].graph.length);
	//foreach(A; Measures!Size) {
	//	foreach(dim; dims) {
	//		rslt.sort!(A.sortPredicate)();
	//		auto mcs = uniqueGraphs!(Size,A)(rslt.mcs, dim);
	//		auto grid = uniqueGraphs!(Size,A)(rslt.grid, dim);
	//		auto lattice = uniqueGraphs!(Size,A)(rslt.lattice, dim);
	//		logf("\n\tmcs.length %s\n\tgird.length %s\n\tlattice.length %s",
	//			mcs.values.length, grid.values.length, lattice.values.length
	//		);
	//		protocolToOutput!(Size,A)(outdir ~ "MCS", mcs, dim);
	//		protocolToOutput!(Size,A)(outdir ~ "Grid", grid, dim);
	//		protocolToOutput!(Size,A)(outdir ~ "Lattice", lattice, dim);
	//	}
	//}
	topLevelFiles!(Size)(outdir, rslts, graphs, dims);
	//graphsToTex(outdir, graphs);
}

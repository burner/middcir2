module statsanalysis;

import std.container.array;
import std.experimental.logger;
import std.stdio : File;
import std.meta : AliasSeq;
import std.exception : enforce;
import std.math : approxEqual, isNaN;
import std.format : format;

import stdx.data.json.parser;
import stdx.data.json.value;

import graphmeasures;
import graph;
import protocols;
import metameasure;

alias Measures(int Size) = 
	AliasSeq!(
		DiameterAverage!Size, DiameterMedian!Size, DiameterMax!Size,
		DiameterMode!Size,
		Connectivity!Size,
		DegreeAverage!Size, DegreeMedian!Size, DegreeMin!Size, DegreeMax!Size,
		BetweenneesAverage!Size, BetweenneesMedian!Size, BetweenneesMin!Size, BetweenneesMax!Size
	);

struct Connectivity(int Size) {
	static immutable string XLabel = "Connectivity";
	static immutable string sortPredicate = "a.graph.connectivity < b.graph.connectivity";
	static auto select(const(GraphStats!Size) g) nothrow {
		import std.math : isNaN;
		assert(!isNaN(g.graph.connectivity));
		return g.graph.connectivity;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.connectivity;
	}
}

struct DiameterAverage(int Size) {
	static immutable string XLabel = "DiameterAverage";
	static immutable string sortPredicate = "a.graph.diameter.average < b.graph.diameter.average";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.diameter.average;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.diameter.average;
	}
}

struct DiameterMedian(int Size) {
	static immutable string XLabel = "DiameterMedian";
	static immutable string sortPredicate = "a.graph.diameter.median < b.graph.diameter.median";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.diameter.median;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.diameter.median;
	}
}

struct DiameterMode(int Size) {
	static immutable string XLabel = "DiameterMode";
	static immutable string sortPredicate = "a.graph.diameter.mode < b.graph.diameter.mode";
	static auto select(const(GraphStats!Size) g) nothrow {
		return g.graph.diameter.mode;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.diameter.mode;
	}
}

struct DiameterMax(int Size) {
	static immutable string XLabel = "DiameterMax";
	static immutable string sortPredicate = "a.graph.diameter.max < b.graph.diameter.max";
	static auto select(const(GraphStats!Size) g) nothrow {
		return g.graph.diameter.max;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.diameter.max;
	}
}

struct DiameterMin(int Size) {
	static immutable string XLabel = "DiameterMin";
	static immutable string sortPredicate = "a.graph.diameter.min < b.graph.diameter.min";
	static auto select(const(GraphStats!Size) g) nothrow {
		return g.graph.diameter.min;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.degree.min;
	}
}

struct DegreeAverage(int Size) {
	static immutable string XLabel = "DegreeAverage";
	static immutable string sortPredicate = "a.graph.degree.average < b.graph.degree.average";
	static auto select(const(GraphStats!Size) g) nothrow {
		return g.graph.degree.average;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.degree.average;
	}
}

struct DegreeMedian(int Size) {
	static immutable string XLabel = "DegreeMedian";
	static immutable string sortPredicate = "a.graph.degree.median < b.graph.degree.median";
	static auto select(const(GraphStats!Size) g) nothrow {
		return g.graph.degree.median;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.degree.median;
	}
}

struct DegreeMin(int Size) {
	static immutable string XLabel = "DegreeMin";
	static immutable string sortPredicate = "a.graph.degree.min < b.graph.degree.min";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.degree.min;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.degree.min;
	}
}

struct DegreeMax(int Size) {
	static immutable string XLabel = "DegreeMax";
	static immutable string sortPredicate = "a.graph.degree.max < b.graph.degree.max";
	static auto select(const(GraphStats!Size) g) {
		return g.graph.degree.max;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.degree.average;
	}
}

struct BetweenneesAverage(int Size) {
	static immutable string XLabel = "BetweenneesAverage";
	static immutable string sortPredicate = "a.graph.betweenness.average < b.graph.betweenness.average";
	static auto select(const(GraphStats!Size) g) nothrow {
		return g.graph.betweenness.average;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.betweenness.average;
	}
}

struct BetweenneesMedian(int Size) {
	static immutable string XLabel = "BetweenneesMedian";
	static immutable string sortPredicate = "a.graph.betweenness.median < b.graph.betweenness.median";
	static auto select(const(GraphStats!Size) g) nothrow {
		return g.graph.betweenness.median;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.betweenness.median;
	}
}

struct BetweenneesMin(int Size) {
	static immutable string XLabel = "BetweenneesMin";
	static immutable string sortPredicate = "a.graph.betweenness.min < b.graph.betweenness.min";
	static auto select(const(GraphStats!Size) g) nothrow {
		return g.graph.betweenness.min;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
		return g.betweenness.min;
	}
}

struct BetweenneesMax(int Size) {
	static immutable string XLabel = "BetweenneesMax";
	static immutable string sortPredicate = "a.graph.betweenness.max < b.graph.betweenness.max";
	static auto select(const(GraphStats!Size) g) nothrow {
		return g.graph.betweenness.max;
	}
	static auto select(const(GraphWithProperties!Size) g) nothrow {
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

enum AvailOrCosts : bool {
	Avail,
	Cost
}

struct GraphStats(int Size) {
	GraphWithProperties!(Size)* graph;
	Result[7][2] results;

	this(GraphWithProperties!(Size)* g, string filename, string protocol,
			LNTDimensions dim) 
	{
		this.graph = g;
		foreach(ref it; this.results) {
			foreach(ref jt; it) {
				jt = getResult();
			}
		}

		this.loadResults(this.graph.graph.id, filename, "_row_", protocol,
				dim, 0);
		this.loadResults(this.graph.graph.id, filename, "_rowc_", protocol,
				dim, 1);
	}

	this(const(GraphStats!(Size)) old) {
		this.graph = cast(typeof(this.graph))old.graph;
		for(size_t i = 0; i < results.length; ++i) {
			for(size_t j = 0; j < results[i].length; ++j) {
				this.results[i][j] = old.results[i][j].dup;
			}
		}
	}

	void validate() const {
		bool floatCmp(string c, Int)(double a, Int b) {
			mixin("bool cr = a " ~ c ~ "b;");
			if(cr) {
				return true;
			} else {
				return approxEqual(a, cast(double)b);
			}
		}

		enforce(this.graph !is null);
		this.graph.validate();

		foreach(ref it; this.results) {
			foreach(ref jt; it) {
				foreach(kt; jt.readAvail) {
					enforce(isNaN(kt) || 
						(floatCmp!">"(kt, 0.0) && floatCmp!"<"(kt, 1.0)), 
							format("%f", kt)
					);
				}
				foreach(kt; jt.writeAvail) {
					enforce(isNaN(kt) || 
						(floatCmp!">"(kt, 0.0) && floatCmp!"<"(kt, 1.0)), 
							format("%f", kt)
					);
				}
				foreach(kt; jt.readCosts) {
					enforce(isNaN(kt) || 
						(floatCmp!">"(kt, 0.0) && floatCmp!"<"(kt, this.graph.graph.length)), 
							format("%f", kt)
					);
				}
				foreach(kt; jt.writeCosts) {
					enforce(isNaN(kt) || 
						(floatCmp!">"(kt, 0.0) && floatCmp!"<"(kt, this.graph.graph.length)), 
							format("%f", kt)
					);
				}
			}
		}
	}

	ref const(double[101]) getData(const size_t idx, 
			const ResultArraySelect type, const size_t ac) const 
	{
		final switch(type) {
			case ResultArraySelect.ReadAvail:
				return this.results[ac][idx].readAvail;
			case ResultArraySelect.WriteAvail:
				return this.results[ac][idx].writeAvail;
			case ResultArraySelect.ReadCosts:
				return this.results[ac][idx].readCosts;
			case ResultArraySelect.WriteCosts:
				return this.results[ac][idx].writeCosts;
		}
	}

	void add(ref const(GraphStats!Size) other, const size_t ac) {
		for(size_t i = 0; i < results.length; ++i) {
			this.results[ac][i].readAvail[] += other.results[ac][i].readAvail[];
			this.results[ac][i].writeAvail[] += other.results[ac][i].writeAvail[];
			this.results[ac][i].readCosts[] += other.results[ac][i].readCosts[];
			this.results[ac][i].writeCosts[] += other.results[ac][i].writeCosts[];
		}
	}

	void div(int count, const size_t ac) {
		for(size_t i = 0; i < results.length; ++i) {
			this.results[ac][i].readAvail[] /= cast(double)count;
			this.results[ac][i].writeAvail[] /= cast(double)count;
			this.results[ac][i].readCosts[] /= cast(double)count;
			this.results[ac][i].writeCosts[] /= cast(double)count;
		}
	}

	void loadResults(long id, string filename, string availOrCosts, 
			string protocol, LNTDimensions dim, size_t ac) 
	{
		import std.array : empty;
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
				//logf("\n\t%s\n\t%s", a, c);
				string avail = readText(a);
				string costs = readText(c);
				assert(!avail.empty);
				assert(!costs.empty);
				this.results[ac][idx] = Result(avail, costs);	
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

	this(LNTDimensions key, Array!(GraphStats!Size) values) {
		this.key = key;
		this.values = values;
	}

	this(LNTDimensions key) {
		this.key = key;
	}

	void validate() const {
		foreach(ref it; this.values[]) {
			it.validate();
		}
	}
}

struct GraphStatss(int Size) {
	Array!(Data!Size) data;

	void sort(alias Pred)() {
		static import std.algorithm.sorting;
		foreach(ref it; this.data[]) {
			std.algorithm.sorting.sort!(Pred)(it.values[]);
		}
	}

	void sort2(Pred)() {
		static import std.algorithm.sorting;
		foreach(ref it; this.data[]) {
			std.algorithm.sorting.sort!(Pred)(it.values[]);
		}
	}

	void validate() const {
		foreach(ref it; this.data[]) {
			it.validate();
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

	void sort2(Pred)() {
		this.mcs.sort!Pred();
		this.grid.sort!Pred();
		this.lattice.sort!Pred();
	}

	void validate() const {
		this.mcs.validate();
		this.grid.validate();
		this.lattice.validate();
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

	void validate() const {
		enforce(!isNaN(this.diameter.min));
		enforce(!isNaN(this.diameter.mode));
		enforce(!isNaN(this.diameter.max));
		enforce(!isNaN(this.diameter.average));
		enforce(!isNaN(this.diameter.median));

		enforce(!isNaN(this.degree.min));
		enforce(!isNaN(this.degree.mode));
		enforce(!isNaN(this.degree.max));
		enforce(!isNaN(this.degree.average));
		enforce(!isNaN(this.degree.median));

		enforce(!isNaN(this.betweenness.min));
		enforce(!isNaN(this.betweenness.mode));
		enforce(!isNaN(this.betweenness.max));
		enforce(!isNaN(this.betweenness.average));
		enforce(!isNaN(this.betweenness.median));

		enforce(!isNaN(this.connectivity));
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
	Array!LNTDimensions dims;
	if(protocol == "MCS") {
		dims.insertBack(LNTDimensions(0, 0));
	} else {
   		dims = genDims(numNodes);
	}
	foreach(ref dim; dims[]) {
		ret.data.insertBack(Data!(Size)(dim, Array!(GraphStats!Size)()));
		foreach(ref g; graphs[]) {
			auto fn = format("%s_Results/%05d", filename, g.graph.id);
			if(!exists(fn)) {
				continue;
			}
			ret.data.back.values.insertBack(GraphStats!(Size)(&g, filename, protocol, dim));
		}
	}
	return ret;
}

Data!Size uniqueGraphs(int Size,Selector)(const(GraphStatss!Size) old,
	   	const(LNTDimensions) dim)
{
	return uniqueGraphsImpl2!(Size,Selector)(old, dim);
}

Data!Size uniqueGraphsImplDummy(int Size,Selector)(
		const(GraphStatss!Size) old, const(LNTDimensions) dim)
{
	import std.math : approxEqual;
	Data!Size ret;
	foreach(ref it; old.data[]) {
		if(it.key == dim) {
			ret.key = it.key;
			foreach(ref jt; it.values[]) {
				ret.values.insertBack(GraphStats!Size(jt));
			}
		}
	}
	return ret;
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
				if(ret.values.empty) {
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
						for(size_t i = 0; i < 2; ++i) {
							ret.values.back.add(jt, i);	
						}
						++addCount;
					} else {
						for(size_t i = 0; i < 2; ++i) {
							ret.values.back.div(addCount, i);
						}
						addCount = 1;
						ret.values.insertBack(GraphStats!Size(jt));
					}
				}
			}
		}
	}
	if(addCount > 1) {
		for(size_t i = 0; i < 2; ++i) {
			ret.values.back.div(addCount, i);
		}
	}
	return ret;
}

void statsAna(int Size)(string jsonFileName) {
	import std.format : format;
	import std.math : isNaN;
	import statsanalysisoutput;

	string outdir = format("%s_Ana/", jsonFileName);
	string outdirWithoutSlash = format("%s_Ana", jsonFileName);
	Array!(GraphWithProperties!Size) graphs = loadGraphs!Size(jsonFileName);
	logf("%(%s %)", graphs[]);
	assert(graphs.length > 0);
	Array!LNTDimensions dims = genDims(graphs[0].graph.length);
	ProtocolStats!(Size) rslts = loadResultss(graphs, jsonFileName);
	//ProtocolStats!(Size) rslts;

	//assert(rslt.mcs.data.length == rslt.lattice.data.length);
	//assert(rslt.grid.data.length == rslt.lattice.data.length);

	foreach(A; Measures!Size) {
		rslts.sort!(A.sortPredicate)();
		auto mcsDim = LNTDimensions(0, 0);
		auto mcs = uniqueGraphs!(Size,A)(rslts.mcs, mcsDim);
		protocolToOutput!(Size,A)(outdir ~ "MCS", mcs, mcsDim);
		foreach(dim; dims) {
			auto grid = uniqueGraphs!(Size,A)(rslts.grid, dim);
			auto lattice = uniqueGraphs!(Size,A)(rslts.lattice, dim);
			logf("\n\tmcs.length %s\n\tgird.length %s\n\tlattice.length %s",
				mcs.values.length, grid.values.length, lattice.values.length
			);
			protocolToOutput!(Size,A)(outdir ~ "Grid", grid, dim);
			protocolToOutput!(Size,A)(outdir ~ "Lattice", lattice, dim);
		}
	}
	topLevelFiles!(Size)(outdir, rslts, graphs, dims);
	graphsToTex(outdir, graphs);
	superMakefile!Size(outdirWithoutSlash, dims);
}

module statsanalysis;

import std.container.array;
import std.experimental.logger;
import std.algorithm.sorting : sort;
import std.stdio : File;

import graphmeasures;
import graph;
import protocols;

struct DiameterAverage(int Size) {
	static immutable string FolderName = "DiameterAverage";
	static auto select = function(const(GraphStats!Size) g) {
		return g.diameter.average;
	};
}

immutable enum gnuplotString =
`print GPVAL_TERMINALS
set terminal eps color
set border linewidth 1.5
set grid back lc rgb "black"
set ylabel 'Node Availability'
set border 3 back lc rgb "black"
set palette defined (0 0 0 0.5, 1 0 0 1, 2 0 0.5 1, 3 0 1 1, 4 0.5 1 0.5, 5 1 1 0, 6 1 0.5 0, 7 1 0 0, 8 0.5 0 0)
set grid
`;

immutable readOverWriteLevel = [0.01, 0.1, 0.25, 0.50, 0.75, 0.90, 0.99];

enum ResultArraySelect : size_t {
	ReadAvail,
	WriteAvail,
	ReadCosts,
	WriteCosts
}

struct GraphStats(int Size) {
	Graph!Size graph;
	DiameterResult diameter;
	Result[7] results;

	this(Graph!Size g, string filename, string protocol) {
		this.graph = g;
		this.loadResults(this.graph.id, filename, "_row_", protocol);
		this.loadResults(this.graph.id, filename, "_rowc_", protocol);
	}

	this(const(GraphStats!Size) old) {
		this.diameter = old.diameter;
		for(size_t i = 0; i < old.results.length; ++i) {
			this.results[i] = old.results[i].dup();
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
			string protocol) 
	{
		import std.file : dirEntries, SpanMode, readText;
		import std.format : format;
		import std.algorithm.iteration : filter;
		import std.algorithm.searching : canFind;
		import std.range : lockstep;
		string folderName = format("%s_Results/%05d/", filename, id);

		foreach(idx, it; readOverWriteLevel) {
			string s = format("%.2f", it);
			auto filesAvail = dirEntries(folderName, SpanMode.depth)
				.filter!(f =>
					canFind(f.name, "data") 
					&& canFind(f.name, availOrCosts) 
					&& canFind(f.name, protocol)
					&& canFind(f.name, s)
					&& canFind(f.name, "_avail")
				);
			auto filesCosts = dirEntries(folderName, SpanMode.depth)
				.filter!(f =>
					canFind(f.name, "data") 
					&& canFind(f.name, availOrCosts) 
					&& canFind(f.name, protocol)
					&& canFind(f.name, s)
					&& canFind(f.name, "_costs")
				);
			foreach(a, c; lockstep(filesAvail, filesCosts)) {
				//logf("\n\t%s\n\t%s", a, c);
				this.results[idx] = Result(readText(a), readText(c));	
				//logf("readAvail %(%.5f, %)", this.results[idx].readAvail[]);
				//logf("writeAvail %(%.5f, %)", this.results[idx].writeAvail[]);
				//logf("readCosts %(%.5f, %)", this.results[idx].readCosts[]);
				//logf("writeCosts %(%.5f, %)", this.results[idx].writeCosts[]);
			}
		}
	}
}

struct ProtocolStats(int Size) {
	Array!(GraphStats!Size) mcs;
	Array!(GraphStats!Size) grid;
	Array!(GraphStats!Size) lattice;
}

ProtocolStats!Size loadGraphs(int Size)(string filename) {
	import stdx.data.json;
	import std.file : readText;

	ProtocolStats!Size ret;

	auto j = toJSONValue(readText(filename));
	foreach(it; j["graphs"].get!(JSONValue[])) {
		ret.mcs.insertBack(GraphStats!Size(Graph!Size(it), filename, "MCS"));
		ret.grid.insertBack(GraphStats!Size(Graph!Size(it), filename, "Grid"));
		ret.lattice.insertBack(GraphStats!Size(Graph!Size(it), filename, "Lattice"));
	}

	return ret;
}

void protocolToOutput(int Size)(string folder, 
		const(Array!(GraphStats!Size)) protocol)
{
	import std.file : mkdirRecurse;
	import std.format : format;
	import std.meta : AliasSeq;
	foreach(Selector; AliasSeq!(DiameterAverage!Size)) {
		foreach(idx, it; readOverWriteLevel) {
			string folderROW = format("%s/%s/%.2f/", folder, Selector.FolderName, it);
			mkdirRecurse(folderROW);

			foreach(type; [ResultArraySelect.ReadAvail,ResultArraySelect.WriteAvail,
					ResultArraySelect.ReadCosts,ResultArraySelect.WriteCosts])
			{
				File f;
				final switch(type) {
					case ResultArraySelect.ReadAvail:
 						f = File(folderROW ~ "readavailgnuplot.data", "w");	
						break;
					case ResultArraySelect.WriteAvail:
 						f = File(folderROW ~ "writeavailgnuplot.data", "w");	
						break;
					case ResultArraySelect.ReadCosts:
 						f = File(folderROW ~ "readcostsgnuplot.data", "w");	
						break;
					case ResultArraySelect.WriteCosts:
 						f = File(folderROW ~ "writecostsgnuplot.data", "w");	
						break;
				}
				auto ltw = f.lockingTextWriter();
				protocolToOutputImpl!(Size,Selector)(ltw, protocol, idx, type);
			}
		}
	}
}

void protocolToOutputImpl(int Size,Selector,LTW)(LTW ltw,
		const(Array!(GraphStats!Size)) protocol, const size_t idx,
	   	const ResultArraySelect resultSelect)
{
	import std.format : formattedWrite;
	foreach(ref it; protocol[]) {
		auto data = it.getData(idx, resultSelect);
		for(size_t i = 0; i < 101; ++i) {
			formattedWrite(ltw, "%.15f %.15f %.15f\n", 
				Selector.select(it), i/100.0, data[i]
			);
		}
	}
}

Array!(GraphStats!Size) uniqueGraphs(int Size,Selector)(
		const(Array!(GraphStats!Size)) old)
{
	Array!(GraphStats!Size) ret;
	int addCount = 1;
	foreach(ref it; old[]) {
		if(ret.empty) {
			ret.insertBack(GraphStats!Size(it));
		} else {
			if(Selector.select(ret.back) == Selector.select(it)) {
				logf("dup");
				ret.back.add(it);	
				++addCount;
			} else {
				ret.back.div(addCount);
				addCount = 1;
				ret.insertBack(GraphStats!Size(it));
			}
		}
	}
	if(addCount > 1) {
		ret.back.div(addCount);
	}
	return ret;
}

void statsAna(int Size)(string jsonFileName) {
	auto graphs = loadGraphs!Size(jsonFileName);

	foreach(ref it; graphs.mcs) {
		it.diameter = diameter!Size(it.graph);
	}

	sort!"a.diameter.average < b.diameter.average"(graphs.mcs[]);
	logf("%(%s\n\n%)", graphs.mcs[]);
	auto mcs = uniqueGraphs!(Size,DiameterAverage!Size)(graphs.mcs);
	protocolToOutput!(Size)("Stats6", mcs);
}

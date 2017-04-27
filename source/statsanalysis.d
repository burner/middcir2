module statsanalysis;

import std.container.array;
import std.experimental.logger;
import std.algorithm.sorting : sort;
import std.stdio : File;
import std.meta : AliasSeq;

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
	static immutable string sortPredicate = "a.connectivity < b.connectivity";
	static auto select = function(const(GraphStats!Size) g) {
		import std.math : isNaN;
		assert(!isNaN(g.connectivity));
		return g.connectivity;
	};
}

struct DiameterAverage(int Size) {
	static immutable string XLabel = "DiameterAverage";
	static immutable string sortPredicate = "a.diameter.average < b.diameter.average";
	static auto select = function(const(GraphStats!Size) g) {
		return g.diameter.average;
	};
}

struct DiameterMedian(int Size) {
	static immutable string XLabel = "DiameterMedian";
	static immutable string sortPredicate = "a.diameter.median < b.diameter.median";
	static auto select = function(const(GraphStats!Size) g) {
		return g.diameter.median;
	};
}

struct DiameterMax(int Size) {
	static immutable string XLabel = "DiameterMax";
	static immutable string sortPredicate = "a.diameter.max < b.diameter.max";
	static auto select = function(const(GraphStats!Size) g) {
		return g.diameter.max;
	};
}

struct DiameterMin(int Size) {
	static immutable string XLabel = "DiameterMin";
	static immutable string sortPredicate = "a.diameter.min < b.diameter.min";
	static auto select = function(const(GraphStats!Size) g) {
		return g.diameter.min;
	};
}

struct DegreeAverage(int Size) {
	static immutable string XLabel = "DegreeAverage";
	static immutable string sortPredicate = "a.degree.average < b.degree.average";
	static auto select = function(const(GraphStats!Size) g) {
		return g.degree.average;
	};
}

struct DegreeMedian(int Size) {
	static immutable string XLabel = "DegreeMedian";
	static immutable string sortPredicate = "a.degree.median < b.degree.median";
	static auto select = function(const(GraphStats!Size) g) {
		return g.degree.median;
	};
}

struct DegreeMin(int Size) {
	static immutable string XLabel = "DegreeMin";
	static immutable string sortPredicate = "a.degree.min < b.degree.min";
	static auto select = function(const(GraphStats!Size) g) {
		return g.degree.min;
	};
}

struct DegreeMax(int Size) {
	static immutable string XLabel = "DegreeMax";
	static immutable string sortPredicate = "a.degree.max < b.degree.max";
	static auto select = function(const(GraphStats!Size) g) {
		return g.degree.max;
	};
}

struct BetweenneesAverage(int Size) {
	static immutable string XLabel = "BetweenneesAverage";
	static immutable string sortPredicate = "a.betweenness.average < b.betweenness.average";
	static auto select = function(const(GraphStats!Size) g) {
		return g.betweenness.average;
	};
}

struct BetweenneesMedian(int Size) {
	static immutable string XLabel = "BetweenneesMedian";
	static immutable string sortPredicate = "a.betweenness.median < b.betweenness.median";
	static auto select = function(const(GraphStats!Size) g) {
		return g.betweenness.median;
	};
}

struct BetweenneesMin(int Size) {
	static immutable string XLabel = "BetweenneesMin";
	static immutable string sortPredicate = "a.betweenness.min < b.betweenness.min";
	static auto select = function(const(GraphStats!Size) g) {
		return g.betweenness.min;
	};
}

struct BetweenneesMax(int Size) {
	static immutable string XLabel = "BetweenneesMax";
	static immutable string sortPredicate = "a.betweenness.max < b.betweenness.max";
	static auto select = function(const(GraphStats!Size) g) {
		return g.betweenness.max;
	};
}

immutable enum gnuplotString =
`print GPVAL_TERMINALS
set terminal eps color
set border linewidth 1.5
set grid back lc rgb "black"
set ylabel 'Node Availability'
set yrange [-0.05:1.1]
set ylabel 'Operation Availability'
set xlabel '%2$s'
set border 3 back lc rgb "black"
set palette defined (0 0 0 0.5, 1 0 0 1, 2 0 0.5 1, 3 0 1 1, 4 0.5 1 0.5, 5 1 1 0, 6 1 0.5 0, 7 1 0 0, 8 0.5 0 0)
set grid
set output '%1$s.eps'
plot "%1$sgnuplot.data" using 1:2:3 with image
`;

immutable readOverWriteLevel = [0.01, 0.1, 0.25, 0.50, 0.75, 0.90, 0.99];

enum ResultArraySelect : size_t {
	ReadAvail,
	WriteAvail,
	ReadCosts,
	WriteCosts
}

struct GraphStats(int Size) {
	// Make sure to copy all
	Graph!Size graph;
	DiameterResult diameter;
	DegreeResult degree;
	BetweennessCentrality betweenness;
	double connectivity;
	Result[7] results;
	// Make sure to copy all

	this(Graph!Size g, string filename, string protocol) {
		this.graph = g;
		this.loadResults(this.graph.id, filename, "_row_", protocol);
		this.loadResults(this.graph.id, filename, "_rowc_", protocol);
	}

	this(const(GraphStats!Size) old) {
		// Make sure to copy all
		this.diameter = old.diameter;
		this.degree = old.degree;
		this.betweenness = old.betweenness;
		this.connectivity = old.connectivity;
		for(size_t i = 0; i < old.results.length; ++i) {
			this.results[i] = old.results[i].dup();
		}
		// Make sure to copy all
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

void protocolToOutput(int Size,Selector)(string folder, 
		const(Array!(GraphStats!Size)) protocol)
{
	import std.file : mkdirRecurse;
	import std.format : format, formattedWrite;
	foreach(idx, it; readOverWriteLevel) {
		string folderROW = format("%s/%s/%.2f/", folder, Selector.XLabel, it);
		mkdirRecurse(folderROW);

		genGnuplotScripts(folderROW, Selector.XLabel);
		genGnuplotMakefile(folderROW);

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

	string mfn = format("%s/%s/", folder, Selector.XLabel);
	subLevelFiles(mfn);
	subLevelFilesSelector!Size(folder ~ "/");
}

void subLevelFilesSelector(int Size)(string folder) {
	import std.format : formattedWrite;
	{
		auto m = File(folder ~ "Makefile", "w");
		auto mLtw = m.lockingTextWriter();
		formattedWrite(mLtw, "all:\n");
		foreach(Selector; Measures!Size) {
			formattedWrite(mLtw, "\t$(MAKE) -C %s\n", Selector.XLabel);
		}
	}
}

void subLevelFiles(string folder) {
	import std.format : formattedWrite;
	{
		auto m = File(folder ~ "Makefile", "w");
		auto mLtw = m.lockingTextWriter();
		formattedWrite(mLtw, "all:\n");
		foreach(it; readOverWriteLevel) {
			formattedWrite(mLtw, "\t$(MAKE) -C %.2f\n", it);
		}
	}
}

void genGnuplotScripts(string folder, string xlabel) {
	import std.format : format, formattedWrite;

	foreach(it; ["readavail", "writeavail", "readcosts", "writecosts"]) {
		auto f = File(format("%s%s.gp", folder, it), "w");
		formattedWrite(f.lockingTextWriter(), gnuplotString, it, xlabel);
	}
}

void genGnuplotMakefile(string folder) {
	import std.format : format, formattedWrite;

	auto f = File(format("%sMakefile", folder), "w");
	formattedWrite(f.lockingTextWriter(),
		"all: readavail writeavail readcosts writecosts\n" ~
		"readavail:\n" ~
		"	gnuplot readavail.gp\n" ~
		"	epstopdf readavail.eps\n" ~
		"writeavail:\n" ~
		"	gnuplot writeavail.gp\n" ~
		"	epstopdf writeavail.eps\n" ~
		"readcosts:\n" ~
		"	gnuplot readcosts.gp\n" ~
		"	epstopdf readcosts.eps\n" ~
		"writecosts:\n" ~
		"	gnuplot writecosts.gp\n" ~
		"	epstopdf writecosts.eps\n");
}

void topLevelFiles(int Size)(string folder, const size_t numGraphs) {
	import std.format : format, formattedWrite;
	{
		auto m = File(folder ~ "Makefile", "w");
		auto mLtw = m.lockingTextWriter();
		formattedWrite(mLtw, "all:\n");
		formattedWrite(mLtw, "\t$(MAKE) -C MCS\n");
		formattedWrite(mLtw, "\t$(MAKE) -C Grid\n");
		formattedWrite(mLtw, "\t$(MAKE) -C Lattice\n");
	}

	{
		auto l = File(folder ~ "latex.tex", "w");
		auto lltw = l.lockingTextWriter();
		formattedWrite(lltw, "\\documentclass{scrbook}\n");
		formattedWrite(lltw, "\\usepackage{graphicx}\n");
		formattedWrite(lltw, "\\usepackage{standalone}\n");
		formattedWrite(lltw, "\\usepackage{float}\n");
		formattedWrite(lltw, "\\usepackage{hyperref}\n");
		formattedWrite(lltw, "\\usepackage[cm]{fullpage}\n");
		formattedWrite(lltw, "\\usepackage{subcaption}\n");
formattedWrite(lltw, `\usepackage{tikz}
\usepackage{pgfplots}
\usetikzlibrary{decorations.markings, arrows, decorations.pathmorphing,
   backgrounds, positioning, fit, shapes.geometric}
	\tikzstyle{place} = [shape=circle,
    draw, align=center,minimum width=0.70cm,
    top color=white, bottom color=blue!20]
`);
		foreach(proto; ["MCS", "Lattice", "Grid"]) {
			formattedWrite(lltw, "%% rubber: path ./%s/\n", proto);
			foreach(Selector; Measures!Size) {
				formattedWrite(lltw, "%% rubber: path ./%s/%s/\n", proto, Selector.XLabel);
				foreach(it; readOverWriteLevel) {
					formattedWrite(lltw, "%% rubber: path ./%s/%s/%.2f\n",
						proto, Selector.XLabel, it
					);
				}
			}
		}
		formattedWrite(lltw, 
`\begin{document}
\tableofcontents
`);
		foreach(proto; ["MCS", "Lattice", "Grid"]) {
			formattedWrite(lltw, "\n\n\\chapter{%s}\n", proto);
			for(size_t i; i < numGraphs; ++i) {
				formattedWrite(lltw,
`\paragraph{Graph %2%s}
\begin{figure}[H]
	\includestandalone{%1$s/%2$d}
	\caption{%1$s Graph %2$d}
\end{figure}
					`, proto, i
				);
			}
			foreach(Selector; Measures!Size) {
				formattedWrite(lltw, "\n\n\\section{%s}\n", Selector.XLabel);
				foreach(it; readOverWriteLevel) {
					string inputfolder = format("%s/%s/%0.2f", /*folder,*/
							proto, Selector.XLabel, it
					);
					formattedWrite(lltw, "\n\n\\paragraph{Write over Read %.02f}\n", it);
					formattedWrite(lltw, 
`\begin{figure}[H]
	\begin{subfigure}[b]{0.5\textwidth}
		\centering
		\includegraphics[width=1.05\textwidth]{%1$s/readavail.pdf}
		\caption{Read Availability}
	\end{subfigure}
	\begin{subfigure}[b]{0.5\textwidth}
		\centering
		\includegraphics[width=1.05\textwidth]{%1$s/writeavail.pdf}
		\caption{Read Availability}
	\end{subfigure}
	\caption{Availability}
\end{figure}
\begin{figure}[H]
	\begin{subfigure}[b]{0.5\textwidth}
		\centering
		\includegraphics[width=1.05\textwidth]{%1$s/readcosts.pdf}
		\caption{Read Availability}
	\end{subfigure}
	\begin{subfigure}[b]{0.5\textwidth}
		\centering
		\includegraphics[width=1.05\textwidth]{%1$s/writecosts.pdf}
		\caption{Read Availability}
	\end{subfigure}
	\caption{Costs}
\end{figure}
`, inputfolder);
				}
			}
		}
		formattedWrite(lltw, "\\end{document}\n");
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
	return uniqueGraphsImpl2!(Size,Selector)(old);
}

Array!(GraphStats!Size) uniqueGraphsImpl2(int Size,Selector)(
		const(Array!(GraphStats!Size)) old)
{
	import std.math : approxEqual;
	Array!(GraphStats!Size) ret;
	foreach(ref it; old[]) {
		if(ret.empty) {
			ret.insertBack(GraphStats!Size(it));
		} else {
			if(approxEqual(Selector.select(ret.back), Selector.select(it))) {
				//logf("dup %.10f %.10f", Selector.select(ret.back), Selector.select(it));
			} else {
				ret.insertBack(GraphStats!Size(it));
			}
		}
	}
	return ret;
}

Array!(GraphStats!Size) uniqueGraphsImpl1(int Size,Selector)(
		const(Array!(GraphStats!Size)) old)
{
	import std.math : approxEqual;
	Array!(GraphStats!Size) ret;
	int addCount = 1;
	foreach(ref it; old[]) {
		if(ret.empty) {
			ret.insertBack(GraphStats!Size(it));
		} else {
			if(approxEqual(Selector.select(ret.back), Selector.select(it))) {
				//logf("dup");
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

void graphsToTex(int Size)(string foldername, const ref ProtocolStats!Size pss) {
	import std.format : format;
	foreach(pro; ["MCS", "Lattice", "Grid"]) {
		auto f = format("%s%s/", foldername, pro);
		if(pro == "MCS") {
			graphsToTexImpl(f, pss.mcs);
		} else if(pro == "Lattice") {
			graphsToTexImpl(f, pss.lattice);
		} else if(pro == "Grid") {
			graphsToTexImpl(f, pss.grid);
		}
	}
}

void graphsToTexImpl(int Size)(string foldername, 
		const ref Array!(GraphStats!Size) gs) 
{
	import std.format : format;
	foreach(const ref it; gs[]) {
		string fn = format("%s%d.tex", foldername, it.graph.id);
		auto f = File(fn, "w");
		auto ltw = f.lockingTextWriter();
		it.graph.toTikz(ltw);
	}
}

void statsAna(int Size)(string jsonFileName) {
	import std.format : format;
	import std.math : isNaN;
	auto graphs = loadGraphs!Size(jsonFileName);
	assert(graphs.mcs.length == graphs.lattice.length);
	assert(graphs.grid.length == graphs.lattice.length);
	string outdir = format("%s_Ana/", jsonFileName);
	graphsToTex(outdir, graphs);

	foreach(ref it; graphs.mcs) {
		it.diameter = diameter!Size(it.graph);
		it.connectivity = computeConnectivity(it.graph);
		it.degree = degree(it.graph);
		it.betweenness = betweennessCentrality(it.graph);
		assert(!isNaN(it.connectivity));
		logf("%f", it.connectivity);
	}
	foreach(ref it; graphs.grid) {
		it.diameter = diameter!Size(it.graph);
		it.connectivity = computeConnectivity(it.graph);
		it.degree = degree(it.graph);
		it.betweenness = betweennessCentrality(it.graph);
		assert(!isNaN(it.connectivity));
		logf("%f", it.connectivity);
	}
	foreach(ref it; graphs.lattice) {
		it.diameter = diameter!Size(it.graph);
		it.connectivity = computeConnectivity(it.graph);
		it.degree = degree(it.graph);
		it.betweenness = betweennessCentrality(it.graph);
		assert(!isNaN(it.connectivity));
		logf("%f", it.connectivity);
	}

	foreach(A; Measures!Size) {
		sort!(A.sortPredicate)(graphs.mcs[]);
		sort!(A.sortPredicate)(graphs.grid[]);
		sort!(A.sortPredicate)(graphs.lattice[]);
		auto mcs = uniqueGraphs!(Size,A)(graphs.mcs);
		auto grid = uniqueGraphs!(Size,A)(graphs.grid);
		auto lattice = uniqueGraphs!(Size,A)(graphs.lattice);
		logf("\n\tmcs.length %s\n\tgird.length %s\n\tlattice.length %s",
			mcs.length, grid.length, lattice.length
		);
		protocolToOutput!(Size,A)(outdir ~ "MCS", mcs);
		protocolToOutput!(Size,A)(outdir ~ "Grid", grid);
		protocolToOutput!(Size,A)(outdir ~ "Lattice", lattice);
	}
	topLevelFiles!Size(outdir, graphs.mcs.length);
}

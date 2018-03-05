module protocols.circle;

import std.experimental.logger;
import std.stdio;
import std.typecons : Flag;
import std.math : approxEqual, isNaN;
import std.container.array : Array;
import std.algorithm.searching : canFind;
import std.algorithm.iteration: sum;
import std.algorithm.sorting : sort;
import std.typecons : isIntegral, Nullable;
import std.format;
import std.conv : to;
import std.file : readText;
import std.algorithm.iteration : splitter;
import std.array : split, front, back;

import gfm.math.vector;
import fixedsizearray;

import graphmeasures : computeMode;
import plot : ResultPlot;
import plot.gnuplot;
import graphgen;
import graphisomorph;
import graphisomorph2;
import protocols.crossing;
import bitsetrbtree;
import bitsetmodule;
import graph;
import protocols;
import permutation;
import config;
import floydmodule;
import utils : percentile;

double nanToNull(double v) {
	return isNaN(v) ? 0.0 : v;
}

struct MinMaxMode {
	double min;
	double q25;
	double average;
	double median;
	double q75;
	double max;
}

struct ManyResults {
	double[][101] readAvail;
	double[][101] writeAvail;
	double[][101] readCosts;
	double[][101] writeCosts;

	MinMaxMode[101] readAvailMode;
	MinMaxMode[101] writeAvailMode;
	MinMaxMode[101] readCostsMode;
	MinMaxMode[101] writeCostsMode;
}

void loadResults(string folderName, ref ManyResults mr) {
	auto availLines = readText(folderName ~ "/Circledatafileavail.rslt")
		.splitter("\n");
	auto costLines = readText(folderName ~ "/Circledatafilecost.rslt")
		.splitter("\n");

	for(size_t i = 0; i < 101; ++i) {
		auto availLine = availLines.front.split();
		double ra = to!double(availLine[1]);
		double wa = to!double(availLine[2]);

		auto costLine = costLines.front.split();
		double rc = to!double(costLine[1]);
		double wc = to!double(costLine[2]);

		logf("avail %s %s cost %s %s", ra, wa, rc, wc);
		availLines.popFront();
		costLines.popFront();

		mr.readAvail[i] ~= ra;
		mr.writeAvail[i] ~= wa;
		mr.readCosts[i] ~= rc;
		mr.writeCosts[i] ~= wc;
	}

	for(size_t i = 0; i < 101; ++i) {
		sort(mr.readAvail[i]);
		sort(mr.writeAvail[i]);
		sort(mr.readCosts[i]);
		sort(mr.writeCosts[i]);

		mr.readAvailMode[i].min = mr.readAvail[i].front;
		mr.readAvailMode[i].q25 = percentile(mr.readAvail[i], 0.25);
		mr.readAvailMode[i].median = percentile(mr.readAvail[i], 0.50);
		mr.readAvailMode[i].average = sum(mr.readAvail[i], 0.0) / mr.readAvail[i].length;
		mr.readAvailMode[i].q75 = percentile(mr.readAvail[i], 0.75);
		mr.readAvailMode[i].max = mr.readAvail[i].back;

		mr.writeAvailMode[i].min = mr.writeAvail[i].front;
		mr.writeAvailMode[i].q25 = percentile(mr.writeAvail[i], 0.25);
		mr.writeAvailMode[i].median = percentile(mr.writeAvail[i], 0.50);
		mr.writeAvailMode[i].average = sum(mr.writeAvail[i], 0.0) / mr.writeAvail[i].length;
		mr.writeAvailMode[i].q75 = percentile(mr.writeAvail[i], 0.75);
		mr.writeAvailMode[i].max = mr.writeAvail[i].back;

		mr.readCostsMode[i].min = mr.readCosts[i].front;
		mr.readCostsMode[i].q25 = percentile(mr.readCosts[i], 0.25);
		mr.readCostsMode[i].median = percentile(mr.readCosts[i], 0.50);
		mr.readCostsMode[i].average = sum(mr.readCosts[i], 0.0) / mr.readCosts[i].length;
		mr.readCostsMode[i].q75 = percentile(mr.readCosts[i], 0.75);
		mr.readCostsMode[i].max = mr.readCosts[i].back;

		mr.writeCostsMode[i].min = mr.writeCosts[i].front;
		mr.writeCostsMode[i].q25 = percentile(mr.writeCosts[i], 0.25);
		mr.writeCostsMode[i].median = percentile(mr.writeCosts[i], 0.50);
		mr.writeCostsMode[i].average = sum(mr.writeCosts[i], 0.0) / mr.writeCosts[i].length;
		mr.writeCostsMode[i].q75 = percentile(mr.writeCosts[i], 0.75);
		mr.writeCostsMode[i].max = mr.writeCosts[i].back;
	}
}

void manyCircles(string filename, string resultFolderName) {
	import std.file : mkdirRecurse;
	mkdirRecurse(resultFolderName);

	auto f = File(resultFolderName ~ "/result.tex", "w");
	auto fLtw = f.lockingTextWriter();
	prepareLatexDoc(fLtw);
	size_t ok = 0;

	ManyResults mr;

	auto graphs = loadGraphsFromJSON!(32)(filename);
	for(size_t i = 0; i < graphs.length; ++i) {
		formattedWrite(fLtw, "\\section{Graph %s}\n", i);
		formattedWrite(fLtw, "\\begin{figure}\n");
		formattedWrite(fLtw, "\\includestandalone{graph%d/graph}\n", i);
		formattedWrite(fLtw, "\\end{figure}\n");

		auto fnG = format("%s/graph%d/", resultFolderName, i);
		auto fnGg = fnG ~ "graph.tex";
		mkdirRecurse(fnG);
		auto f2 = File(fnGg, "w");
		auto f2Ltw = f2.lockingTextWriter();
		graphs[i].toTikz(f2Ltw);
		try {
			auto cur = CirclesImpl!32(graphs[i]);
			Result curRslt = cur.calcAC();
			gnuPlot(fnG, "", ResultPlot("Circle", curRslt));
			formattedWrite(fLtw, "\\begin{figure}\n");
			formattedWrite(fLtw, "\\includegraphics{graph%d/1resultavail}\n", i);
			formattedWrite(fLtw, "\\caption{graph %d availability}\n", i);
			formattedWrite(fLtw, "\\end{figure}\n");
			formattedWrite(fLtw, "\\begin{figure}\n");
			formattedWrite(fLtw, "\\includegraphics{graph%d/1resultcost}\n", i);
			formattedWrite(fLtw, "\\caption{graph %d cost}\n", i);
			formattedWrite(fLtw, "\\end{figure}\n");
			++ok;
			loadResults(fnG, mr);
		} catch(Exception e) {
			logf("Unable to find border for graph %d %s", i, e.toString());
			formattedWrite(fLtw, "Unable to process graph with Circle Protocol\n");
		}
	}

	formattedWrite(fLtw, "\\section{Results}\n");
	formattedWrite(fLtw, "%d out of %d worked", ok, graphs.length);
	logf("%s", mr);
	manyResultsToFile(resultFolderName, mr);
	formattedWrite(fLtw, "\\end{document}");
}

void manyResultsToFile(string foldername, ref ManyResults mr) {
	auto fnG = format("%s/", foldername);
	{
		auto fnGg = fnG ~ "Makefile";
		auto f = File(fnGg, "w");
		auto ltw = f.lockingTextWriter();
		string make = `all: readavail.pdf writeavail.pdf readcosts.pdf writecosts.pdf 

readavail.pdf: readavail.tex
	xelatex readavail.tex

writeavail.pdf: writeavail.tex
	xelatex writeavail.tex

readcosts.pdf: readcosts.tex
	xelatex readcosts.tex

writecosts.pdf: writecosts.tex
	xelatex writecosts.tex

readavail.tex: readavail.gp readavail.rslt
	gnuplot readavail.gp

writeavail.tex: writeavail.gp writeavail.rslt
	gnuplot writeavail.gp

readcosts.tex: readcosts.gp readcosts.rslt
	gnuplot readcosts.gp

writecosts.tex: writecosts.gp writecosts.rslt
	gnuplot writecosts.gp
`;
		formattedWrite(ltw, make);
	}
	{
		auto fnGg = fnG ~ "readavail.rslt";
		auto f = File(fnGg, "w");
		auto ltw = f.lockingTextWriter();
		for(size_t i = 0; i < 101; ++i) {
			formattedWrite(ltw,
				"%15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f\n",
				i / 100.0, 
				nanToNull(mr.readAvailMode[i].min),
				nanToNull(mr.readAvailMode[i].q25),
				nanToNull(mr.readAvailMode[i].average),
				nanToNull(mr.readAvailMode[i].median),
				nanToNull(mr.readAvailMode[i].q75),
				nanToNull(mr.readAvailMode[i].max),
				i / 100.0, 
			);
		}
		immutable(string) gpAvail = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex color standalone
set xrange [0.000000:1.0]
set yrange [:1.0]
set output 'readavail.tex'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data boxplot
#set key at 50,112
set xlabel 'Replica Availability (p)'
set ylabel 'Read Availability' offset 1,0
set tics scale 0.75
plot 'readavail.rslt' using 1:3:2:7:6 with candlesticks notitle whiskerbars, \
'' using 1:4:4:4:4 with candlesticks lt -1 notitle, \
'' using 1:5:5:5:5 with candlesticks lt -1 lc 'red' notitle, \
'' using 1:8 with lines lc '#00BFFF' linewidth 4 notitle
`;
		auto f2 = File(fnG ~ "readavail.gp", "w");
		auto ltw2 = f2.lockingTextWriter();
		formattedWrite(ltw2, gpAvail);
	}
	{
		auto fnGg = fnG ~ "writeavail.rslt";
		auto f = File(fnGg, "w");
		auto ltw = f.lockingTextWriter();
		for(size_t i = 0; i < 101; ++i) {
			formattedWrite(ltw,
				"%15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f\n",
				i / 100.0, 
				nanToNull(mr.writeAvailMode[i].min),
				nanToNull(mr.writeAvailMode[i].q25),
				nanToNull(mr.writeAvailMode[i].average),
				nanToNull(mr.writeAvailMode[i].median),
				nanToNull(mr.writeAvailMode[i].q75),
				nanToNull(mr.writeAvailMode[i].max),
				i / 100.0
			);
		}
		immutable(string) gpAvail = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex color standalone
set xrange [0.000000:1.0]
set yrange [:1.0]
set output 'writeavail.tex'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data boxplot
#set key at 50,112
set xlabel 'Replica Availability (p)'
set ylabel 'Write Availability' offset 1,0
set tics scale 0.75
plot 'writeavail.rslt' using 1:3:2:7:6 with candlesticks notitle whiskerbars, \
'' using 1:4:4:4:4 with candlesticks lt -1 notitle, \
'' using 1:5:5:5:5 with candlesticks lt -1 lc 'red' notitle, \
'' using 1:8 with lines lc '#00BFFF' linewidth 4 notitle
`;
		auto f2 = File(fnG ~ "writeavail.gp", "w");
		auto ltw2 = f2.lockingTextWriter();
		formattedWrite(ltw2, gpAvail);
	}
	{
		auto fnGg = fnG ~ "readcosts.rslt";
		auto f = File(fnGg, "w");
		auto ltw = f.lockingTextWriter();
		for(size_t i = 0; i < 101; ++i) {
			formattedWrite(ltw,
				"%15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f\n",
				i / 100.0, 
				nanToNull(mr.readCostsMode[i].min),
				nanToNull(mr.readCostsMode[i].q25),
				nanToNull(mr.readCostsMode[i].average),
				nanToNull(mr.readCostsMode[i].median),
				nanToNull(mr.readCostsMode[i].q75),
				nanToNull(mr.readCostsMode[i].max)
			);
		}
		immutable(string) gpAvail = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex color standalone
set xrange [0.000000:1.0]
set output 'readcosts.tex'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data boxplot
#set key at 50,112
set xlabel 'Replica Availability (p)'
set ylabel 'Read Costs' offset 1,0
set tics scale 0.75
plot 'readcosts.rslt' using 1:3:2:7:6 with candlesticks notitle whiskerbars, \
'' using 1:4:4:4:4 with candlesticks lt -1 notitle, \
'' using 1:5:5:5:5 with candlesticks lt -1 lc 'red' notitle
`;
		auto f2 = File(fnG ~ "readcosts.gp", "w");
		auto ltw2 = f2.lockingTextWriter();
		formattedWrite(ltw2, gpAvail);
	}
	{
		auto fnGg = fnG ~ "writecosts.rslt";
		auto f = File(fnGg, "w");
		auto ltw = f.lockingTextWriter();
		for(size_t i = 0; i < 101; ++i) {
			formattedWrite(ltw,
				"%15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f\n",
				i / 100.0, 
				nanToNull(mr.writeCostsMode[i].min),
				nanToNull(mr.writeCostsMode[i].q25),
				nanToNull(mr.writeCostsMode[i].average),
				nanToNull(mr.writeCostsMode[i].median),
				nanToNull(mr.writeCostsMode[i].q75),
				nanToNull(mr.writeCostsMode[i].max)
			);
		}
		immutable(string) gpAvail = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex color standalone
set xrange [0.000000:1.0]
set output 'writecosts.tex'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data boxplot
#set key at 50,112
set xlabel 'Replica Availability (p)'
set ylabel 'Write Costs' offset 1,0
set tics scale 0.75
plot 'writecosts.rslt' using 1:3:2:7:6 with candlesticks notitle whiskerbars, \
'' using 1:4:4:4:4 with candlesticks lt -1 notitle, \
'' using 1:5:5:5:5 with candlesticks lt -1 lc 'red' notitle
`;
		auto f2 = File(fnG ~ "writecosts.gp", "w");
		auto ltw2 = f2.lockingTextWriter();
		formattedWrite(ltw2, gpAvail);
	}
}

void prepareLatexDoc(LTW)(ref LTW ltw) {
	formattedWrite(ltw, "\\documentclass[crop=false,class=scrbook]{standalone}\n");
	formattedWrite(ltw, "\\usepackage{graphicx}\n");
	formattedWrite(ltw, "\\usepackage{standalone}\n");
	formattedWrite(ltw, "\\usepackage{float}\n");
	formattedWrite(ltw, "\\usepackage{multirow}\n");
	formattedWrite(ltw, "\\usepackage{hyperref}\n");
	formattedWrite(ltw, "\\usepackage{placeins}\n");
	formattedWrite(ltw, "\\usepackage[cm]{fullpage}\n");
	formattedWrite(ltw, "\\usepackage{subcaption}\n");
	formattedWrite(ltw, `\usepackage{tikz}
\usepackage{pgfplots}
\usetikzlibrary{decorations.markings, arrows, decorations.pathmorphing,
   backgrounds, positioning, fit, shapes.geometric}
	\tikzstyle{place} = [shape=circle,
    draw, align=center,minimum width=0.70cm,
    top color=white, bottom color=blue!20]
\setcounter{tocdepth}{5}
\begin{document}
`);
}

double sumResult(ref Result curRslt, const double writeBalance) {
	import utils : sum;

	return sum(curRslt.writeAvail)  * writeBalance + sum(curRslt.readAvail) * 1.0 - writeBalance;
}

struct CircleImplResult(int Size) {
	CircleImpl!Size cirImpl;
	Result result;
	int mid;

	this(CircleImpl!Size cir) {
		this.cirImpl = cir;
	}
}

alias Circles = CirclesImpl!32;

struct CirclesImpl(int Size) {
	alias BSType = TypeFromSize!Size;

	double bestResult = 0.0;
	size_t bestIdx = size_t.max;
	Array!int border;

	Graph!Size graph;
	this(ref Graph!Size graph) {
		this.graph = graph;
	}

	Result calcAC() {
		Result ret;

		Array!(CircleImplResult!Size) cirImpls;

		this.border = this.graph.computeBorder();
		Array!int uniqueBorder;

		makeArrayUnique!BSType(this.border, uniqueBorder);

		for(int mid = 0; mid < this.graph.length; ++mid) {
			if(canFind(uniqueBorder[], mid)) {
				continue;
			}
			logf("%s", mid);
			
			cirImpls.insertBack(CircleImplResult!(Size)(
					CircleImpl!(Size)(uniqueBorder, mid))
				);
			cirImpls.back.mid = mid;
			cirImpls.back.result = cirImpls.back.cirImpl.calcAC(this.graph);
		}

		for(size_t i = 0; i < cirImpls.length; ++i) {
			double s = sumResult(cirImpls[i].result, 0.5);
			logf("%15.13f > %15.13f mid %s", bestResult, s, cirImpls[i].mid);
			if(s > bestResult) {
				bestIdx = i;
				bestResult = s;
			}
		}

		if(bestIdx != size_t.max) {
			logf("best one found idx %s mid %s %15.13f", bestIdx,
					cirImpls[bestIdx].mid, bestResult
				);
			return cirImpls[bestIdx].result;
		}
		logf("default one found");
		return ret;
	}
}

struct CircleImpl(int Size) {
	alias BSType = TypeFromSize!Size;
	Array!int border;
	int center;
	BitsetStore!(BSType) store;

	this(ref Array!int border, const int center) {
		this.border = border;
		this.center = center;
	}

	Result calcAC(ref Graph!Size graph) {
		Result ret;
		auto permu = PermutationsImpl!BSType(
			cast(int)graph.length,
			1,
			getConfig().permutationStop(cast(int)graph.length)
		);
		auto last = 0;
		foreach(perm; permu) {
			auto cur = popcnt(perm.store);
			//logf("%s, %s", cur, perm.toString());
			auto f = this.store.search(perm);
			if(!f.isNull()) {
				//logf("found superset %s", (*f).bitset.toString());
				(*f).subsets ~= perm;
				continue;
			}

			bool cir = pathOutExists!Size(graph, perm, this.border, this.center);
			auto fr = floyd(graph);
			fr.execute(graph, perm);

			FixedSizeArray!(FixedSizeArray!(BSType)) paths;
			buildPaths!(Size)(fr, graph, this.border, this.center,
					paths);

			size_t maxLen = size_t.max;
			size_t idx = size_t.max;
			for(size_t i = 0; i < paths.length; ++i) {
				if(paths[i].length < maxLen) {
					maxLen = paths[i].length;
					idx = i;
				}
			}

			if(cir && maxLen != size_t.max) {
				if(cur < maxLen) {
					//logf("cir around mid %s", perm.toString());
					this.store.insert(perm);
				} else {
					//logf("path to center better %s", paths[idx]);
					Bitset!BSType tmp;
					foreach(it; paths[idx]) {
						tmp.set(it);
					}
					this.store.insert(tmp);
				}
			} else if(!cir && maxLen != size_t.max) {
				//logf("path to center %s", paths[idx]);
				Bitset!BSType tmp;
				foreach(it; paths[idx]) {
					tmp.set(it);
				}
				this.store.insert(tmp);
			}
		}

		return calcAvailForTree(to!int(graph.length),
				this.store, this.store
			);
	}
}

void buildPaths(int Size,FLY)(ref FLY fr, 
		ref Graph!Size graph, ref Array!int border, const int center, 
		ref FixedSizeArray!(FixedSizeArray!(TypeFromSize!Size)) paths)
{
	foreach(it; border[]) {
		if(fr.pathExists(it, center)) {
			paths.insertBack(FixedSizeArray!(TypeFromSize!Size)());
			fr.path(it, center, paths.back);
		}
	}
}

bool pathOutExists(int Size)(ref Graph!Size graph, 
		Bitset!(TypeFromSize!(Size)) innerBorder, ref Array!int border, const int center)
{
	auto innerBorderFlip = innerBorder;
	innerBorderFlip.flip();
	foreach(it; border[]) {
		innerBorderFlip.set(it);
	}
	auto fr = floyd(graph);
	fr.execute(graph, innerBorderFlip);	

	foreach(it; border[]) {
		if(fr.pathExists(it, center)) {
			return true;
		}
	}
	return false;
}

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
import planar;
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

struct CirResult {
	Result result;
	CirclesImpl!32 cir;
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
		logf("graph %s of %s", i, graphs.length);

		Array!(Graph!32) planarGraphs;
		makePlanar(graphs[i], planarGraphs);
		logf("%s planar graphs", planarGraphs.length);

		Array!(CirResult) results;
		foreach(it; planarGraphs[]) {
			if(!isConnected(it)) {
				logf("Planar graph is no longer connected");
				continue;
			}
			try {
				auto cur = CirclesImpl!32(it);
				Result curRslt = cur.calcAC();
				CirResult tmp;
				tmp.result = curRslt;
				tmp.cir = cur;
				results.insertBack(tmp);
			} catch(Exception e) {
				logf("Unable to find border for graph %d %s", i, e.toString());
			}
		}

		if(results.empty) {
			continue;
		} else {
			logf("turned one graph into %s graphs %s", planarGraphs.length, results.length);
		}

		sort!((a,b) => a.result.awr() > b.result.awr())(results[]);

		try {
			formattedWrite(fLtw, "\\section{Graph %s}\n", i);
			formattedWrite(fLtw, "center %s\\\n", results.front.cir.center);
			formattedWrite(fLtw, "outside %(%s, %)\n",
					results.front.cir.best.border[]);
			formattedWrite(fLtw, "graph %s\n",
					results.front.cir.best.graphSave.toString());
			formattedWrite(fLtw, "\\begin{figure}\n");
			formattedWrite(fLtw, "\\includestandalone{graph%d/graph}\n", i);
			formattedWrite(fLtw, "\\end{figure}\n");

			auto fnG = format("%s/graph%d/", resultFolderName, i);
			auto fnGg = fnG ~ "graph.tex";
			mkdirRecurse(fnG);
			auto f2 = File(fnGg, "w");
			auto f2Ltw = f2.lockingTextWriter();
			results.front.cir.graph.toTikz(f2Ltw);
			Result curRslt = results.front.result;
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
	int center;
	CircleImpl!(Size) best;

	Graph!Size graph;
	this(ref Graph!Size graph) {
		this.graph = graph;
	}

	Result calcAC() {
		import utils;
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
			logf("quorum intersection");
			testQuorumIntersection(cirImpls.back.cirImpl.store,
					cirImpls.back.cirImpl.store);
			//logf("all subsets smaller");
			//testAllSubsetsSmaller(cirImpls.back.store, cirImpls.back.store);
		}

		if(cirImpls.empty) {
			throw new Exception("no valid middle found");
		}

		for(size_t i = 0; i < cirImpls.length; ++i) {
			double s = sumResult(cirImpls[i].result, 0.5);
			logf("%15.13f > %15.13f mid %s", bestResult, s, cirImpls[i].mid);
			if(s > bestResult) {
				bestIdx = i;
				bestResult = s;
				this.center = cirImpls[i].mid;
				this.best = cirImpls[i].cirImpl;
			}
		}

		if(bestIdx != size_t.max) {
			logf("best one found idx %s mid %s %15.13f", bestIdx,
					cirImpls[bestIdx].mid, bestResult
				);
			return cirImpls[bestIdx].result;
		}
		//testSemetry(cirImpls[bestIdx].result);
		logf("default one found");
		return ret;
	}
}

struct CircleImpl(int Size) {
	import exceptionhandling;
	alias BSType = TypeFromSize!Size;
	Array!int border;
	int center;
	BitsetStore!(BSType) store;
	Graph!Size graphSave;

	this(ref Array!int border, const int center) {
		this.border = border;
		this.center = center;
	}

	Result calcAC(ref Graph!Size graph) {
		this.graphSave = graph;
		Result ret;
		auto permu = PermutationsImpl!BSType(
			cast(int)graph.length,
			2,
			getConfig().permutationStop(cast(int)graph.length)
		);
		auto last = 0;
		outer: foreach(perm; permu) {
			auto curCount = popcnt(perm.store);
			//logf("%s, %s", cur, perm.toString());
			auto f = this.store.search(perm);
			if(!f.isNull()) {
				//logf("found superset %s %s", (*f).bitset.toString(),
				//		perm.toString());
				(*f).subsets ~= perm;
				continue;
			}

			auto dir = shortestPathOutside!Size(graph, this.border,
					this.center, perm
				);
			auto dirBS = bitset!(TypeFromSize!Size,int)(dir.path);

			bool sm = surroundsMiddle!Size(graph, this.border, this.center,
					perm
				);

			if(dir.pathExists == PathOutsideExists.yes && sm) {
				if(dir.path.length < curCount) {
					this.store.insert(perm);
				} else {
					this.store.insert(perm);
				}
			} else if(dir.pathExists == PathOutsideExists.yes && !sm) {
				this.store.insert(perm);
			} else if(dir.pathExists != PathOutsideExists.yes && sm) {
				this.store.insert(perm);
			}

		}

		return calcAvailForTree(to!int(graph.length),
				this.store, this.store
			);
	}

	/+Result calcAC(ref Graph!Size graph) {
		Result ret;
		auto permu = PermutationsImpl!BSType(
			cast(int)graph.length,
			1,
			getConfig().permutationStop(cast(int)graph.length)
		);
		auto last = 0;
		outer: foreach(perm; permu) {
			auto cur = popcnt(perm.store);
			//logf("%s, %s", cur, perm.toString());
			auto f = this.store.search(perm);
			if(!f.isNull()) {
				//logf("found superset %s %s", (*f).bitset.toString(),
				//		perm.toString());
				(*f).subsets ~= perm;
				continue;
			}

			// test if there is a way out from the border
			bool cir = pathOutExists!Size(graph, perm, this.border, this.center);
			bool isBorderQuorum = false;
			if(cir) {
				// true means that the middle could break out
				//logf("mid could break out");
				continue;
			} else {
				// the middle could not break out
				// if perm has a element in border we have a circle
				foreach(it; this.border[]) {
					if(perm.test(it)) {
						//logf("perm enclosed mid and touched outer");
						isBorderQuorum = true;
						break;
					}
				}
			}

			//if(isBorderQuorum) {
			//	this.store.insert(perm);
			//}

			auto fr = floyd(graph);
			fr.execute(graph, perm);

			Bitset!(TypeFromSize!(Size)) fin;
			auto spm = buildShortestPath!(Size)(fr, graph, this.border, this.center);

			if(spm.empty && isBorderQuorum) {
				//this.store.insert(perm);
				fin = perm;
			} else if(!spm.empty && isBorderQuorum 
					&& spm.length <= perm.count()) 
			{
				Bitset!BSType tmp;
				foreach(it; spm[]) {
					tmp.set(it);
				}
				fin = tmp;
			} else if(!spm.empty && isBorderQuorum 
					&& spm.length > perm.count()) 
			{
				//this.store.insert(perm);
				fin = perm;
			} else if(!spm.empty && !isBorderQuorum) {
				Bitset!BSType tmp;
				foreach(it; spm[]) {
					tmp.set(it);
				}
				//this.store.insert(tmp);
				fin = tmp;
			} else {
				continue outer;
				//throw new Exception("something strange happened");
			}

			/*for(size_t i = 0; i < graph.length; ++i) {
				if(fin.test(i)) {
					writef("%s, ", i);
				}
			}
			writeln();
			*/

			this.store.insert(fin);

			/*FixedSizeArray!(FixedSizeArray!(BSType)) paths;
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

			Bitset!BSType tmp;
			if(maxLen != size_t.max) {
				//logf("path to center better %s", paths[idx]);
				foreach(it; paths[idx]) {
					tmp.set(it);
				}
			}
			if(isBorderQuorum) {
				if(perm.count() < maxLen) {
					this.store.insert(perm);
					continue outer;
				} 
			}
			if(maxLen != size_t.max) {
				this.store.insert(tmp);
			}*/
		}

		return calcAvailForTree(to!int(graph.length),
				this.store, this.store
			);
	}+/
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

FixedSizeArray!(TypeFromSize!Size) buildShortestPath(int Size,FLY)(ref FLY fr, 
		ref Graph!Size graph, ref Array!int border, const int center)
{
	FixedSizeArray!(TypeFromSize!Size) cur;
	FixedSizeArray!(TypeFromSize!Size) best;
	foreach(it; border[]) {
		if(fr.pathExists(it, center)) {
			fr.path(it, center, cur);
			if(best.empty) {
				best = cur;
			} else if(cur.length < best.length) {
				best = cur;
			}
		}
	}
	return best;
}

alias PathOutsideExists = Flag!"PathOutsideExists";

struct ShortestPathOutside {
	PathOutsideExists pathExists;
	Array!int path;
}

ShortestPathOutside shortestPathOutside(int Size)(ref Graph!Size graph, 
		ref Array!int border, const int center, 
		const Bitset!(TypeFromSize!(Size)) perm
) {
	ShortestPathOutside ret;
	if(perm.test(center)) {
		auto fr = floyd(graph);
		fr.execute(graph, perm);

		foreach(on; border[]) {
			if(perm.test(on)) {
				Array!int tmp;
				if(fr.path(center, on, tmp)) {
					if(ret.pathExists == PathOutsideExists.yes) {
						if(tmp.length < ret.path.length) {
							ret.path = tmp;
						}
					} else {
						ret.path = tmp;
						ret.pathExists = PathOutsideExists.yes;
					}
				}
			}
		}
	}
	return ret;
}

bool surroundsMiddle(int Size)(ref Graph!Size graph, ref Array!int border,
		const int center, const Bitset!(TypeFromSize!(Size)) perm
) {
	Bitset!(TypeFromSize!Size) permC;
	permC.flip();
	for(size_t i = 0; i < perm.size(); ++i) {
		if(perm.test(i)) {
			permC.reset(i);
		}
	}
	permC.set(center);
	auto fr = floyd(graph);
	fr.execute(graph, permC);	

	foreach(ov; border[]) {
		if(fr.pathExists(center, ov)) {
			return false;
		}
	}

	auto fr2 = floyd(graph);
	fr2.execute(graph, perm);	
	outer: foreach(ov; border[]) {
		for(int i = 0; i < perm.size(); ++i) {
			if(perm.test(i) && !fr2.pathExists(ov, i)) {
				continue outer;
			}
		}
		return true;
	}	
	return false;
}

bool pathOutExists(int Size)(ref Graph!Size graph, 
		const Bitset!(TypeFromSize!(Size)) innerBorder, ref Array!int border, const int center)
{
	Bitset!(TypeFromSize!Size) a = innerBorder;
	//a.set();

	if(a.test(center)) {
		auto fr = floyd(graph);
		fr.execute(graph, a);	

		foreach(it; border[]) {
			if(a.test(it)) {
				if(fr.pathExists(it, center)) {
					return true;
				}
			}
		}
	}
	return false;
}

/*bool pathOutExists(int Size)(ref Graph!Size graph, 
		const Bitset!(TypeFromSize!(Size)) innerBorder, ref Array!int border, const int center)
{
	//Bitset!(TypeFromSize!Size) innerBorderFlip = innerBorder;
	Bitset!(TypeFromSize!Size) innerBorderFlip; 
	innerBorderFlip.flip();
	//logf("a %s %s", innerBorderFlip.toString(), innerBorder.toString());
	innerBorderFlip.store ^= innerBorder.store;
	//logf("b %s", innerBorderFlip.toString());
	//innerBorderFlip.flip();
	foreach(it; border[]) {
		innerBorderFlip.set(it);
	}
	//logf("c %s", innerBorderFlip.toString());
	innerBorderFlip.set(center);
	//logf("d %s", innerBorderFlip.toString());
	//logf("%s", innerBorderFlip.toString());
	auto fr = floyd(graph);
	fr.execute(graph, innerBorderFlip);	

	foreach(it; border[]) {
		if(fr.pathExists(it, center)) {
			logf("aa %s", innerBorderFlip.toString2());
			return true;
		}
	}
	logf("bb %s", innerBorderFlip.toString2());
	return false;
}*/

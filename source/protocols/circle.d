module protocols.circle;

import std.experimental.logger;
import std.stdio;
import std.typecons : Flag;
import std.math : approxEqual;
import std.container.array : Array;
import std.algorithm.searching : canFind;
import std.typecons : isIntegral, Nullable;
import std.format;
import std.conv : to;

import gfm.math.vector;
import fixedsizearray;

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

void manyCircles(string filename, string resultFolderName) {
	import std.file : mkdirRecurse;
	mkdirRecurse(resultFolderName);

	auto f = File(resultFolderName ~ "/result.tex", "w");
	auto fLtw = f.lockingTextWriter();
	prepareLatexDoc(fLtw);

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
		} catch(Exception e) {
			logf("Unable to find border for graph %d %s", i, e.toString());
			formattedWrite(fLtw, "Unable to process graph with Circle Protocol\n");
		}
	}

	formattedWrite(fLtw, "\\end{document}");
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

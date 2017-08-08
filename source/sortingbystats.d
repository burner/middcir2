module sortingbystats;

import std.container.array;
import std.algorithm.sorting : sort;
import std.stdio : File;
import std.file : exists, mkdir;
import std.format : format, formattedWrite;
import std.experimental.logger;

import exceptionhandling;
import permutation;

import statsanalysis : GraphStats, GraphWithProperties, loadGraphs,
	   readOverWriteLevel;
//import learning;
import learning2;

void printHeader(LTW)(ref LTW ltw) {
	formattedWrite(ltw, "\\documentclass{scrbook}\n");
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

void sortMappedQP(int Size)(string jsonFileName) {
	Array!(GraphWithProperties!Size) graphs = loadGraphs!Size(jsonFileName);
	ensure(graphs.length > 0);
	const size_t numNodes = graphs[0].graph.length;

	string[3] protocols = ["MCS", "Lattice", "Grid"];
	info();

	OptimalMappings!(Size)[3] rslts; 
	foreach(idx, proto; protocols) {
		ensure(graphs[0].graph.length > 0);
		rslts[idx] = loadResults(graphs, jsonFileName, proto, graphs[0].graph.length);
		infof("%s %s", idx, proto);
	}

	foreach(ref it; rslts) {
		it.validate();
	}
	info();

	string foldername = jsonFileName ~ "_sort";
	if(!exists(foldername)) {
		mkdir(foldername);
	}
	auto f = File(foldername ~ "/index.tex", "w");
	auto ltw = f.lockingTextWriter();
	printHeader(ltw);

	auto permu = Permutations(cast(int)cstatsArray.length, 
			//1, cast(int)cstatsArray.length
			1, 2
		);
	formattedWrite(ltw, "\\chapter{Permutations}\n");
	auto mm = new MMCStat!32();
	foreach(perm; permu) {
		mm.clear();
		for(int j = 0; j < cstatsArray.length; ++j) {
			if(perm.test(j)) {
				mm.insertIStat(cstatsArray[j]);
			}
		}
		if(!areMeasuresUnique(mm)) {
			logf("ignore %s", mm.getName());
			continue;
		}

		infof("working on %s", mm.getName());
		formattedWrite(ltw, "\\section{%s}\n", mm.getName());
		foreach(idx, ref rslt; rslts) {
			formattedWrite(ltw, "\\subsection{Protocol %s}\n", protocols[idx]);
			foreach(ref OptMapData!Size om; rslt.data[]) {
				formattedWrite(ltw, "\\subsubsection{Dimension %s times %s}\n",
						om.key.height, om.key.width
					);
				Array!(GraphStats!Size) tmp;
				ensure(om.values[].length > 0);
				foreach(ref GraphStats!Size gs; om.values[]) {
					tmp.insertBack(gs);
				}
				ensure(tmp.length > 0);
				sortMappedQP!Size(tmp, mm);
				toLatexSortMapped!Size(tmp, mm, protocols[idx], foldername,
						format("_%sX%s", 
							om.key.height, om.key.width
						)
					);
			}
		}
	}
	formattedWrite(ltw, "\\end{document}\n");
}

immutable enum gnuplotString =
`print GPVAL_TERMINALS
set terminal eps color
set border linewidth 1.5
set grid back lc rgb "black"
set ylabel 'Node Availability'
set yrange [-0.05:1.1]
set ylabel 'Operation Availability'
set xlabel '%1$s'
set border 3 back lc rgb "black"
set palette defined (0 0 0 0.5, 1 0 0 1, 2 0 0.5 1, 3 0 1 1, 4 0.5 1 0.5, 5 1 1 0, 6 1 0.5 0, 7 1 0 0, 8 0.5 0 0)
set grid
set output '%1$s%2$s%4$s%5$s%6$s.eps'
plot "%1$s%2$s%5$s%3$s%4$s%6$s.data" using 1:2:3 with image
`;

void toLatexSortMapped(int Size)(ref Array!(GraphStats!Size) rslt,
		const(MMCStat!Size) mm, const(string) protocol, string folder, string postfix = "")
{
	foreach(idx, w; ["readAvail", "writeAvail", "readCosts", "writeCosts"]) {
		foreach(jdx, it; ["Avail", "Costs"]) {
			foreach(rdx, row; readOverWriteLevel) {
				auto f = File(
						format("%s/%s%s%s%s%.2f%s.data", folder, mm.getName(), protocol,
							w, it, row, postfix
						), "w"
					);
				auto ltw = f.lockingTextWriter();
				for(size_t i = 0; i < rslt.length; ++i) {
					for(size_t p = 0; p < 101; ++p) {
						double value;
						switch(idx) {
							case 0:
								value = rslt[i].results[jdx][rdx].readAvail[p];
								break;
							case 1:
								value = rslt[i].results[jdx][rdx].writeAvail[p];
								break;
							case 2:
								value = rslt[i].results[jdx][rdx].readCosts[p];
								break;
							case 3:
								value = rslt[i].results[jdx][rdx].writeCosts[p];
								break;
							default:
								assert(false);
						}
						formattedWrite(ltw, "%s %.2f %.15f\n", i, p / 100.0, value);
					}
				}
				auto g = File(
						format("%s/%s%s%s%s%.2f%s.gp", folder, mm.getName(), protocol,
							w, it, row, postfix
						), "w"
					);
				auto gtw = g.lockingTextWriter();
				formattedWrite(gtw, gnuplotString, mm.getName(), protocol, it, 
						format("%.2f", row), w, postfix
					);
			}
		}
	}
}

void sortMappedQP(int Size)(ref Array!(GraphStats!Size) rslt,
		const(MMCStat!Size) mm) 
{
	sort!((a,b) => mm.less(a,b))(rslt[]);
}

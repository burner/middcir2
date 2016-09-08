module plot.mappingplot;

import plot : ResultPlot;
import plot.gnuplot;
import protocols.crossing;
import protocols.mcs;
import mapping;
import graph;
import std.stdio : File;
import std.experimental.logger;
import std.format : formattedWrite;

void writeMapping(M)(string prefix, ref File tex, const ref M mapping) {
	tex.write("\\begin{tabular}{l ");
	for(size_t i = 0; i < mapping.bestMapping.mapping.length; ++i) {
		tex.write("c ");
	}
	tex.write("}\nOriginal ");
	for(size_t i = 0; i < mapping.bestMapping.mapping.length; ++i) {
		tex.writef("& %s ", i);
	}
	tex.write("\\\\\nMapped ");
	for(size_t i = 0; i < mapping.bestMapping.mapping.length; ++i) {
		tex.writef("& %s ", mapping.bestMapping.mapping[i]);
	}
	tex.write("\n\\end{tabular}\n");
}

void mappingPlot(M)(string path, const ref M mapping, ResultPlot[] results...) 
{
	import std.file : mkdirRecurse, chdir, getcwd;
	import std.stdio : File;
	import std.process : execute;
	import std.exception : enforce;
	string oldcwd = getcwd();
	scope(exit) {
		chdir(oldcwd);
	}

	mkdirRecurse(path);
	chdir(path);

	gnuPlot(results);

	auto tex = File("mapping.tex", "w");
	tex.write(topString);
	writeMapping("", tex, mapping);
	tex.write(bottomString);

	{
		auto lnt = File("lnt.tex", "w");
		(*mapping.lnt).toTikz(lnt.lockingTextWriter());

		auto pnt = File("pnt.tex", "w");
		(*mapping.pnt).toTikz(pnt.lockingTextWriter());
	}
}

string topString =
`
\documentclass[a4]{article}
\usepackage[english]{babel}
\usepackage{graphicx}
\usepackage{standalone}
\usepackage{subcaption}
\usepackage[cm]{fullpage}
\usepackage{tikz}
\usepackage{pgfplots}
\usetikzlibrary{decorations.markings, arrows, decorations.pathmorphing,
   backgrounds, positioning, fit, shapes.geometric}
\IfFileExists{../config.tex}%
	{\input{../config}}%
	{
	\tikzstyle{place} = [shape=circle,
    draw, align=center,minimum width=0.70cm,
    top color=white, bottom color=blue!20]
	}

\begin{document}
\section{Graphs}
\begin{figure}[h]
	\centering
	\begin{subfigure}[b]{0.45\textwidth}
		\centering
		\includestandalone{lnt}
		\caption{LNT}
	\end{subfigure}
	\begin{subfigure}[b]{0.45\textwidth}
		\centering
		\includestandalone{pnt}
		\caption{PNT}
	\end{subfigure}
\end{figure}

\section{Mapping}
`;

string bottomString = 
`\section{Availability}
\begin{figure}[h]
	\includegraphics[width=\linewidth]{1resultavail.pdf}
\end{figure}

\section{Costs}
\begin{figure}[h]
	\includegraphics[width=\linewidth]{1resultcost.pdf}
\end{figure}
\end{document}
`;

void writeTBLRSetsImpl(string setName,A,Out)(A a, ref Out ltw) {
	formattedWrite(ltw, "\\paragraph{%s Set}\n", setName);
	formattedWrite(ltw, "%(%s, %)\n", a);
}

void writeTBLRSets(C,Out)(ref C crossing, ref Out ltw) {
	writeTBLRSetsImpl!"Top"(crossing.top[], ltw);
	writeTBLRSetsImpl!"Bottom"(crossing.bottom[], ltw);
	writeTBLRSetsImpl!"Left"(crossing.left[], ltw);
	writeTBLRSetsImpl!"Right"(crossing.right[], ltw);
}

void mappingPlot2(Graph,P...)(string path, auto ref Graph pnt, auto ref P ps) {
	import std.file : mkdirRecurse, chdir, getcwd;
	import std.stdio : File;
	import std.process : execute;
	import std.exception : enforce;
	import std.array : back;
	string oldcwd = getcwd();
	scope(exit) {
		chdir(oldcwd);
	}

	mkdirRecurse(path);
	chdir(path);

	Mappings!(32,32)[] mappings;
	ResultPlot[ps.length] results;
	ResultPlot[ps.length] resultsMapping;

	auto tex = File("mapping.tex", "w");
	tex.write(topString2);
	auto ltw = tex.lockingTextWriter();

	auto mappingGraph = File("mappinggraph.tex", "w");
	pnt.toTikz(mappingGraph.lockingTextWriter());

	foreach(idx, ref p; ps) {
		results[idx] = ResultPlot(p.name(), p.calcAC);
		formattedWrite(ltw, "\n\n\\section{%s}\n", p.name());
		auto tf = File(p.name() ~ "graph.tex", "w");
		p.getGraph.toTikz(tf.lockingTextWriter());
		formattedWrite(ltw, graphInclude, p.name(), p.name());
		gnuPlot(".", p.name(), results[idx]);
		static if(is(typeof(p) == Crossing)) {
			writeTBLRSets(p, ltw);
		}

		formattedWrite(ltw, 
				"\\subsection{%s Availability and Costs on LNT}\n", 
				p.name());
		formattedWrite(ltw, figureInclude, p.name(), p.name(), p.name(), 
				p.name(), p.name(), p.name());
		formattedWrite(ltw, "\\clearpage\n");

		mappings ~= Mappings!(32,32)(p.getGraph(), pnt, 1.0, ROW(0.5));
		static if(is(typeof(p) == Crossing)) {
			// HACK to not make it segfault we create a dummy best mapping for
			// the crossing protocol, as it does not require a mapping
			mappings.back.createDummyBestMapping();

			// for the crossing protocol the original results is equal to the
			// mapped results as there is no mapping required.
			resultsMapping[idx] = results[idx];
		} else {
			// As MCS is using a totally connected LNT we only have to look at
			// one mapping
			const bool isMCS = is(typeof(p) == MCS);

			resultsMapping[idx] = ResultPlot(
					mappings.back.name(p.name()),
					mappings.back.calcAC(p.read, p.write, isMCS)
			);
		}

		string mapFigName = p.name() ~ "mapped";
		gnuPlot(".", mapFigName, results[idx], resultsMapping[idx]);

		formattedWrite(ltw, "\n\\subsection{Best mapping for %s}\n", p.name());
		writeMapping(p.name(), tex, mappings.back);

		formattedWrite(ltw, figureInclude, mapFigName, mapFigName, mapFigName,
				mapFigName, mapFigName, mapFigName);

	}
	string mapFigNameAll = "allmapped";
	gnuPlot(".", mapFigNameAll, results[]);
	formattedWrite(ltw, "\n\\clearpage\n");
	formattedWrite(ltw, "\n\\section{Protocols on LNT}\n");
	formattedWrite(ltw, figureInclude, mapFigNameAll, mapFigNameAll,
			mapFigNameAll, mapFigNameAll, mapFigNameAll, mapFigNameAll);

	string mapFigNameAllM = "allmappedmap";
	gnuPlot(".", mapFigNameAllM, resultsMapping[]);
	formattedWrite(ltw, "\n\\clearpage\n");
	formattedWrite(ltw, "\n\\section{Protocols on PNT}\n");
	formattedWrite(ltw, figureInclude, mapFigNameAllM, mapFigNameAllM,
			mapFigNameAllM, mapFigNameAllM, mapFigNameAllM, mapFigNameAllM);
	formattedWrite(ltw, "\\end{document}\n");
}

string topString2 =
`
\documentclass[a4]{article}
\usepackage[english]{babel}
\usepackage{graphicx}
\usepackage{standalone}
\usepackage{float}
\usepackage{subcaption}
\usepackage[cm]{fullpage}
\usepackage{tikz}
\usepackage{pgfplots}
\usetikzlibrary{decorations.markings, arrows, decorations.pathmorphing,
   backgrounds, positioning, fit, shapes.geometric}
\IfFileExists{../config.tex}%
	{\input{../config}}%
	{
	\tikzstyle{place} = [shape=circle,
    draw, align=center,minimum width=0.70cm,
    top color=white, bottom color=blue!20]
	}

\begin{document}
\section{Physical Network Topology}
\begin{figure}[H]
	\centering
	\includestandalone{mappinggraph}
	\caption{PNT used.}
\end{figure}

`;

string graphInclude = 
`\begin{figure}[H]
	\centering
	\includestandalone{%sgraph}
	\caption{LNT used by %s}
\end{figure}
`;

string figureInclude = 
`\begin{figure}[H]
	\includegraphics[width=0.9\linewidth]{%s1resultavail.pdf}
	\caption{Availability of %s"}
	\includegraphics[width=0.9\linewidth]{%s80resultavail.pdf}
	\caption{Availability of %s p \(\ge\) 0.8"}
\end{figure}
\begin{figure}[H]
	\includegraphics[width=0.9\linewidth]{%s1resultcost.pdf}
	\caption{Costs of %s"}
\end{figure}
`;

module plot.resultplot;

import std.stdio;
import std.experimental.logger;

import plot;
import plot.gnuplot;
import plot.mappingplot;
import graph;
import protocols;
import protocols.crossing;

string topString =
`
\documentclass[a4]{article}
\usepackage[english]{babel}
\usepackage{graphicx}
\usepackage{standalone}
\usepackage{float}
\usepackage{subcaption}
\usepackage[section]{placeins}
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
\tableofcontents
\section{Physical Network Topology}
\begin{figure}[H]
	\centering
	\includestandalone{pnt}
	\caption{PNT used.}
\end{figure}

`;

string genFolderPrefix(RP)(ref RP resultProtocol) {
	static if(is(typeof(RP.protocol) == Crossings)) {
		return "Crossings";
	} else {
		import std.array : appender;
		import std.format : formattedWrite;
		auto app = appender!string();

		formattedWrite(app, "%s", resultProtocol.protocol.name());
		formattedWrite(app, "row%3.2f", resultProtocol.mappingParameter.row);
		formattedWrite(app, "qtf%3.2f", resultProtocol.mappingParameter.quorumTestFraction);
		return app.data;
	}
}

ResultPlot printLNTResults(LTW, RP)(LTW ltw, ref RP resultProtocol) {
	ResultPlot ret = ResultPlot(
			resultProtocol.protocol.name(), 
			resultProtocol.lntResult
		);

	//string prefix = genFolderPrefix(resultProtocol);
	//writeln(prefix);
	gnuPlot(resultProtocol.protocol.name(), "", ret);
	return ret;
}

ResultPlot printPNTResults(LTW, RP)(LTW ltw, ref RP resultProtocol) {
	string prefix = genFolderPrefix(resultProtocol);
	ResultPlot ret = ResultPlot(
			prefix, 
			resultProtocol.pntResult
		);

	//string prefix = genFolderPrefix(resultProtocol)~"-mapped";
	writeln(prefix);
	gnuPlot(prefix, "", ret);
	return ret;
}

import std.range : ElementType;

version(LDC) {
ref auto Delay(alias arg, size_t idx)() { return *arg[idx].opDot(); }
} else {
ref auto Delay(alias arg, size_t idx)() { return *arg[idx]; }
}

template expand(alias args, size_t idx = 0) {
	import std.meta : AliasSeq;
    alias Args = typeof(args);

    static if (is(Args : C[N], C, size_t N)) {
        static if (idx < (N - 1)) {
            alias expand = AliasSeq!(Delay!(args, idx),
                                      expand!(args, idx + 1));
		} else {
            alias expand = Delay!(args, N - 1);
		}
    }
}

/** We assume that all RPs have the same pnt.
*/
void resultNTPlot(RPs...)(string path, ref RPs resultProtocols) {
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

	// PNT Graph Tex File
	auto pntFile = File("pnt.tex", "w");
	resultProtocols[0].pnt.toTikz(pntFile.lockingTextWriter());

	// Main Tex File
	auto mainFile = File("main.tex", "w");
	mainFile.write(topString);

	ResultPlot[RPs.length] lntResultPlots;
	ResultPlot[RPs.length] pntResultPlots;

	foreach(idx, resultProtocol; resultProtocols) {
		string unmappedName = resultProtocol.protocol.name();
		string mappedName = genFolderPrefix(resultProtocol);
		string nuName = unmappedName ~ mappedName;

		lntResultPlots[idx] = printLNTResults(
				mainFile.lockingTextWriter(), resultProtocol
			);

		pntResultPlots[idx] = printPNTResults(
				mainFile.lockingTextWriter(), resultProtocol
			);

		gnuPlot(nuName, "", lntResultPlots[idx], pntResultPlots[idx]);

		mainFile.writefln("\\section{%s}\n", mappedName);
		auto lntFile = File(unmappedName ~ "/lnt.tex", "w");
		resultProtocol.protocol.graph.toTikz(lntFile.lockingTextWriter());
		mainFile.writefln(
`\begin{figure}[H]
	\centering
	\includestandalone{%1$s/lnt}
	\caption{LNT of %1$s}
\end{figure}
`, unmappedName);

		static if(!is(typeof(resultProtocol.protocol) == Crossings)) {
			writeMapping("", mainFile, resultProtocol.mappings);
		}
		mainFile.writefln("\\subsection{Executed on its LNT}\n");
		mainFile.writefln(
`\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{%1$s/1resultavail.pdf}
	\caption{The Read and Write Availability of %1$s.}
\end{figure}

\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{%1$s/80resultavail.pdf}
	\caption{The Read and Write Availability of %1$s.}
\end{figure}

\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{%1$s/1resultcost.pdf}
	\caption{The Read and Write Costs of %1$s.}
\end{figure}
`, unmappedName);

		mainFile.writefln("\\subsection{Mapped on the PNT}\n");
		mainFile.writefln(
`\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{%1$s/1resultavail.pdf}
	\caption{The Read and Write Availability of %1$s mapped.}
\end{figure}

\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{%1$s/80resultavail.pdf}
	\caption{The Read and Write Availability of %1$s mapped.}
\end{figure}

\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{%1$s/1resultcost.pdf}
	\caption{The Read and Write Costs of %1$s mapped.}
\end{figure}
`, mappedName);

		mainFile.writefln(
`\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{%1$s/1resultavail.pdf}
	\caption{The Read and Write Availability of %1$s mapped.}
\end{figure}

\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{%1$s/80resultavail.pdf}
	\caption{The Read and Write Availability of %1$s mapped.}
\end{figure}

\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{%1$s/1resultcost.pdf}
	\caption{The Read and Write Costs of %1$s mapped.}
\end{figure}
`, nuName);
	}

	mainFile.writeln("\\section{LNT Comparision}\n");
	gnuPlot("LNTComparision", "", lntResultPlots);

	mainFile.writefln(
`\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{LNTComparision/1resultavail.pdf}
	\caption{The Read and Write Availability of all Quorum Protocols.}
\end{figure}

\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{LNTComparision/80resultavail.pdf}
	\caption{The Read and Write Availability of all Quorum Protocols.}
\end{figure}

\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{LNTComparision/1resultcost.pdf}
	\caption{The Read and Write Costs of all Quorum Protocols.}
\end{figure}
`);

	mainFile.writeln("\\section{PNT Comparision}\n");
	gnuPlot("PNTComparision", "", pntResultPlots);
	foreach(idx, resultProtocol; resultProtocols) {
		static if(!is(typeof(resultProtocol.protocol) == Crossings)) {
			string mappedName = genFolderPrefix(resultProtocol);
			mainFile.writefln("%s\\\\", mappedName);
			writeMapping("", mainFile, resultProtocol.mappings);
			mainFile.writefln("\\\\");
		}
	}

	mainFile.writefln(
`\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{PNTComparision/1resultavail.pdf}
	\caption{The Read and Write Availability of all mapped Quorum Protocols.}
\end{figure}

\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{PNTComparision/80resultavail.pdf}
	\caption{The Read and Write Availability of all mapped Quorum Protocols.}
\end{figure}

\begin{figure}[H]
	\centering
	\includegraphics[width=0.9\linewidth]{PNTComparision/1resultcost.pdf}
	\caption{The Read and Write Costs of all mapped Quorum Protocols.}
\end{figure}
`);

	mainFile.writeln("\\end{document}\n");
}

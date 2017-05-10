module statsanalysisoutput;

import std.stdio : File;
import std.container.array : Array;
import statsanalysis;

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

void subLevelFiles(string folder, const(LNTDimensions) dim) {
	import std.format : format, formattedWrite;
	{
		auto m = File(format(folder ~ "%dx%d/Makefile", dim.width,
						dim.height), "w");
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

void graphsToTex(int Size)(string foldername, 
		const ref Array!(GraphWithProperties!Size) pss) 
{
	import std.format : format;
	auto f = format("%sGraphs/", foldername);
	graphsToTexImpl(f, pss.mcs);
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

void topLevelFiles(int Size)(string folder,
	   	ProtocolStats!(Size) rslts, 
		Array!(GraphWithProperties!Size) graphs,
		Array!LNTDimensions dims) 
{
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
				foreach(dim; dims[]) {
					formattedWrite(lltw, "%% rubber: path ./%s/%s/%dx%d/\n", 
							proto, Selector.XLabel, dim.width, dim.height
					);
					foreach(it; readOverWriteLevel) {
						formattedWrite(lltw, "%% rubber: path ./%s/%s/%dx%d/%.2f\n",
							proto, Selector.XLabel, dim.width, dim.height, it
						);
					}
				}
			}
		}
		formattedWrite(lltw, 
`\begin{document}
\tableofcontents
`);
		formattedWrite(lltw, "\\chapter{Graphs}\n");
		for(size_t i; i < graphs.length; ++i) {
			formattedWrite(lltw,
`\paragraph{Graph %1$d}
\begin{tabular}{p{0.5\textwidth} l r}
\multirow{%d}{*}{
	\includestandalone{Graphs/%1$d}
} &
`, i);
			foreach(m; Measures!Size) {
				formattedWrite(lltw, "%s & %.6f \\\\\n",
					m.XLabel, m.select(graphs[i])
				);
			}
			formattedWrite(lltw, `
\end{tabular}`);
		}
		foreach(proto; ["MCS", "Lattice", "Grid"]) {
			formattedWrite(lltw, "\n\n\\chapter{%s}\n", proto);
			foreach(Selector; Measures!Size) {
				formattedWrite(lltw, "\n\n\\section{%s}\n", Selector.XLabel);
				foreach(dim; dims) {
					formattedWrite(lltw, "\n\n\\subsection{%dx%d}\n",
							dim.width, dim.height
					);
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
		}
		formattedWrite(lltw, "\\end{document}\n");
	}
}

void protocolToOutputImpl(int Size,Selector,LTW)(LTW ltw,
		const(Data!Size) protocol, const size_t idx,
	   	const ResultArraySelect resultSelect)
{
	import std.format : formattedWrite;
	foreach(ref it; protocol.values[]) {
		auto data = it.getData(idx, resultSelect);
		for(size_t i = 0; i < 101; ++i) {
			formattedWrite(ltw, "%.15f %.15f %.15f\n", 
				Selector.select(it), i/100.0, data[i]
			);
		}
	}
}

void protocolToOutput(int Size,Selector)(string folder, 
		const(Data!Size) protocol, const(LNTDimensions) dim)
{
	import std.file : mkdirRecurse, exists;
	import std.format : format, formattedWrite;
	mkdirRecurse(format("%s/%s/", folder, Selector.XLabel));
	string folderDim = format("%s/%s/Makefile", folder, Selector.XLabel);
	if(exists(folderDim)) {
		auto f = File(folderDim, "a");
		formattedWrite(f.lockingTextWriter(), "\t$(MAKE) -C %dx%d\n",
				dim.width, dim.height);
	} else {
		auto f = File(folderDim, "w");
		formattedWrite(f.lockingTextWriter(), "all:\n");
		formattedWrite(f.lockingTextWriter(), "\t$(MAKE) -C %dx%d\n",
				dim.width, dim.height);

	}
	foreach(idx, it; readOverWriteLevel) {
		string folderROW = format("%s/%s/%dx%d/%.2f/", folder, Selector.XLabel, 
				dim.width, dim.height, it);
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
	subLevelFiles(mfn, dim);
	subLevelFilesSelector!Size(folder ~ "/");
}


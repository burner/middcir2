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
set output '%3$s%1$s.eps'
plot "%3$s%1$sgnuplot.data" using 1:2:3 with image
`;

immutable(string[]) protocolString = ["MCS", "Grid", "Lattice"];
//immutable(string[]) protocolString = ["MCS"];

void genGnuplotScripts(string folder, string xlabel) {
	import std.format : format, formattedWrite;

	foreach(it; ["readavail", "writeavail", "readcosts", "writecosts"]) {
		foreach(ac; ["row", "rowc"]) {
			auto f = File(format("%s%s%s.gp", folder, ac, it), "w");
			formattedWrite(f.lockingTextWriter(), gnuplotString, it, xlabel, ac);
		}
	}
}

void graphsToTex(int Size)(string foldername, 
		const ref Array!(GraphWithProperties!Size) pss) 
{
	import std.format : format;
	import std.file : mkdirRecurse;
	auto f = format("%sGraphs/", foldername);
	mkdirRecurse(f);
	graphsToTexImpl(f, pss);
}

void graphsToTexImpl(int Size)(string foldername, 
		const ref Array!(GraphWithProperties!Size) gs) 
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
		foreach(proto; protocolString) {
			formattedWrite(mLtw, "\t$(MAKE) -j 2 -C %s\n", proto);
		}
	}

	{
		auto l = File(folder ~ "latex.tex", "w");
		auto lltw = l.lockingTextWriter();
		formattedWrite(lltw, "\\documentclass{scrbook}\n");
		formattedWrite(lltw, "\\usepackage{graphicx}\n");
		formattedWrite(lltw, "\\usepackage{standalone}\n");
		formattedWrite(lltw, "\\usepackage{float}\n");
		formattedWrite(lltw, "\\usepackage{multirow}\n");
		formattedWrite(lltw, "\\usepackage{hyperref}\n");
		formattedWrite(lltw, "\\usepackage{placeins}\n");
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
		foreach(proto; protocolString) {
			formattedWrite(lltw, "%% rubber: path ./%s/\n", proto);
			foreach(Selector; Measures!Size) {
				formattedWrite(lltw, "%% rubber: path ./%s/%s/\n", proto, Selector.XLabel);

				Array!LNTDimensions dimsToIter;
				if(proto == "MCS") {
					dimsToIter.insertBack(LNTDimensions(0, 0));
				} else {
					dimsToIter = dims;
				}

				foreach(dim; dimsToIter[]) {
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
		formattedWrite(lltw, "\\part{Graphs}\n");
	//\resizebox{0.5\textwidth}{5cm}{\includestandalone{Graphs/%1$d}}
		for(size_t i; i < graphs.length; ++i) {
			formattedWrite(lltw,
`
\FloatBarrier
\subsection{Graph %1$d}
\begin{tabular}{p{0.5\textwidth} l r}
\multirow{%2$d}{*}{
	\resizebox{0.5\textwidth}{5cm}{\input{Graphs/%1$d}}
}
`, i, Measures!(Size).length);
			foreach(m; Measures!Size) {
				formattedWrite(lltw, "& %s & %.6f \\\\\n",
					m.XLabel, m.select(graphs[i])
				);
			}
			formattedWrite(lltw, `
\end{tabular}`);
		}
		foreach(proto; protocolString) {
			formattedWrite(lltw, "\n\n\\part{%s}\n", proto);
			foreach(Selector; Measures!Size) {
				formattedWrite(lltw, "\n\n\\chapter{%s}\n", Selector.XLabel);

				Array!LNTDimensions dimsToIter;
				if(proto == "MCS") {
					dimsToIter.insertBack(LNTDimensions(0, 0));
				} else {
					dimsToIter = dims;
				}

				foreach(dim; dimsToIter[]) {
					formattedWrite(lltw, "\n\n\\section{%dx%d}\n",
							dim.width, dim.height
					);
					foreach(it; readOverWriteLevel) {
						string inputfolder = format("%s/%s/%dx%d/%0.2f", /*folder,*/
								proto, Selector.XLabel, dim.width, dim.height, it
						);
						foreach(ac; ["row", "rowc"]) {
							formattedWrite(lltw, 
`

\FloatBarrier
\subsection{Write over Read %.02f %s}
`, 							it, ac == "row" ? "Availability" : "Costs"); 
							formattedWrite(lltw, 
`\begin{figure}[H]
	\begin{subfigure}[b]{0.5\textwidth}
		\centering
		\includegraphics[width=1.05\textwidth]{%1$s/%2$sreadavail.pdf}
		\caption{Read Availability}
	\end{subfigure}
	\begin{subfigure}[b]{0.5\textwidth}
		\centering
		\includegraphics[width=1.05\textwidth]{%1$s/%2$swriteavail.pdf}
		\caption{Write Availability}
	\end{subfigure}
	\caption{Availability}
\end{figure}
\begin{figure}[H]
	\begin{subfigure}[b]{0.5\textwidth}
		\centering
		\includegraphics[width=1.05\textwidth]{%1$s/%2$sreadcosts.pdf}
		\caption{Read Costs}
	\end{subfigure}
	\begin{subfigure}[b]{0.5\textwidth}
		\centering
		\includegraphics[width=1.05\textwidth]{%1$s/%2$swritecosts.pdf}
		\caption{Write Costs}
	\end{subfigure}
	\caption{Costs}
\end{figure}
`, inputfolder, ac);
						}
					}
				}
			}
		}
		formattedWrite(lltw, "\\end{document}\n");
	}
}

void superMakefile(int Size)(string folder, Array!(LNTDimensions) dims) {
	import std.format : format, formattedWrite;
	auto f = File(format("%s/SuperMakefile", folder), "w");
	auto ltw = f.lockingTextWriter();

	formattedWrite(ltw, "all:");
	foreach(proto; protocolString) {
		Array!LNTDimensions dimsToIter;
		if(proto == "MCS") {
			dimsToIter.insertBack(LNTDimensions(0, 0));
		} else {
			dimsToIter = dims;
		}
		foreach(m; Measures!Size) {
			foreach(d; dimsToIter[]) {
				foreach(row; readOverWriteLevel) {
					foreach(ac; ["row", "rowc"]) {
						foreach(p; ["readavail", "writeavail", "readcosts",
								"writecosts"])
						{
							formattedWrite(ltw, " %s%s%d%d%02d%s%s",
								proto, m.XLabel, d.width, d.height,
								cast(int)(row * 100), ac, p
							);
						}
					}
				}
			}
		}
	}
	formattedWrite(ltw, "\n\n");

	foreach(proto; protocolString) {
		Array!LNTDimensions dimsToIter;
		if(proto == "MCS") {
			dimsToIter.insertBack(LNTDimensions(0, 0));
		} else {
			dimsToIter = dims;
		}
		foreach(m; Measures!Size) {
			foreach(d; dimsToIter[]) {
				foreach(row; readOverWriteLevel) {
					foreach(ac; ["row", "rowc"]) {
						foreach(p; ["readavail", "writeavail", "readcosts",
								"writecosts"])
						{
							formattedWrite(ltw, "%s%s%d%d%02d%s%s:\n",
								proto, m.XLabel, d.width, d.height,
								cast(int)(row * 100), ac, p
							);
							formattedWrite(ltw, 
								"\tcd %s/%s/%dx%d/%.2f && gnuplot %s%s.gp\n",
								proto, m.XLabel, d.width, d.height,
								row, ac, p
							);
							formattedWrite(ltw, 
								"\tcd %s/%s/%dx%d/%.2f && epstopdf %s%s.eps\n",
								proto, m.XLabel, d.width, d.height,
								row, ac, p
							);
							formattedWrite(ltw, "\n");
						}
						formattedWrite(ltw, "\n");
					}
				}
			}
		}
	}
}

void protocolToOutputImpl(int Size,Selector,LTW)(LTW ltw,
		const(Data!Size) protocol, const size_t idx,
	   	const ResultArraySelect resultSelect, const size_t ac)
{
	import std.format : formattedWrite;
	foreach(ref it; protocol.values[]) {
		auto data = it.getData(idx, resultSelect, ac);
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
	foreach(idx, it; readOverWriteLevel) {
		string folderROW = format("%s/%s/%dx%d/%.2f/", folder, Selector.XLabel, 
				dim.width, dim.height, it);
		mkdirRecurse(folderROW);

		genGnuplotScripts(folderROW, Selector.XLabel);
		genGnuplotMakefile(folderROW);

		foreach(jdx, ac; ["row", "rowc"]) {
			foreach(type; [ResultArraySelect.ReadAvail,ResultArraySelect.WriteAvail,
					ResultArraySelect.ReadCosts,ResultArraySelect.WriteCosts])
			{
				File f;
				final switch(type) {
					case ResultArraySelect.ReadAvail:
 						f = File(folderROW ~ ac ~ "readavailgnuplot.data", "w");	
						break;
					case ResultArraySelect.WriteAvail:
 						f = File(folderROW ~ ac ~ "writeavailgnuplot.data", "w");	
						break;
					case ResultArraySelect.ReadCosts:
 						f = File(folderROW ~ ac ~ "readcostsgnuplot.data", "w");	
						break;
					case ResultArraySelect.WriteCosts:
 						f = File(folderROW ~ ac ~ "writecostsgnuplot.data", "w");	
						break;
				}
				auto ltw = f.lockingTextWriter();
				protocolToOutputImpl!(Size,Selector)(ltw, protocol, idx, type, jdx);
			}
		}
	}

	string mfn = format("%s/%s/", folder, Selector.XLabel);
}

module plot.mappingplot;

import plot : ResultPlot;
import plot.gnuplot;
import mapping;

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

	{
		auto tex = File("mapping.tex", "w");
		tex.write(topString);
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

		tex.write(bottomString);
	}

	{
		auto lnt = File("lnt.tex", "w");
		(*mapping.lnt).toTikz(lnt.lockingTextWriter());

		auto pnt = File("pnt.tex", "w");
		(*mapping.pnt).toTikz(pnt.lockingTextWriter());
	}

	//auto latex = execute(["pdflatex", "mapping.tex"]);
	//enforce(latex.status == 0);
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
	\includegraphics[width=\linewidth]{resultavail.pdf}
\end{figure}

\section{Costs}
\begin{figure}[h]
	\includegraphics[width=\linewidth]{resultcost.pdf}
\end{figure}
\end{document}
`;

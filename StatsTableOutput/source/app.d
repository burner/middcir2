import std.stdio;
import std.conv : to;
import std.file : readText;
import std.algorithm.iteration : splitter;
import std.algorithm.searching : find, startsWith;
import std.typecons : Flag;
import std.range : dropOne, drop;
import std.array : split, replace;
import std.format : format;

string[] rows = ["0.01", "0.10", "0.25", "0.50", "0.75", "0.90", "0.99"];
string[] resultTypes = [
		"Read Avail", "Write Avail", "Read Costs", "Write Costs"
	];
string[] aggregater = ["Min", "Avg", "Median", "Mode", "Max"];

struct Result {
	string ftrSet;
	double value;
}

struct RoWLine {
	Result[string] results;
}

alias ReadOrWriteARW = Flag!"RoWARW";

RoWLine[string] splitOutRoWLines(L)(L lines, ReadOrWriteARW rowarw) {
	RoWLine[string] rslt;

	auto linesN = rowarw == ReadOrWriteARW.yes ?
		lines.find!(a => startsWith(a, "\\subsubsection{Avail Measures}"))
		: lines.find!(a => startsWith(a, "\\subsubsection{Costs Measures}"));
	assert(!linesN.empty);
	linesN.popFront();
	assert(!linesN.empty);

	foreach(row; rows) {
		RoWLine rowResults;
		auto linesRoW = linesN.save
			.find!(a => 
					startsWith(a, format("\\paragraph{Read over Write %s}", row))
			)
			.drop(2);
		assert(!linesRoW.empty);

		foreach(idx, resultType; resultTypes) {
			string[] line = linesRoW.front.split[];
			string t = line[0] ~ " " ~ line[1];
			assert(t == resultType, t ~ "!=" ~ resultType);
			Result rar;
			rar.ftrSet = line[5];
			rar.value = to!double(line[3]);
			rowResults.results[resultType] = rar;
			linesRoW.popFront();
		}
		rslt[row] = rowResults;
	}

	return rslt;
}

struct Pair {
	string proto;
	string dim;
	size_t numNodes;
}

void main() {
	Counter[string] counter;
	auto pairs = [
			Pair("Grid", "4:2", 8),
			Pair("Grid", "2:4", 8),
			Pair("MCS", "0:0", 8),
			Pair("Lattice", "2:4", 8),
			Pair("Lattice", "4:2", 8),
		];
	//string protocol = "Grid";
	size_t knn = 7;
	//string dimension = "4:2";
	foreach(pair; pairs) {
		RoWLine[string][string][ReadOrWriteARW] rslts;
		foreach(aggre; aggregater) {
			string fn = format("../graphs8nodes3.json_%s_%s_%u_ai2.tex",
					pair.proto, aggre, knn
				);
			auto lines = readText(fn)
				.splitter("\n")
				.find!(a => startsWith(a, "\\chapter{Result}"))
				.find!(a => 
						startsWith(a, format(
							"\\subsection{Dimension %s}",
							pair.dim)
						)
					);
			foreach(rowc; [ReadOrWriteARW.no, ReadOrWriteARW.yes]) {
				RoWLine[string] rslt = splitOutRoWLines(lines, rowc);
				rslts[rowc][aggre] = rslt;
			}
		}
		foreach(rsltType; resultTypes) {
			printResultTable(rslts, pair.proto, knn, pair.dim, rsltType,
					pair.numNodes, counter
				);
		}
	}
	writeln(counter);
}

struct Counter {
	size_t cnt;
	size_t id;

	static size_t globalId = 1;

	static Counter opCall() {
		Counter ret;
		ret.cnt = 0;
		ret.id = Counter.globalId++;
		return ret;
	}
}

void printResultTable(const RoWLine[string][string][ReadOrWriteARW] rslts,
		string protocol, size_t knn, string dimension, string operation,
		size_t numNodes, ref Counter[string] counter) 
{
	foreach(rowc; [ReadOrWriteARW.no, ReadOrWriteARW.yes]) {
		string fn = format(
				"%s_%s_%u_%s_%s.tex", protocol, dimension, knn,
				rowc, operation.replace(" ", "_")
			);
		writeln(fn);
		auto f = File(fn, "w");
		f.writeln(`\documentclass{standalone}
\input{../config.tex}

\begin{document}
\begin{table}
\resizebox{\columnwidth}{!}{
\begin{tabular}{ r l | r l | r l | r l | r l}
\multicolumn{2}{c|}{Min} & %
	\multicolumn{2}{c|}{Average} & %
	\multicolumn{2}{c|}{Median} & %
	\multicolumn{2}{c|}{Mode} & %
	\multicolumn{2}{c}{Max} \\ \hline
MSE & ID & MSE & ID & MSE & ID & MSE & ID & MSE & ID \\ \hline`);
		foreach(row; rows) {
			f.writefln(`\multicolumn{10}{c}{Write over Read %s} \\ \hline`, row);
			foreach(idx, aggre; aggregater) {
				if(idx != 0) {
					f.write("& ");
				}
				string ftrSet = rslts[rowc][aggre][row].results[operation].ftrSet;
				if(ftrSet !in counter) {
					counter[ftrSet] = Counter();
				}
				size_t id = counter[ftrSet].id;
				counter[ftrSet].cnt++;

				writeln(rslts[rowc][aggre][row].results[operation].value, id);
				f.writefln("%0.2f & (%s) %% ",
						rslts[rowc][aggre][row].results[operation].value, 
						//ftrSet
						id
					);
			}
			f.writeln("\\\\ \\hline");
		}
		f.writeln(`\end{tabular}}`);
		f.writefln(
`\caption{The \g{mse} of the %s of the %s predictions of the \g{knn} approach
%s where $k = %u$.}`, 
		opToCaption(operation), nameToCaptionName(protocol), 
		dimNameToLNTDesc(dimension, protocol, numNodes), knn);
		f.writeln(`\end{table}
\end{document}
`);
	}
}

string opToCaption(string op) {
	switch(op) {
		case "Read Avail": return "\\arp{}";
		case "Write Avail": return "\\awp{}";
		case "Read Costs": return "\\crp{}";
		case "Write Costs": return "\\cwp{}";
		default: 
			assert(false);
	}	
}

string nameToCaptionName(string name) {
	switch(name) {
		case "Grid": return "\\g{gp}";
		case "Lattice": return "\\g{tl}";
		case "MCS": return "\\g{mcs}";
		default: 
			assert(false);
	}	
}

string dimNameToLNTDesc(string dim, string name, size_t numNodes) {
	switch(name) {
		case "MCS": return format("with $%s$ replicas", numNodes);
		case "Lattice": goto case "Grid";
		case "Grid": return format("on a $%s \\times %s$ \\g{gs}",
								dim.split(":")[0], dim.split(":")[1]);
		default: 
			assert(false);
	}
}

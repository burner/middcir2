import std.stdio;
import std.conv : to;
import std.file : readText;
import std.algorithm.iteration : splitter;
import std.algorithm.searching : find, startsWith;
import std.algorithm.sorting : sort;
import std.typecons : Flag;
import std.range : dropOne, drop;
import std.array : split, replace, empty;
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
	size_t knn;
}

void main() {
	foreach(nn; [2,3,5,7]) {
		auto pairs = [[
				Pair("Grid", "4:2", nn),
				Pair("Grid", "2:4", nn),
				Pair("MCS", "0:0", nn),
				Pair("Lattice", "2:4", nn),
				Pair("Lattice", "4:2", nn),
			], 
			[
				Pair("Grid", "3:3", nn),
				Pair("MCS", "0:0", nn),
				Pair("Lattice", "3:3", nn),
			]
		];
		Counter.resetGlobalId();
		Counter[string] counter;
		foreach(idx, numNodes; [8, 9]) {
			foreach(pair; pairs[idx]) {
				RoWLine[string][string][ReadOrWriteARW] rslts;
				foreach(aggre; aggregater) {
					string fn = format("../graphs%dnodes3.json_%s_%s_%u_ai2.tex",
							numNodes, pair.proto, aggre, pair.knn
						);
					//writeln(fn);
					auto lines = readText(fn)
						.splitter("\n")
						.find!(a => startsWith(a, "\\chapter{Result}"))
						.find!(a => 
								startsWith(a, format(
									"\\subsection{Dimension %s}",
									pair.dim)
								)
							);
					foreach(rowc; [ReadOrWriteARW.yes]) {
						RoWLine[string] rslt = splitOutRoWLines(lines, rowc);
						rslts[rowc][aggre] = rslt;
					}
				}
				foreach(rsltType; resultTypes) {
					printResultTable(rslts, pair.proto, pair.knn, pair.dim, rsltType,
							numNodes, counter
						);
				}
			}
			//writeln(counter);
			printCounterTable(counter, nn, numNodes);
		}
	}
}

struct Counter {
	size_t cnt;
	size_t id;
	string ftrSet;

	static size_t globalId = 1;

	static void resetGlobalId() {
		Counter.globalId = 1;
	}

	static Counter opCall() {
		Counter ret;
		ret.cnt = 0;
		ret.id = Counter.globalId++;
		return ret;
	}
}

string ftrSetToString(string ftrSet) {
	string ret;
	while(!ftrSet.empty) {
		if(ftrSet.startsWith("Dgr")) {
			ret ~= "Degree";
			ftrSet = ftrSet[3 .. $];
		} else if(ftrSet.startsWith("Btwnns")) {
			ret ~= "Betweennees";
			ftrSet = ftrSet[6 .. $];
		} else if(ftrSet.startsWith("Dmtr")) {
			ret ~= "Diameter";
			ftrSet = ftrSet[4 .. $];
		} else if(ftrSet.startsWith("Cnnctvty")) {
			ret ~= "Connectivity, ";
			ftrSet = ftrSet[8 .. $];
		} else if(ftrSet.startsWith("Avrg")) {
			ret ~= "Average, ";
			ftrSet = ftrSet[4 .. $];
		} else if(ftrSet.startsWith("Mdn")) {
			ret ~= "Median, ";
			ftrSet = ftrSet[3 .. $];
		} else if(ftrSet.startsWith("Md")) {
			ret ~= "Mode, ";
			ftrSet = ftrSet[2 .. $];
		} else if(ftrSet.startsWith("Mx")) {
			ret ~= "Max, ";
			ftrSet = ftrSet[2 .. $];
		} else if(ftrSet.startsWith("Mn")) {
			ret ~= "Mix, ";
			ftrSet = ftrSet[2 .. $];
		}
	}
	return ret;
}

void printCounterTable(ref Counter[string] counters, size_t knn, 
		size_t numNodes)
{
		Counter[] sortedCnt;
		foreach(key, value; counters) {
			sortedCnt ~= value;
		}
		sort!((a,b) => a.id < b.id)(sortedCnt);
		writeln(sortedCnt);
		string fn = format("counter_%s_%s.tex", knn, numNodes);
		writeln(fn);
		auto f = File(fn, "w");
		f.writeln(`\begin{table}
\resizebox{\columnwidth}{!}{
\begin{longtable}{r l r}
Id & Estimators & Occurrences \\ \hline`);
		foreach(cnt; sortedCnt) {
			f.writefln("%s & $\\{$ %s $\\}$ & %s \\\\", cnt.id, 
					ftrSetToString(cnt.ftrSet), cnt.cnt
				);
		}
		f.writeln(`\end{longtable}}`);
		f.writefln(`\caption{"The graph properties and graph properties combinations used in the
\g{knn} where $k = %s$ predictions that lead to the best predictions in at least one
instance with $%s$ replicas.}`, knn, numNodes);
		f.writefln(`\label{labtabknnestimators%s%s}`, knn, numNodes);
		f.writeln(`\end{table}`);
}

void printResultTable(const RoWLine[string][string][ReadOrWriteARW] rslts,
		string protocol, size_t knn, string dimension, string operation,
		size_t numNodes, ref Counter[string] counter) 
{
	foreach(rowc; [ReadOrWriteARW.yes]) {
		string fn = format(
				"%s_%s_%s_%u_%s_%s.tex", protocol, dimension.replace(":", "x"), 
				numNodes, knn, rowc, operation.replace(" ", "_")
			);
		writeln(fn);
		auto f = File(fn, "w");
		f.writeln(`\begin{table}
\resizebox{\columnwidth}{!}{
\begin{tabular}{c | r l | r l | r l | r l | r l} \hline
\g{agf} & %
\multicolumn{2}{c|}{Min} & %
	\multicolumn{2}{c|}{Average} & %
	\multicolumn{2}{c|}{Median} & %
	\multicolumn{2}{c|}{Mode} & %
	\multicolumn{2}{c}{Max} \\ \hline
$wor$ & MSE & ID & MSE & ID & MSE & ID & MSE & ID & MSE & ID \\ \hline`);
		foreach(row; rows) {
			f.writef(`%s &`, row);
			foreach(idx, aggre; aggregater) {
				if(idx != 0) {
					f.write("& ");
				}
				string ftrSet = rslts[rowc][aggre][row].results[operation].ftrSet;
				if(ftrSet !in counter) {
					counter[ftrSet] = Counter();
					counter[ftrSet].ftrSet = ftrSet;
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
`\caption{The \g{mse} of the %s predictions by the \g{knn} approach for the %s
%s where $k = %u$.}`, 
		opToCaption(operation), nameToCaptionName(protocol), 
		dimNameToLNTDesc(dimension, protocol, numNodes), knn);
		f.writefln("\\label{labtabknn%s}", genLabelName(protocol, operation,
					dimension, numNodes));
		f.writeln(`\end{table}`);
	}
}

string genLabelName(string protocol, string operation, string dimension,
		size_t numNodes)
{
	string ret;
	switch(protocol) {
		case "Grid": ret ~= "gp"; break;
		case "Lattice": ret ~= "tlp"; break;
		case "MCS": ret ~= "mcs"; break;
		default: 
			assert(false);
	}

	ret ~= dimension.replace(":", "x");

	switch(operation) {
		case "Read Avail": ret ~= "readavail"; break;
		case "Write Avail": ret ~= "writeavail"; break;
		case "Read Costs": ret ~= "readcosts"; break;
		case "Write Costs": ret ~= "writecosts"; break;
		default: 
			assert(false);
	}

	ret ~= to!string(numNodes);

	return ret;
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

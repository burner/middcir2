import std.stdio;
import std.conv : to;
import std.file : readText;
import std.algorithm.iteration : splitter;
import std.algorithm.searching : find, startsWith;
import std.typecons : Flag;
import std.range : dropOne, drop;
import std.array : split;
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

void main() {
	string protocol = "Grid";
	size_t knn = 7;
	RoWLine[string][string] rslts;
	foreach(aggre; aggregater) {
		string fn = format("../graphs8nodes3.json_%s_%s_%u_ai2.tex", protocol,
				aggre, knn
			);
		auto lines = readText(fn)
			.splitter("\n")
			.find!(a => startsWith(a, "\\chapter{Result}"));

		RoWLine[string] rslt = splitOutRoWLines(lines, ReadOrWriteARW.yes);
		rslts[aggre] = rslt;
		writeln(rslt);
	}
}

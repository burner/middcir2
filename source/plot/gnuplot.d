module plot.gnuplot;

import std.experimental.logger;
import std.exception : enforce;
import std.format : formattedWrite;
import std.stdio : File;

import exceptionhandling;

import plot : ResultPlot;

private immutable dataFilenameAvail = "datafileavail.rslt";
private immutable dataFilenameCost = "datafilecost.rslt";
private immutable gnuplotFilenameAvail = "gnuplotavail.gp";
private immutable gnuplotFilenameCost = "gnuplotcost.gp";
private immutable resultFilenameAvail = "resultavail.eps";
private immutable resultFilenameCost = "resultcost.eps";

void gnuPlot(ResultPlot[] results ...) {
	gnuPlot(".", "", results);
}

void gnuPlot(string path, string prefix, ResultPlot[] results ...) {
	import std.process : execute;
	import std.file : mkdirRecurse, chdir, getcwd;
	string oldcwd = getcwd();
	scope(exit) {
		chdir(oldcwd);
	}

	mkdirRecurse(path);
	chdir(path);

	createDataFiles(prefix, results);
	createGnuplotFiles(prefix, results);

	auto gnuplot = execute(["gnuplot", "-c", prefix ~ gnuplotFilenameAvail]);
	ensure(gnuplot.status == 0, prefix ~ gnuplotFilenameAvail);

	gnuplot = execute(["gnuplot", "-c", prefix ~ gnuplotFilenameCost]);
	ensure(gnuplot.status == 0, prefix ~ gnuplotFilenameCost);

	auto epstopdf = execute(["epstopdf", prefix ~ resultFilenameAvail]);
	ensure(epstopdf.status == 0, prefix ~ resultFilenameAvail);

	epstopdf = execute(["epstopdf", prefix ~ resultFilenameCost]);
	ensure(epstopdf.status == 0, prefix ~ resultFilenameCost);
}

void createDataFiles(string prefix, ResultPlot[] results ...) {
	import std.algorithm.iteration : joiner;
	import std.range;
	import std.conv : to;

	auto datafileAvail = File(prefix ~ dataFilenameAvail, "w");
	auto ltwAvail = datafileAvail.lockingTextWriter();

	auto datafileCost = File(prefix ~ dataFilenameCost, "w");
	auto ltwCost = datafileCost.lockingTextWriter();

	for(size_t i = 0; i < 101; ++i) {
		formattedWrite(ltwAvail, "%.5f ", i/100.0);
		formattedWrite(ltwCost, "%.5f ", i/100.0);
		foreach(rslt; results) {
			formattedWrite(ltwAvail, "%.15f ", rslt.result.readAvail[i]);
			formattedWrite(ltwAvail, "%.15f ", rslt.result.writeAvail[i]);

			formattedWrite(ltwCost, "%.15f ", rslt.result.readCosts[i]);
			formattedWrite(ltwCost, "%.15f ", rslt.result.writeCosts[i]);
		}
		formattedWrite(ltwAvail, "\n");
		formattedWrite(ltwCost, "\n");
	}
}

void createGnuplotFiles(string prefix, ResultPlot[] results ...) {
	createGnuplotFile(prefix, resultFilenameAvail, dataFilenameAvail,
			gnuplotFilenameAvail, "Protocol Availability", results);

	createGnuplotFile(prefix, resultFilenameCost, dataFilenameCost,
			gnuplotFilenameCost, "Protocol Costs", results);
}

void createGnuplotFile(string prefix, string rsltFN, string dataFN, string gpFN, 
		string ylabel, ResultPlot[] results ...) {
	import std.array : appender;

	auto app = appender!string();
	formattedWrite(app, `set size ratio 0.71
print GPVAL_TERMINALS
set terminal eps color
set xrange [0.01:1.0]
set output '%s'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data linespoints
#set key at 50,112
set xlabel 'Node Avaiability'
set ylabel '%s' offset 1,0
set tics scale 0.75
plot `, prefix ~ rsltFN, ylabel);

	bool first = true;
	size_t idx = 2;
	foreach(result; results) {
		if(!first) {
			app.put(", ");
		}
		first = false;
		formattedWrite(app, "\"%s%s\" using 1:%s lw 4 ps 0.4 title \"%s R\", ",
				prefix, dataFN, idx++, result.name);
		formattedWrite(app, "\"%s%s\" using 1:%s lw 4 ps 0.4 title \"%s W\"",
				prefix, dataFN, idx++, result.name);
	}
	app.put(";");

	auto datafile = File(prefix ~ gpFN, "w");
	datafile.write(app.data);
}


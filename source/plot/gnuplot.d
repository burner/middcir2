module plot.gnuplot;

import std.experimental.logger;
import std.format : formattedWrite;
import std.stdio : File;

import plot : ResultPlot;

private immutable dataFilenameAvail = ".datafileavail.rslt";
private immutable dataFilenameCost = ".datafilecost.rslt";
private immutable gnuplotFilenameAvail = ".gnuplotavail.gp";
private immutable gnuplotFilenameCost = ".gnuplotcost.gp";
private immutable resultFilenameAvail = ".resultavail.eps";
private immutable resultFilenameCost = ".resultcost.eps";

void gnuPlot(ResultPlot[] results ...) {
	import std.process : execute;
	createDataFiles(results);
	createGnuplotFiles(results);

	auto gnuplot = execute(["gnuplot", "-c", gnuplotFilenameAvail]);
	assert(gnuplot.status == 0);

	gnuplot = execute(["gnuplot", "-c", gnuplotFilenameCost]);
	assert(gnuplot.status == 0);

	auto epstopdf = execute(["epstopdf", resultFilenameAvail]);
	assert(epstopdf.status == 0);

	epstopdf = execute(["epstopdf", resultFilenameCost]);
	assert(epstopdf.status == 0);
}

void createDataFiles(ResultPlot[] results ...) {
	import std.algorithm.iteration : joiner;
	import std.range;
	import std.conv : to;

	auto datafileAvail = File(dataFilenameAvail, "w");
	auto ltwAvail = datafileAvail.lockingTextWriter();

	auto datafileCost = File(dataFilenameCost, "w");
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

void createGnuplotFiles(ResultPlot[] results ...) {
	createGnuplotFile(resultFilenameAvail, dataFilenameAvail,
			gnuplotFilenameAvail, results);

	createGnuplotFile(resultFilenameCost, dataFilenameCost,
			gnuplotFilenameCost, results);
}

void createGnuplotFile(string rsltFN, string dataFN, string gpFN, ResultPlot[] results ...) {
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
set xlabel 'Node Availability'
set ylabel 'Protocol Avaiability' offset 1,0
set tics scale 0.75
plot `, rsltFN);

	bool first = true;
	size_t idx = 2;
	foreach(result; results) {
		if(!first) {
			app.put(", ");
		}
		first = false;
		formattedWrite(app, "\"%s\" using 1:%s lw 4 ps 0.4 title \"%s R\", ",
				dataFN, idx++, result.name);
		formattedWrite(app, "\"%s\" using 1:%s lw 4 ps 0.4 title \"%s W\"",
				dataFN, idx++, result.name);
	}
	app.put(";");

	auto datafile = File(gpFN, "w");
	datafile.write(app.data);
}


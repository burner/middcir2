module plot.gnuplot;

import std.experimental.logger;
import std.format : formattedWrite;
import std.stdio : File;

import plot : ResultPlot;

private immutable dataFilename = ".datafile.rslt";
private immutable gnuplotFilename = ".gnuplot.gp";
private immutable resultFilename = ".result.eps";

void gnuPlot(ResultPlot[] results ...) {
	import std.process : execute;
	createDataFile(results);
	createGnuplotFile(results);

	auto gnuplot = execute(["gnuplot", "-c", gnuplotFilename]);
	assert(gnuplot.status == 0);

	auto epstopdf = execute(["epstopdf", resultFilename]);
	assert(epstopdf.status == 0);
}

void createDataFile(ResultPlot[] results ...) {
	import std.algorithm.iteration : joiner;
	import std.range;
	import std.conv : to;

	auto datafile = File(dataFilename, "w");
	auto ltw = datafile.lockingTextWriter();

	for(size_t i = 0; i < 101; ++i) {
		formattedWrite(ltw, "%.5f ", i/100.0);
		foreach(rslt; results) {
			formattedWrite(ltw, "%.15f ", rslt.result.readAvail[i]);
			formattedWrite(ltw, "%.15f ", rslt.result.writeAvail[i]);
		}
		formattedWrite(ltw, "\n");
	}
}

void createGnuplotFile(ResultPlot[] results ...) {
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
plot `, resultFilename);

	bool first = true;
	size_t idx = 2;
	foreach(result; results) {
		if(!first) {
			app.put(", ");
		}
		first = false;
		formattedWrite(app, "\"%s\" using 1:%s lw 4 ps 0.4 title \"%s R\", ",
				dataFilename, idx++, result.name);
		formattedWrite(app, "\"%s\" using 1:%s lw 4 ps 0.4 title \"%s W\"",
				dataFilename, idx++, result.name);
	}
	app.put(";");

	auto datafile = File(gnuplotFilename, "w");
	datafile.write(app.data);
}


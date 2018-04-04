module plot.gnuplot;

import std.experimental.logger;
import std.exception : enforce;
import std.format : formattedWrite;
import std.stdio : File;
import std.conv : to;

import exceptionhandling;

import plot : ResultPlot;

private immutable dataFilenameAvail = "datafileavail.rslt";
private immutable dataFilenameCost = "datafilecost.rslt";
private immutable gnuplotFilenameAvail = "gnuplotavail.gp";
private immutable gnuplotFilenameCost = "gnuplotcost.gp";
private immutable resultFilenameAvail = "resultavail.tex";
private immutable resultFilenameCost = "resultcost.tex";

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

	auto gnuplot = execute(["gnuplot", "-c", prefix ~ to!string(1) ~ gnuplotFilenameAvail]);
	ensure(gnuplot.status == 0, prefix ~ to!string(1) ~ gnuplotFilenameAvail);

	gnuplot = execute(["gnuplot", "-c", prefix ~ to!string(80) ~ gnuplotFilenameAvail]);
	ensure(gnuplot.status == 0, prefix ~ to!string(80) ~ gnuplotFilenameAvail);

	gnuplot = execute(["gnuplot", "-c", prefix ~ to!string(1) ~gnuplotFilenameCost]);
	ensure(gnuplot.status == 0, prefix ~ to!string(1) ~gnuplotFilenameCost);

	auto epstopdf = execute(["pdflatex", prefix ~ to!string(1) ~ resultFilenameAvail]);
	ensure(epstopdf.status == 0, prefix ~ to!string(1) ~ resultFilenameAvail);

	epstopdf = execute(["pdflatex", prefix ~ to!string(80) ~ resultFilenameAvail]);
	ensure(epstopdf.status == 0, prefix ~ to!string(80) ~ resultFilenameAvail);

	epstopdf = execute(["pdflatex", prefix ~ to!string(1) ~resultFilenameCost]);
	ensure(epstopdf.status == 0, prefix ~ to!string(1) ~resultFilenameCost);
}

void createDataFiles(string prefix, ResultPlot[] results ...) {
	import std.algorithm.iteration : joiner;
	import std.range;
	import std.conv : to;

	foreach(rslt; results) {
		auto datafileAvail = File(prefix ~ rslt.name ~ dataFilenameAvail, "w");
		auto ltwAvail = datafileAvail.lockingTextWriter();

		auto datafileCost = File(prefix ~ rslt.name ~ dataFilenameCost, "w");
		auto ltwCost = datafileCost.lockingTextWriter();

		for(size_t i = 0; i < 101; ++i) {
			formattedWrite(ltwAvail, "%.5f ", i/100.0);
			formattedWrite(ltwCost, "%.5f ", i/100.0);
			formattedWrite(ltwAvail, "%.15f ", rslt.result.readAvail[i]);
			formattedWrite(ltwAvail, "%.15f ", rslt.result.writeAvail[i]);

			formattedWrite(ltwCost, "%.15f ", rslt.result.readCosts[i]);
			formattedWrite(ltwCost, "%.15f ", rslt.result.writeCosts[i]);
			formattedWrite(ltwAvail, "\n");
			formattedWrite(ltwCost, "\n");
		}
	}
}

void createGnuplotFiles(string prefix, ResultPlot[] results ...) {
	createGnuplotFile(prefix, gpAvail, resultFilenameAvail, dataFilenameAvail,
			gnuplotFilenameAvail, "Protocol Availability", 1, results);

	createGnuplotFile(prefix, gpAvail80, resultFilenameAvail, dataFilenameAvail,
			gnuplotFilenameAvail, "Protocol Availability", 80, results);

	createGnuplotFile(prefix, gpCosts, resultFilenameCost, dataFilenameCost,
			gnuplotFilenameCost, "Protocol Costs", 1, results);
}

immutable(string) gpAvail = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex standalone color
set xrange [%f:1.0]
set yrange [:1.0]
set output '%s'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data linespoints
#set key at 50,112
set xlabel 'Node Availability (p)'
set ylabel '%s' offset 1,0
set tics scale 0.75
plot `;

immutable(string) gpAvail80 = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex standalone color
set xrange [%f:1.0]
set yrange [:1.0]
set output '%s'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key right bottom
set style data linespoints
#set key at 50,112
set xlabel 'Node Availability (p)'
set ylabel '%s' offset 1,0
set tics scale 0.75
plot `;

immutable(string) gpCosts = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex standalone color
set xrange [%f:1.0]
set output '%s'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data linespoints
#set key at 50,112
set xlabel 'Node Availability (p)'
set ylabel '%s' offset 1,0
set tics scale 0.75
plot `;

void createGnuplotFile(string prefix, string gpString, string rsltFN, 
		string dataFN, string gpFN, string ylabel, int xmin, ResultPlot[] results ...) 
{
	import std.array : appender;

	auto app = appender!string();
	formattedWrite(app, gpString, xmin / 100.0, prefix ~ to!string(xmin) ~ rsltFN, ylabel);

	bool first = true;
	foreach(result; results) {
		size_t idx = 2;
		if(!first) {
			app.put(", ");
		}
		first = false;
		formattedWrite(app, "\"%s%s%s\" using 1:%s lw 4 ps 0.4 title \"%s R\", ",
				prefix, result.name, dataFN, idx++, result.name);
		formattedWrite(app, "\"%s%s%s\" using 1:%s lw 4 ps 0.4 title \"%s W\"",
				prefix, result.name, dataFN, idx++, result.name);
	}
	app.put(";");

	auto datafile = File(prefix ~ to!string(xmin) ~ gpFN, "w");
	datafile.write(app.data);
}


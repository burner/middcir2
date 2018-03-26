module boxplotmapping;

import std.stdio : File, writeln;
import std.array : front, back, empty;
import std.experimental.logger;
import std.conv : to;
import exceptionhandling;
import std.format : format, formattedWrite;
import plot.gnuplot : ResultPlot;

void latticeBoxplot() {
	import protocols.lattice;
	import protocols;
	import plot.gnuplot;
	foreach(it; [[3,3], [2,4], [4,2]]) {
		auto l = Lattice(it[0],it[1]);
		auto r = l.calcAC();
		auto rp = ResultPlot(format("Lattice%dx%d", it[0], it[1]), r);
		gnuPlot(format("Results/Lattice%dx%d", it[0], it[1]), "", rp);
	}
}

void mcsBoxplot() {
	import protocols.mcs;
	import protocols;
	import plot.gnuplot;
	foreach(it; [8, 9]) {
		auto l = MCS(it);
		auto r = l.calcAC();
		auto rp = ResultPlot(format("MCS%d", it), r);
		gnuPlot(format("Results/MCS%d", it), "", rp);
	}
}

void gridBoxplot() {
	import protocols.grid;
	import protocols;
	import plot.gnuplot;
	foreach(it; [[3,3], [2,4], [4,2]]) {
		auto l = Grid(it[0],it[1]);
		auto r = l.calcAC();
		auto rp = ResultPlot(format("Grid%dx%d", it[0], it[1]), r);
		gnuPlot(format("Results/Grid%dx%d", it[0], it[1]), "", rp);
	}
}

void boxplot() {
	latticeBoxplot();
	gridBoxplot();
	mcsBoxplot();
	boxplot("graphs9nodes3.json_Results", "Lattice", "3x3", "avail",
			"Results/Lattice3x3");
	boxplot("graphs9nodes3.json_Results", "Lattice", "3x3", "cost",
			"Results/Lattice3x3");
	boxplot("graphs9nodes3.json_Results", "Grid", "3x3", "avail",
			"Results/Grid3x3");
	boxplot("graphs9nodes3.json_Results", "Grid", "3x3", "cost",
			"Results/Grid3x3");
	boxplot("graphs9nodes3.json_Results", "MCS", "0x0", "avail",
			"Results/MCS9");
	boxplot("graphs9nodes3.json_Results", "MCS", "0x0", "cost", 
			"Results/MCS9");
	boxplotMakefile("graphs9nodes3.json_Results", 9);
	boxplot("graphs8nodes3.json_Results", "Lattice", "2x4", "avail",
			"Results/Lattice2x4");
	boxplot("graphs8nodes3.json_Results", "Lattice", "2x4", "cost",
			"Results/Lattice2x4");
	boxplot("graphs8nodes3.json_Results", "Grid", "2x4", "avail",
			"Results/Grid2x4");
	boxplot("graphs8nodes3.json_Results", "Grid", "2x4", "cost",
			"Results/Grid2x4");
	boxplot("graphs8nodes3.json_Results", "Lattice", "4x2", "avail",
			"Results/Lattice2x4");
	boxplot("graphs8nodes3.json_Results", "Lattice", "4x2", "cost",
			"Results/Lattice4x2");
	boxplot("graphs8nodes3.json_Results", "Grid", "4x2", "avail",
			"Results/Grid4x2");
	boxplot("graphs8nodes3.json_Results", "Grid", "4x2", "cost",
			"Results/Grid4x2");
	boxplot("graphs8nodes3.json_Results", "MCS", "0x0", "avail",
			"Results/MCS8");
	boxplot("graphs8nodes3.json_Results", "MCS", "0x0", "cost", 
			"Results/MCS8");
	boxplotMakefile("graphs8nodes3.json_Results", 8);
	//boxplot("graphs6nodes3.json_Results", "Lattice", "2x3", "avail");
	//boxplot("graphs6nodes3.json_Results", "Lattice", "2x3", "cost");
	//boxplot("graphs6nodes3.json_Results", "Grid", "2x3", "avail");
	//boxplot("graphs6nodes3.json_Results", "Grid", "2x3", "cost");
	//boxplot("graphs6nodes3.json_Results", "Lattice", "3x2", "avail");
	//boxplot("graphs6nodes3.json_Results", "Lattice", "3x2", "cost");
	//boxplot("graphs6nodes3.json_Results", "Grid", "3x2", "avail");
	//boxplot("graphs6nodes3.json_Results", "Grid", "3x2", "cost");
	//boxplot("graphs6nodes3.json_Results", "MCS", "0x0", "avail");
	//boxplot("graphs6nodes3.json_Results", "MCS", "0x0", "cost");
	//boxplotMakefile("graphs6nodes3.json_Results", 6);
}

void boxplotMakefile(string foldername, size_t nn) {
	auto f = File(foldername ~ "/Makefile", "w");
	auto ltw = f.lockingTextWriter();
	formattedWrite(ltw, "all: ");

	string[] rw = ["read", "write"];
	string[] ca = ["cost", "avail"];
	string[][string] dim;
	dim["MCS"] = ["0x0"];
	string[] gp;
	string[] tlp;
	switch(nn) {
		case 6:
			dim["Grid"] = ["3x2", "2x3"];
			dim["Lattice"] = ["3x2", "2x3"];
			break;
		case 8:
			dim["Grid"] = ["4x2", "2x4"];
			dim["Lattice"] = ["4x2", "2x4"];
			break;
		case 9:
			dim["Grid"] = ["3x3"];
			dim["Lattice"] = ["3x3"];
			break;
		default:
			assert(false);
	}

	foreach(it; ca) {
		foreach(jt; rw) {
			foreach(kt; ["MCS", "Lattice", "Grid"]) {
				foreach(d; dim[kt]) {
					formattedWrite(ltw, "mappingavail%s%s%s%s.tex ", kt, it,
							jt, d
						);
				}
			}
		}
	}
	formattedWrite(ltw, "\n\n");

	foreach(it; ca) {
		foreach(jt; rw) {
			foreach(kt; ["MCS", "Lattice", "Grid"]) {
				foreach(d; dim[kt]) {
					formattedWrite(ltw, "mappingavail%s%s%s%s.tex: ", kt, it,
							jt, d
						);
					formattedWrite(ltw, "Quantils%s%s%s%s.gp", kt,
							it, jt, d
						);
					formattedWrite(ltw, " Quantils%s%s%s%s_sd.gp\n", kt,
							it, jt, d
						);
					formattedWrite(ltw, "\tgnuplot Quantils%s%s%s%s.gp\n", kt,
							it, jt, d
						);
					formattedWrite(ltw, "\tgnuplot Quantils%s%s%s%s_sd.gp\n", kt,
							it, jt, d
						);
					formattedWrite(ltw, "\tpdflatex mappingavail%s%s%s%s.tex\n", 
							kt, it, jt, d
						);
					formattedWrite(ltw, "\tpdflatex mappingavail%s%s%s%s_sd.tex\n\n", 
							kt, it, jt, d
						);
				}
			}
		}
	}
}

void boxplot(string foldername, string protocol, string xx, string aOrC,
		string compareFolder) 
{
	import std.file : dirEntries, SpanMode;		
	import std.algorithm.searching : canFind;
	import std.algorithm.iteration : filter, splitter;
	import std.algorithm.sorting : sort;
	import std.math : isNaN;

	double[][101] reads;
	double[][101] writes;

	foreach(de; dirEntries(foldername, SpanMode.breadth)
			.filter!(a => (a.name.canFind(protocol)
				&& a.name.canFind(xx)
				&& a.name.canFind(aOrC)
				&& a.name.canFind("0.50")
				&& a.name.canFind("row")
				&& !a.name.canFind("rowc")
				&& a.name.canFind(".data"))))
	{
		auto f = File(de.name, "r");
		size_t idx = 0;
		foreach(l; f.byLine()) {
			auto s = l.splitter(' ');
			ensure(!s.empty);
			s.popFront();
			ensure(!s.empty);
			reads[idx] ~= to!double(s.front);
			if(isNaN(reads[idx].back)) {
				reads[idx].back = 0.0;
			}
			s.popFront();
			ensure(!s.empty);
			writes[idx] ~= to!double(s.front);
			if(isNaN(writes[idx].back)) {
				writes[idx].back = 0.0;
			}
			++idx;
		}
	}

	for(size_t i = 0; i < 101; ++i) {
		reads[i].sort();
		writes[i].sort();
	}

	writeSortedData(foldername, protocol, aOrC, "read", reads, xx,
			compareFolder);
	writeSortedData(foldername, protocol, aOrC, "write", writes, xx,
			compareFolder);
}

double computeStd(double midpoint, double[] data) {
	import std.math : pow, sqrt;
	double ret = 1.0 / cast(double)(data.length - 1);

	double sum = 0.0;
	foreach(it; data) {
		sum += pow(it - midpoint, 2.0);
	}

	ret = ret * sum;
	return sqrt(ret);
}

double computeMAD(double midpoint, double[] data) {
	import std.math : pow, sqrt, abs;
	import std.algorithm.sorting : sort;
	import utils : percentile;

	double[] dataDup = data.dup;
	foreach(ref it; dataDup) {
		it = abs(it - midpoint);
	}

	sort(dataDup);
	return percentile(dataDup, 0.50); 
}

double[101] readComp(string compareFolder, string protocol, string row, string aOrC) {
	import std.range : drop, dropOne, takeOne, split;
	import std.algorithm : map, find;
	import std.array : array;

	auto f = File(compareFolder ~ "/" ~ find(compareFolder,
				"/").dropOne() ~ "datafile" ~ aOrC ~
			".rslt", "r"
		);
	auto tmp = f.byLine()
				.map!split()
				.map!(it => it.drop(row == "read" ? 1 : 2))
				.map!(it => it.takeOne())
				.map!(it => it.front)
				.map!(m => to!double(m))
				.array;

	writeln(tmp);

	double[101] ret;
	ensure(tmp.length == 101);
	ret[] = tmp;
	return ret;
}

void writeSortedData(string foldername, string protocol, string aOrC,
	   	string row, double[][101] data, string xx, string compareFolder) 
{
	import utils : percentile;
	import std.algorithm.iteration : sum;
	if(data.empty) {
		logf("%s %s %s %s", foldername, protocol, aOrC, row);
		return;
	}

	double[101] notMapped = readComp(compareFolder, protocol, row, aOrC);

	auto f = File(foldername ~ "/Quantils" ~ protocol ~ aOrC ~ row ~ xx ~ ".data",
			"w");
	ensure(data.length == 101);
	auto ltw = f.lockingTextWriter();
	for(size_t i = 0; i < 101; ++i) {
		if(data[i].empty) {
			logf("%s %s %s %s %s %s", foldername, protocol, aOrC, row, xx, i);
			continue;
		}
		double avg = sum(data[i], 0.0) / data[i].length;
		double median = percentile(data[i], 0.50);
		double mad = computeMAD(median, data[i]);
		formattedWrite(ltw, "%15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f\n", i / 100.0, 
				data[i].front,
				percentile(data[i], 0.25),
				median,
				percentile(data[i], 0.75),
				data[i].back,
				avg,
				computeStd(avg, data[i]),
				mad,
				notMapped[i]
			);
	}

	writeGnuplot(foldername, protocol, aOrC, row, xx);
}

void writeGnuplot(string foldername, string protocol, string aOrC, string row,
		string xx) 
{
	import std.array : appender;
	if(aOrC == "avail") {
		{
			immutable(string) gpAvail = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex color standalone
set xrange [%f:1.0]
set yrange [:1.0]
set output '%s'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data boxplot
#set key at 50,112
set xlabel 'Replica Availability (p)'
set ylabel '%s' offset 1,0
set tics scale 0.75
plot `;

			auto app = appender!string();
			formattedWrite(app, gpAvail, 0.0, 
					"mappingavail" ~ protocol ~ aOrC ~ row ~ xx ~ ".tex", 
					aOrC == "avail" ? "Operation Availability" : "Operation Cost");
			formattedWrite(app, "'Quantils" ~ protocol ~ aOrC ~ row ~ xx ~ ".data'");
			formattedWrite(app, " using 1:3:2:6:5 with candlesticks notitle whiskerbars, \\\n");
			formattedWrite(app, "'' using 1:4:4:4:4 with candlesticks lt -1 notitle, \\\n");
			formattedWrite(app, "'' using 1:7:7:7:7 with candlesticks lt -1 lc 'red' notitle, \\\n");
			formattedWrite(app, "'' using 1:10 with lines lc '#00BFFF' linewidth 4 notitle");

			auto f = File(foldername ~ "/Quantils" ~ protocol ~ aOrC ~ row 
					~ xx ~ ".gp", "w");
			formattedWrite(f.lockingTextWriter(), "%s", app.data);
		}
		{
			immutable(string) gpAvail = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex color standalone
set xrange [%f:1.0]
set autoscale y
set output '%s'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data linespoints
#set key at 50,112
set xlabel 'Replica Availability (p)'
set ylabel '%s' offset 1,0
set tics scale 0.75
plot `;

			auto app = appender!string();
			formattedWrite(app, gpAvail, 0.0, 
					"mappingavail" ~ protocol ~ aOrC ~ row ~ xx ~ "_sd.tex", 
					aOrC == "avail" ? "Operation Availability SD" : "Operation Cost SD");
			formattedWrite(app, "'Quantils" ~ protocol ~ aOrC ~ row ~ xx ~ ".data'");
			formattedWrite(app, " using 1:8 title \"SD\", \\\n");
			formattedWrite(app, "'' using 1:9 lc 'red' title \"MAD\"");

			auto f = File(foldername ~ "/Quantils" ~ protocol ~ aOrC ~ row ~
					xx ~ "_sd.gp", "w");
			formattedWrite(f.lockingTextWriter(), "%s", app.data);
		}

	} else {
		{
			immutable(string) gpAvail = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex color standalone
set xrange [%f:1.0]
set autoscale y
#set offsets 0, 0, 1, 0
set output '%s'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data boxplot
#set key at 50,112
set xlabel 'Replica Availability (p)'
set ylabel '%s' offset 1,0
set tics scale 0.75
plot `;

			auto app = appender!string();
			formattedWrite(app, gpAvail, 0.0, 
					"mappingavail" ~ protocol ~ aOrC ~ row ~ xx ~ ".tex", 
					aOrC == "avail" ? "Operation Availability" : "Operation Cost");
			formattedWrite(app, "'Quantils" ~ protocol ~ aOrC ~ row ~ xx ~ ".data'");
			formattedWrite(app, " using 1:3:2:6:5 with candlesticks  notitle whiskerbars, \\\n");
			formattedWrite(app, "'' using 1:4:4:4:4 with candlesticks lt -1 notitle, \\\n");
			formattedWrite(app, "'' using 1:7:7:7:7 with candlesticks lt -1 lc 'red' notitle, \\\n");
			formattedWrite(app, "'' using 1:10 with lines lc '#00BFFF' linewidth 2 notitle");

			auto f = File(foldername ~ "/Quantils" ~ protocol ~ aOrC ~ row ~ xx ~ ".gp", "w");
			formattedWrite(f.lockingTextWriter(), "%s", app.data);
		}
		{
			immutable(string) gpAvail = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex color standalone
set xrange [%f:1.0]
set autoscale y
#set offsets 0, 0, 1, 0
set output '%s'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data linespoints
#set key at 50,112
set xlabel 'Replica Availability (p)'
set ylabel '%s' offset 1,0
set tics scale 0.75
plot `;

			auto app = appender!string();
			formattedWrite(app, gpAvail, 0.0, 
					"mappingavail" ~ protocol ~ aOrC ~ row ~ xx ~ "_sd.tex", 
					aOrC == "avail" ? "Operation Availability" : "Operation Cost");
			formattedWrite(app, "'Quantils" ~ protocol ~ aOrC ~ row ~ xx ~ ".data'");
			formattedWrite(app, " using 1:8 title \"SD\", \\\n");
			formattedWrite(app, "'' using 1:9 lc 'red' title \"MAD\"");

			auto f = File(foldername ~ "/Quantils" ~ protocol ~ aOrC ~ row ~
					xx ~ "_sd.gp", "w");
			formattedWrite(f.lockingTextWriter(), "%s", app.data);
		}
	}
}

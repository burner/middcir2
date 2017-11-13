module boxplotmapping;

import std.stdio;
import std.array : front, back, empty;
import std.experimental.logger;
import std.conv : to;
import exceptionhandling;
import std.format : formattedWrite;

void boxplot() {
	boxplot("graphs9nodes3.json_Results", "Lattice", "3x3", "avail");
	boxplot("graphs9nodes3.json_Results", "Lattice", "3x3", "cost");
	boxplot("graphs9nodes3.json_Results", "Grid", "3x3", "avail");
	boxplot("graphs9nodes3.json_Results", "Grid", "3x3", "cost");
	boxplot("graphs9nodes3.json_Results", "MCS", "0x0", "avail");
	boxplot("graphs9nodes3.json_Results", "MCS", "0x0", "cost");
}

void boxplot(string foldername, string protocol, string xx, string aOrC) {
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

	writeSortedData(foldername, protocol, aOrC, "read", reads);
	writeSortedData(foldername, protocol, aOrC, "write", writes);
}

void writeSortedData(string foldername, string protocol, string aOrC,
	   	string row, double[][101] data) 
{
	import utils : percentile;
	import std.algorithm.iteration : sum;
	if(data.empty) {
		logf("%s %s %s %s", foldername, protocol, aOrC, row);
		return;
	}
	auto f = File(foldername ~ "/Quantils" ~ protocol ~ aOrC ~ row ~ ".data",
			"w");
	ensure(data.length == 101);
	auto ltw = f.lockingTextWriter();
	for(size_t i = 0; i < 101; ++i) {
		if(data[i].empty) {
			logf("%s %s %s %s %s", foldername, protocol, aOrC, row, i);
			continue;
		}
		formattedWrite(ltw, "%15.13f %15.13f %15.13f %15.13f %15.13f %15.13f %15.13f\n", i / 100.0, 
				data[i].front,
				percentile(data[i], 0.25),
				percentile(data[i], 0.50),
				percentile(data[i], 0.75),
				data[i].back,
				sum(data[i], 0.0) / data[i].length);
	}

	writeGnuplot(foldername, protocol, aOrC, row);
}

void writeGnuplot(string foldername, string protocol, string aOrC, string row) {
	import std.array : appender;
	if(aOrC == "avail") {
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
set xlabel 'Node Availability (p)'
set ylabel '%s' offset 1,0
set tics scale 0.75
plot `;

		auto app = appender!string();
		formattedWrite(app, gpAvail, 0.0, 
				"mappingavail" ~ protocol ~ aOrC ~ row ~ ".tex", 
				aOrC == "avail" ? "Operation Availability" : "Operation Cost");
		formattedWrite(app, "'Quantils" ~ protocol ~ aOrC ~ row ~ ".data'");
		formattedWrite(app, " using 1:3:2:6:5 with candlesticks notitle whiskerbars, \\\n");
		formattedWrite(app, "'' using 1:4:4:4:4 with candlesticks lt -1 notitle, \\\n");
		formattedWrite(app, "'' using 1:7:7:7:7 with candlesticks lt -1 lc 'red' notitle");

		auto f = File(foldername ~ "/Quantils" ~ protocol ~ aOrC ~ row ~ ".gp", "w");
		formattedWrite(f.lockingTextWriter(), "%s", app.data);
	} else {
		immutable(string) gpAvail = `set size ratio 0.71
print GPVAL_TERMINALS
set terminal epslatex color standalone
set xrange [%f:1.0]
set output '%s'
set border linewidth 1.5
# Grid
set grid back lc rgb "black"
set border 3 back lc rgb "black"
set key left top
set style data boxplot
#set key at 50,112
set xlabel 'Node Availability (p)'
set ylabel '%s' offset 1,0
set tics scale 0.75
plot `;

		auto app = appender!string();
		formattedWrite(app, gpAvail, 0.0, 
				"mappingavail" ~ protocol ~ aOrC ~ row ~ ".tex", 
				aOrC == "avail" ? "Operation Availability" : "Operation Cost");
		formattedWrite(app, "'Quantils" ~ protocol ~ aOrC ~ row ~ ".data'");
		formattedWrite(app, " using 1:3:2:6:5 with candlesticks  notitle whiskerbars, \\\n");
		formattedWrite(app, "'' using 1:4:4:4:4 with candlesticks lt -1 notitle, \\\n");
		formattedWrite(app, "'' using 1:7:7:7:7 with candlesticks lt -1 lc 'red' notitle");

		auto f = File(foldername ~ "/Quantils" ~ protocol ~ aOrC ~ row ~ ".gp", "w");
		formattedWrite(f.lockingTextWriter(), "%s", app.data);
	}
}

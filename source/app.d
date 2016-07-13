import std.stdio;
import std.range : lockstep;

import protocols.mcs;
import plot;
import plot.gnuplot;

void main() {
	auto mcs = MCS(9);
	auto rslt = mcs.calcP();
	int idx = 0;
	foreach(ref r, w; lockstep(rslt.readAvail[], rslt.writeAvail[])) {
		writefln("%3d %.15f %.15f", idx++, r, w);
	}

	gnuPlot(ResultPlot("MCS9", rslt));
}

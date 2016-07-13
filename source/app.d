import std.stdio;
import std.range : lockstep;

import protocols.mcs;
import plot;
import plot.gnuplot;

void main() {
	int mcsN = 20;
	/*auto mcs = MCS(mcsN);
	auto rsltMCS = ResultPlot(mcs.name(), mcs.calcP());*/

	auto mcsF = MCSFormula(mcsN);
	auto rsltMCSF = ResultPlot(mcsF.name(), mcsF.calcP());

	gnuPlot(/*rsltMCS,*/ rsltMCSF);
}

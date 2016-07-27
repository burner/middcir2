import std.stdio;
import std.range : lockstep;
import std.algorithm : permutations, Permutations;
import std.experimental.logger;

import protocols.mcs;
import plot;
import plot.gnuplot;
import utils;

void main() {
	int mcsN = 10;
	auto mcs = MCS(mcsN);
	auto mcsRslt = mcs.calcP();
	auto rsltMCS = ResultPlot(mcs.name(), mcsRslt);

	auto mcsF = MCSFormula(mcsN);
	auto mcsFRslt = mcsF.calcP();
	auto rsltMCSF = ResultPlot(mcsF.name(), mcsFRslt);

	gnuPlot(rsltMCS, rsltMCSF);
}

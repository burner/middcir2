import std.stdio;
import std.range : lockstep;
import std.math : approxEqual;
import std.algorithm : permutations, Permutations;
import std.experimental.logger;

import protocols.mcs;
import plot;
import plot.gnuplot;
import utils;

bool equal(double a, double b) {
	return approxEqual(a, b, 0.000001);
}

void main() {
	int[8] toPerm = [0,1,2,3,4,5,6,7];

	foreach(perm; permutations(toPerm[])) {
		logf("%s", perm);
	}

	int mcsN = 20;
	auto mcs = MCS(mcsN);
	auto mcsRslt = mcs.calcP();
	auto rsltMCS = ResultPlot(mcs.name(), mcs.calcP());

	auto mcsF = MCSFormula(mcsN);
	auto mcsFRslt = mcsF.calcP();
	auto rsltMCSF = ResultPlot(mcsF.name(), mcsFRslt);

	compare(mcsFRslt.readAvail, mcsRslt.readAvail, &equal);
	compare(mcsFRslt.writeAvail, mcsRslt.writeAvail, &equal);

	gnuPlot(rsltMCS, rsltMCSF);
}

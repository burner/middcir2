static import std.array;
import std.stdio;
import std.range : lockstep;
import std.algorithm : permutations, Permutations;
import std.experimental.logger;

import protocols.mcs;
import protocols.grid;
import protocols.lattice;
import protocols.crossing;
import plot;
import plot.gnuplot;
import utils;
import graph;

void main() {
	/*int mcsN = 16;
	auto mcs = MCS(mcsN);
	auto mcsRslt = mcs.calcAC();
	auto rsltMCS = ResultPlot(mcs.name(), mcsRslt);
	*/

	logf("MCS");
	auto mcsF = MCSFormula(16);
	auto mcsFRslt = mcsF.calcAC();
	auto rsltMCSF = ResultPlot(mcsF.name(), mcsFRslt);

	//gnuPlot(rsltMCS, rsltMCSF);

	/*auto grid = Grid(4,3);
	auto gridRslt = grid.calcAC();
	auto rsltGrid = ResultPlot(grid.name(), gridRslt);
	*/
	//gnuPlot(rsltMCS, rsltGrid);
	logf("Grid");
	auto grid = GridFormula(4,4);
	auto gridRslt = grid.calcAC();
	auto rsltGrid = ResultPlot(grid.name(), gridRslt);

	logf("Lattice");
	auto tl = Lattice(4,4);
	auto tlRslt = tl.calcAC();
	auto rsltTL = ResultPlot(tl.name(), tlRslt);

	auto g = genTestGraph!32();
	logf("Crossing");
	auto c = Crossing(g);
	auto cRslt = c.calcAC();
	auto rsltC = ResultPlot(c.name(), cRslt);

	logf("Gen Plot");
	gnuPlot(rsltMCSF, rsltTL, rsltGrid, rsltC);

	//auto writeAvailReverse = gridRslt.writeAvail.dup;
	//reverse(writeAvailReverse);
	//compare(gridRslt.readAvail, writeAvailReverse, &pointFive);


}

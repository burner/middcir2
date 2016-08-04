static import std.array;
import std.stdio;
import std.range : lockstep;
import std.algorithm : permutations, Permutations;
import std.experimental.logger;

import protocols.mcs;
import protocols.grid;
import protocols.lattice;
import plot;
import plot.gnuplot;
import utils;

void main() {
	/*int mcsN = 16;
	auto mcs = MCS(mcsN);
	auto mcsRslt = mcs.calcAC();
	auto rsltMCS = ResultPlot(mcs.name(), mcsRslt);
	*/

	/*auto mcsF = MCSFormula(mcsN);
	auto mcsFRslt = mcsF.calcAC();
	auto rsltMCSF = ResultPlot(mcsF.name(), mcsFRslt);

	gnuPlot(rsltMCS, rsltMCSF);
	*/

	/*auto grid = Grid(4,3);
	auto gridRslt = grid.calcAC();
	auto rsltGrid = ResultPlot(grid.name(), gridRslt);
	*/
	//gnuPlot(rsltMCS, rsltGrid);
	auto grid = GridFormula(4,4);
	auto gridRslt = grid.calcAC();
	auto rsltGrid = ResultPlot(grid.name(), gridRslt);

	auto tl = Lattice(4,4);
	auto tlRslt = tl.calcAC();
	auto rsltTL = ResultPlot(tl.name(), tlRslt);
	gnuPlot(rsltTL, rsltGrid);

	//auto writeAvailReverse = gridRslt.writeAvail.dup;
	//reverse(writeAvailReverse);
	//compare(gridRslt.readAvail, writeAvailReverse, &pointFive);


}

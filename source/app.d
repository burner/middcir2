static import std.array;
import std.stdio;
import std.range : lockstep;
import std.algorithm : permutations, Permutations;
import std.experimental.logger;

import protocols.mcs;
import protocols.grid;
import plot;
import plot.gnuplot;
import utils;

void main() {
	int mcsN = 20;
	auto mcs = MCS(mcsN);
	auto mcsRslt = mcs.calcAC();
	auto rsltMCS = ResultPlot(mcs.name(), mcsRslt);

	/*auto mcsF = MCSFormula(mcsN);
	auto mcsFRslt = mcsF.calcAC();
	auto rsltMCSF = ResultPlot(mcsF.name(), mcsFRslt);

	gnuPlot(rsltMCS, rsltMCSF);
	*/

	log();
	auto grid = Grid(4,5);
	auto gridRslt = grid.calcAC();
	auto rsltGrid = ResultPlot(grid.name(), gridRslt);
	gnuPlot(rsltMCS, rsltGrid);

	//auto writeAvailReverse = gridRslt.writeAvail.dup;
	//reverse(writeAvailReverse);
	//compare(gridRslt.readAvail, writeAvailReverse, &pointFive);


	/*auto gridF = GridFormula(4,4);
	auto gridFRslt = gridF.calcAC();
	auto rsltFGrid = ResultPlot(gridF.name(), gridFRslt);
	*/
}

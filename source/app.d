static import std.array;
import std.stdio;
import std.container.array;
import std.range : lockstep;
import std.format : format;
import std.algorithm : permutations, Permutations;
import std.experimental.logger;

import protocols.mcs;
import protocols.grid;
import protocols.lattice;
import protocols.crossing;
import plot;
import planar;
import plot.gnuplot;
import utils;
import graph;
import mapping;

void main() {
	/*int mcsN = 16;
	auto mcs = MCS(mcsN);
	auto mcsRslt = mcs.calcAC();
	auto rsltMCS = ResultPlot(mcs.name(), mcsRslt);
	*/

	/*logf("MCS");
	auto mcsF = MCSFormula(16);
	auto mcsFRslt = mcsF.calcAC();
	auto rsltMCSF = ResultPlot(mcsF.name(), mcsFRslt);
	*/

	//gnuPlot(rsltMCS, rsltMCSF);

	/*auto grid = Grid(4,3);
	auto gridRslt = grid.calcAC();
	auto rsltGrid = ResultPlot(grid.name(), gridRslt);
	*/
	//gnuPlot(rsltMCS, rsltGrid);
	/*logf("Grid");
	auto grid = GridFormula(4,4);
	auto gridRslt = grid.calcAC();
	auto rsltGrid = ResultPlot(grid.name(), gridRslt);*/

	/*logf("Lattice");
	auto tl = Lattice(4,4);
	auto tlRslt = tl.calcAC();
	auto rsltTL = ResultPlot(tl.name(), tlRslt);
	*/

	/+
	auto g = genTestGraph!32();
	g.setEdge(2, 13);
	Array!(Graph!32) planarGraphs;
	makePlanar(g, planarGraphs);
	logf("%s planar graphs", planarGraphs.length);

	/*logf("Crossing");
	auto c = Crossing(g);
	auto cRslt = c.calcAC();
	auto rsltC = ResultPlot(c.name(), cRslt);
	*/

	ResultPlot[] rsltC;
	for(int i = 0; i < planarGraphs.length; ++i) {
		auto c = Crossing(planarGraphs[i]);
		auto cRslt = c.calcAC();
		rsltC ~= ResultPlot(format("%s-%s",c.name(), i), cRslt);
	}

	logf("Gen Plot");
	//gnuPlot(rsltMCSF, rsltTL, rsltGrid, rsltC);
	gnuPlot(rsltC);+/

	//auto writeAvailReverse = gridRslt.writeAvail.dup;
	//reverse(writeAvailReverse);
	//compare(gridRslt.readAvail, writeAvailReverse, &pointFive);

	auto lattice = Lattice(3,3);
	auto latticeRslt = lattice.calcAC();
	logf("LatticeRslt done");
	auto pnt = makeNine!16();
	
	auto map = Mappings!(32,16)(lattice.graph, pnt);
	auto mapRslt = map.calcAC(lattice.read, lattice.write);
	logf("Mapping done");

	gnuPlot(ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt)
	);

}

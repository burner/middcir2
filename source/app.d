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

void MCSAgainstMCS(int mcsN = 16) {
	auto mcs = MCS(mcsN);
	auto mcsRslt = mcs.calcAC();
	auto rsltMCS = ResultPlot(mcs.name(), mcsRslt);

	auto mcsF = MCSFormula(mcsN);
	auto mcsFRslt = mcsF.calcAC();
	auto rsltMCSF = ResultPlot(mcsF.name(), mcsFRslt);

	gnuPlot(format("Results/MCS%s", mcsN), rsltMCS, rsltMCSF);
}

void gridAgainstGrid(int nr, int nc) {
	auto grid = Grid(nr, nc);
	auto gridRslt = grid.calcAC();
	auto rsltGrid = ResultPlot(grid.name(), gridRslt);

	auto gridF = GridFormula(nr, nc);
	auto gridFRslt = gridF.calcAC();
	auto rsltFGrid = ResultPlot(gridF.name(), gridFRslt);

	gnuPlot(format("Results/Grid%sX%s", nr, nc), rsltGrid, rsltFGrid);
}

void lattice(int nr, int nc) {
	auto tl = Lattice(nr, nc);
	auto tlRslt = tl.calcAC();
	auto rsltTL = ResultPlot(tl.name(), tlRslt);

	gnuPlot(format("Results/Lattice%sX%s", nr, nc), rsltTL);
}

void latticeMapped() {
	auto lattice = Lattice(3,3);
	auto latticeRslt = lattice.calcAC();
	logf("LatticeRslt done");
	auto pnt = makeNine!16();
	
	auto map = Mappings!(32,32)(lattice.graph, lattice.graph);
	auto mapRslt = map.calcAC(lattice.read, lattice.write);
	logf("Mapping done");

	gnuPlot("Results/TLMapped", 
			ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt)
	);
}

void main() {
	//lattice(4,4);
	//gridAgainstGrid(4,4);
	MCSAgainstMCS(15);
}

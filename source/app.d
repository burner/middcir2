static import std.array;
import std.stdio;
import std.container.array;
import std.range : lockstep;
import std.format : format;
import std.algorithm : permutations, Permutations;
import std.experimental.logger;
import std.datetime : StopWatch;

import protocols;
import protocols.mcs;
import protocols.grid;
import protocols.lattice;
import protocols.crossing;
import plot;
import planar;
import plot.gnuplot;
import plot.mappingplot;
import utils;
import graph;
import mapping;

//version(release) {
	//version = exceptionhandling_release_asserts;
//}

void MCSAgainstMCS(int mcsN = 16) {
	auto mcs = MCS(mcsN);
	auto mcsRslt = mcs.calcAC();
	auto rsltMCS = ResultPlot(mcs.name(), mcsRslt);

	auto mcsF = MCSFormula(mcsN);
	auto mcsFRslt = mcsF.calcAC();
	auto rsltMCSF = ResultPlot(mcsF.name(), mcsFRslt);

	gnuPlot(format("Results/MCS%s", mcsN), "", rsltMCS, rsltMCSF);
}

void gridAgainstGrid(int nc, int nr) {
	auto grid = Grid(nc, nr);
	auto gridRslt = grid.calcAC();
	auto rsltGrid = ResultPlot(grid.name(), gridRslt);

	auto gridF = GridFormula(nr, nc);
	auto gridFRslt = gridF.calcAC();
	auto rsltFGrid = ResultPlot(gridF.name(), gridFRslt);

	gnuPlot(format("Results/Grid%sX%s", nr, nc), "", rsltGrid, rsltFGrid);
}

void lattice(int nc, int nr) {
	auto tl = Lattice(nc, nr);
	auto tlRslt = tl.calcAC();
	auto rsltTL = ResultPlot(tl.name(), tlRslt);

	gnuPlot(format("Results/Lattice%sX%s", nr, nc), "", rsltTL);
}

void latticeMapped() {
	auto lattice = Lattice(3,3);
	auto latticeRslt = lattice.calcAC();
	logf("LatticeRslt done");
	auto pnt = makeNine!32();

	auto crossing = Crossing(pnt);
	auto crossingRslt = crossing.calcAC();
	
	auto map = Mappings!(32,32)(lattice.graph, pnt, 1.0, 0.5);
	auto mapRslt = map.calcAC(lattice.read, lattice.write);
	logf("Mapping done");

	mappingPlot("Results/Lattice3x3Mapped", map,
			ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(crossing.name(), crossingRslt),
			ResultPlot(map.name(lattice.name()), mapRslt)
	);
}

void latticeMapped2() {
	auto lattice = Lattice(2,3);
	auto latticeRslt = lattice.calcAC();
	auto pnt = makeSix!16();

	auto map = Mappings!(32,16)(lattice.graph, pnt, 1.0, 0.5);
	auto mapRslt = map.calcAC(lattice.read, lattice.write);

	mappingPlot("Results/Lattice2x3Mapped", map,
			ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt)
	);
}

void crossings6() {
	auto pnt = makeSix!32();

	auto crs = Crossings(pnt);
	auto crsRslt = crs.calcAC();
	auto cr = Crossing(pnt);
	auto crRslt = cr.calcAC();

	gnuPlot("Results/Crossings6", "", ResultPlot(crs.name(), crsRslt),
			ResultPlot(cr.name(), crRslt)
	);
}

void crossings9() {
	auto pnt = makeNine!32();

	auto crs = Crossings(pnt);
	auto crsRslt = crs.calcAC();
	auto cr = Crossing(pnt);
	auto crRslt = cr.calcAC();

	gnuPlot("Results/Crossings9", "", ResultPlot(crs.name(), crsRslt),
			ResultPlot(cr.name(), crRslt)
	);
}

void latticeMCSMapped6() {
	auto lattice = Lattice(2,3);
	auto mcs = MCS(6);
	auto pnt = makeSix!32();

	mappingPlot2("Results/LatticeMCS6", pnt, lattice, mcs);
}

void latticeMCSMappedCrossing6() {
	auto pnt = makeSix!32();

	auto lattice = Lattice(2,3);
	auto mcs = MCS(6);
	auto crossing = Crossing(pnt);

	mappingPlot2("Results/LatticeMCSCrossing6", pnt, lattice, mcs, crossing);
}

void latticeMCSMapped9() {
	auto pnt = makeNine!32();

	auto lattice = Lattice(3,3);
	auto mcs = MCS(9);

	mappingPlot2("Results/LatticeMCS9", pnt, lattice, mcs);
}

void latticeMCSMappedCrossing9() {
	auto pnt = makeNine!32();

	auto lattice = Lattice(3,3);
	auto mcs = MCS(9);
	auto crossing = Crossing(pnt);

	mappingPlot2("Results/LatticeMCSCrossing9", pnt, lattice, mcs, crossing);
}

void mcsMapped() {
	auto mcs = MCS(6);
	auto mcsRslt = mcs.calcAC();
	auto pnt = makeSix!16();

	auto map = Mappings!(32,16)(mcs.graph, pnt, 1.0, 0.5);
	auto mapRslt = map.calcAC(mcs.read, mcs.write);

	mappingPlot("Results/MCS6_Mapped", map,
			ResultPlot(mcs.name(), mcsRslt),
			ResultPlot(map.name(mcs.name()), mapRslt)
	);
}

void gridMapped() {
	auto grid = Grid(2,3);
	auto gridRslt = grid.calcAC();
	auto pnt = makeSix!16();

	auto map = Mappings!(32,16)(grid.graph, pnt, 1.0, 0.5);
	auto mapRslt = map.calcAC(grid.read, grid.write);

	mappingPlot("Results/Grid2x3_Mapped", map,
			ResultPlot(grid.name(), gridRslt),
			ResultPlot(map.name(grid.name()), mapRslt)
	);
}

void latticeMapped9quantil() {
	auto pnt = makeNine!32();

	//const quantils = [1.0, 0.7, 0.5, 0.2, 0.1, 0.01];
	//const quantils = [0.1, 0.2, 0.5, 1.0];
	const quantils = [0.1];
	long[quantils.length] td;

	foreach(idx, f; quantils) {
		StopWatch sw;
		sw.start();
		auto rp = resultProtocol(
			Lattice(3,3), 
			MappingParameter(f, 0.5),
			pnt
		);
		sw.stop();
		td[idx] = sw.peek().msecs;
	}

	writefln("\n%(%5d\n %)", td);
}

void main() {
	//lattice(4,4);
	//gridAgainstGrid(4,4);
	//MCSAgainstMCS(15);
	//latticeMapped();
	//latticeMapped2();
	//latticeMCSMapped6();
	//latticeMCSMapped9();
	//latticeMCSMappedCrossing6();
	//latticeMCSMappedCrossing9();
	//latticeMapped2();
	//mcsMapped();
	//gridMapped();
	//crossings9();
	latticeMapped9quantil();
}

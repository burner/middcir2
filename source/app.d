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
import stats;

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
	
	auto map = Mappings!(32,32)(lattice.graph, pnt, QTF(1.0), ROW(0.5));
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

	auto map = Mappings!(32,16)(lattice.graph, pnt, QTF(1.0), ROW(0.5));
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

	mappingPlot2("Results/LatticeMCSCrossing6_2", pnt, lattice, mcs, crossing);
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

void latticeMCSMappedCrossing12() {
	auto pnt = genTestGraph12!32();

	auto lattice = Lattice(4,3);
	auto mcs = MCS(12);
	auto crossings = Crossings(pnt);

	mappingPlot2("Results/LatticeMCSCrossing12", pnt, lattice, mcs, crossings);
}

void mcsMapped() {
	auto mcs = MCS(6);
	auto mcsRslt = mcs.calcAC();
	auto pnt = makeSix!16();

	auto map = Mappings!(32,16)(mcs.graph, pnt, QTF(1.0), ROW(0.5));
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

	auto map = Mappings!(32,16)(grid.graph, pnt, QTF(1.0), ROW(0.5));
	auto mapRslt = map.calcAC(grid.read, grid.write);

	mappingPlot("Results/Grid2x3_Mapped", map,
			ResultPlot(grid.name(), gridRslt),
			ResultPlot(map.name(grid.name()), mapRslt)
	);
}

void crossing12() {
	auto pnt = genTestGraph12!32();

	auto crs = Crossings(pnt);
	auto crsRslt = crs.calcAC();
	gnuPlot("Results/Crossing12", "", ResultPlot(crs.name, crsRslt));
	writefln(
		"\nt [%(%s, %)], b [%(%s, %)], l [%(%s, %)], r [%(%s, %)], d [%(%s, %)]\n",
		crs.bestCrossing.top[],
		crs.bestCrossing.bottom[],
		crs.bestCrossing.left[],
		crs.bestCrossing.right[],
		crs.bestCrossing.diagonalPairs[]
	);
	writefln("\n%(%s\n %)", crs.bestCrossing.read[]);
}

void crossingSixteen() {
	auto pnt = genTestGraph!32();

	auto crs = Crossings(pnt);
	auto crsRslt = crs.calcAC();
	gnuPlot("Results/Crossing16", "", ResultPlot(crs.name, crsRslt));
}

void crossingMCSSixteen() {
	auto pnt = genTestGraph!32();

	auto crs = Crossings(pnt);
	auto crsRslt = crs.calcAC();
	auto mcs = MCS(16);
	auto mcsRslt = mcs.calcAC();
	gnuPlot("Results/CrossingMCS16", "",
			ResultPlot(crs.name(), crsRslt),
			ResultPlot(mcs.name(), mcsRslt)
	);
}

void latticeMapped9quantil() {
	import plot.resultplot;
	import std.typecons : Unique;

	auto pnt = makeSix!32();

	const quantils = [0.01, 0.1, 0.2, 0.5, 0.7, 0.9, 1.0];
	long[quantils.length] td;

	Unique!(ResultProtocol!(Lattice))[quantils.length] rps;

	foreach(idx, qtf; quantils) {
		StopWatch sw;
		sw.start();

		rps[idx] = resultProtocolUnique(
				Lattice(3,2), 
				MappingParameter(ROW(0.5), QTF(qtf)),
				pnt
			);

		td[idx] = sw.peek().msecs;
	}
	resultNTPlot("Results/LatticeQuantil", expand!rps);

	writefln("\n%(%5d\n%)", td);
}

void genRandomGraphs() {
	import std.random : Random;
	import graphgen;

	Array!(Graph!16) graphs;

	auto rnd = Random(1337);

	GraphGenConfig ggc;
	ggc.numNodes = 9;
	ggc.minEdges = 1;
	ggc.maxEdges = 3;

	log("Here");
	auto gg = graphGenerator!16(16, 1024, ggc, rnd);
	while(!gg.empty) {
		writeln(gg.front.toString());
		graphs.insertBack(gg.front);
		gg.popFront(graphs);
	}

	graphsToJSON("129graphs.json", graphs);
}

void addGraphsToFile(int Size)(const string filename, long numGraphsToAdd) {
	import std.random : Random;
	import std.file : exists;
	import graphgen;

	Array!(Graph!Size) graphs;
	if(exists(filename)) {
		graphs = loadGraphsFromJSON!Size(filename);
	}

	auto rnd = Random();

	GraphGenConfig ggc;
	ggc.numNodes = 9;
	ggc.minEdges = 1;
	ggc.maxEdges = 5;
	auto gg = graphGenerator!16(numGraphsToAdd, numGraphsToAdd * 3, ggc, rnd);

	while(!gg.empty) {
		writefln("%4d\n%s", gg.maxTries, gg.front.toString());
		graphs.insertBack(gg.front);
		gg.popFront(graphs);
	}

	logf("Generated %d new graphs. File now contains %d graphs", gg.cnt,
			graphs.length);

	graphsToJSON(filename, graphs);
}

void addGraphsToFile() {
	addGraphsToFile!16("9nodegraphs.json", 256);
}

/*void runAllMappings(const(string) graphFile) {
	Array!(Graph!Size) graphs;
	if(exists(graphFile)) {
		graphs = loadGraphsFromJSON!Size(graphFile);
	}

	foreach(ref it; graphs[]) {
		if(it.mappingFileName.empty) {


		}
		if(it.crossingFileName.empty) {

		}
	}
}*/

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
	//latticeMCSMappedCrossing12();
	//crossing12();
	//latticeMapped2();
	//mcsMapped();
	//gridMapped();
	//crossings9();
	//crossingSixteen();
	//crossingMCSSixteen();
	//latticeMapped9quantil();
	//genRandomGraphs();
	//addGraphsToFile();
	runMappings("9nodegraphs.json");
}

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
import learning;
import plot;
import planar;
import plot.gnuplot;
import plot.mappingplot;
import utils;
import graph;
import mapping;
import stats;
import statsanalysis;
import config;

//version(release) {
	//version = exceptionhandling_release_asserts;
//}

void MCSForm() {
	const NN = 7;
	MCSFormula[NN] formula;
	Result[NN] rslt;
	ResultPlot[NN] rsltPlot;

	int[NN] nns = [3,5,8,9,16,33,63];

	for(int i = 0; i < nns.length; ++i) {
		formula[i] = MCSFormula(nns[i]);
		logf("a %d", i);
		rslt[i] = formula[i].calcAC();
		logf("b %d", i);
		rsltPlot[i] = ResultPlot(formula[i].name(), rslt[i]);
		logf("c %d", i);
	}
	gnuPlot("Result/MCS_Many", "", 
			rsltPlot[0],
			rsltPlot[1],
			rsltPlot[2],
			rsltPlot[3],
			rsltPlot[4],
			rsltPlot[5],
			rsltPlot[6]);
}

void crossingVCrossing() {
	for(int i = 4; i < 5; ++i) {
		logf("%d x %d", i, i);
		auto tl = LatticeImpl!64(i, i);
		auto tlRslt = tl.calcAC();
		auto rsltTL = ResultPlot(tl.name(), tlRslt);

		auto crossings1 = CrossingsImpl!64(tl.getGraph(), 
			CrossingsConfig(0, 10)
		);
		auto crossingsRslt1 = crossings1.calcAC();
		auto crossingsTL1 = ResultPlot(format("Crossing90%dx%d", i, i), crossingsRslt1);

		//auto crossings = CrossingsImpl!64(tl.getGraph());
		//auto crossingsRslt = crossings.calcAC();
		//auto crossingsTL = ResultPlot(format("Crossing%dx%d", i, i), crossingsRslt);
		gnuPlot(format("Results/CrossingCrossing%d", i), "", crossingsTL1, rsltTL);
		logf("\nT %(%d, %)\nB %(%d, %)\nL %(%d, %)\nR %(%d, %)",
			crossings1.bestCrossing.top[],
			crossings1.bestCrossing.bottom[],
			crossings1.bestCrossing.left[],
			crossings1.bestCrossing.right[]);
	}
}

void crossingVLattice() {
	for(int i = 4; i < 5; ++i) {
		logf("%d x %d", i, i);
		auto tl = LatticeImpl!64(i, i);
		auto tlRslt = tl.calcAC();
		auto rsltTL = ResultPlot(tl.name(), tlRslt);

		auto crossings = CrossingsImpl!64(tl.getGraph());
		auto crossingsRslt = crossings.calcAC();
		auto crossingsTL = ResultPlot(format("Crossing%dx%d", i, i), crossingsRslt);
		gnuPlot(format("Results/LatticeCrossing%d", i), "", rsltTL,
				crossingsTL);
	}
}

void LatticeXX() {
	import std.typecons : Tuple, tuple;
	const NN = 3;
	Lattice[NN] formula;
	Result[NN] rslt;
	ResultPlot[NN] rsltPlot;

	Tuple!(int,int)[NN] nns = [tuple(2,2),tuple(3,3),tuple(4,4)];

	for(int i = 0; i < nns.length; ++i) {
		formula[i] = Lattice(nns[i][0],nns[i][1]);
		logf("a %d", i);
		rslt[i] = formula[i].calcAC();
		logf("b %d", i);
		rsltPlot[i] = ResultPlot(formula[i].name(), rslt[i]);
		logf("c %d", i);
	}
	gnuPlot("Results/Lattice_XtimesX", "", 
			rsltPlot[0],
			rsltPlot[1],
			rsltPlot[2]
	);
}

void LatticeXY() {
	import std.typecons : Tuple, tuple;
	const NN = 3;
	Lattice[NN] formula;
	Result[NN] rslt;
	ResultPlot[NN] rsltPlot;

	Tuple!(int,int)[NN] nns = [tuple(8,1),tuple(2,2),tuple(4,2)];

	for(int i = 0; i < nns.length; ++i) {
		formula[i] = Lattice(nns[i][0],nns[i][1]);
		logf("a %d", i);
		rslt[i] = formula[i].calcAC();
		logf("b %d", i);
		rsltPlot[i] = ResultPlot(formula[i].name(), rslt[i]);
		logf("c %d", i);
	}
	gnuPlot("Results/Lattice_XtimesY", "", 
			rsltPlot[0],
			rsltPlot[1],
			rsltPlot[2]
	);
}


void GridFormXY() {
	import std.typecons : Tuple, tuple;
	const NN = 3;
	GridFormula[NN] formula;
	Result[NN] rslt;
	ResultPlot[NN] rsltPlot;

	Tuple!(int,int)[NN] nns = [tuple(8,1),tuple(2,2),tuple(4,2)];

	for(int i = 0; i < nns.length; ++i) {
		formula[i] = GridFormula(nns[i][0],nns[i][1]);
		logf("a %d", i);
		rslt[i] = formula[i].calcAC();
		logf("b %d", i);
		rsltPlot[i] = ResultPlot(formula[i].name(), rslt[i]);
		logf("c %d", i);
	}
	gnuPlot("Results/Grid_XtimesY", "", 
			rsltPlot[0],
			rsltPlot[1],
			rsltPlot[2]
	);
}


void GridForm() {
	const NN = 7;
	GridFormula[NN] formula;
	Result[NN] rslt;
	ResultPlot[NN] rsltPlot;

	int[NN] nns = [2,3,4,5,6,7,8];

	for(int i = 0; i < nns.length; ++i) {
		formula[i] = GridFormula(nns[i],nns[i]);
		logf("a %d", i);
		rslt[i] = formula[i].calcAC();
		logf("b %d", i);
		rsltPlot[i] = ResultPlot(formula[i].name(), rslt[i]);
		logf("c %d", i);
	}
	gnuPlot("Results/Grid_XtimesX", "", 
			rsltPlot[0],
			rsltPlot[1],
			rsltPlot[2],
			rsltPlot[3],
			rsltPlot[4],
			rsltPlot[5],
			rsltPlot[6]);
}


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

void gridVLattice(int nc, int nr) {
	logf("grid");
	auto grid = GridFormula(nc, nr);
	auto gridRslt = grid.calcAC();
	auto rsltGrid = ResultPlot(grid.name(), gridRslt);

	logf("mcs");
	auto mcs = MCSFormula(nc * nr);
	auto mcsRslt = mcs.calcAC();
	auto rsltMCS = ResultPlot(format("MCS-%d", nc * nr) , mcsRslt);

	logf("lattice");
	auto tl = LatticeImpl!64(nc, nr);
	auto tlRslt = tl.calcAC();
	auto rsltTL = ResultPlot(tl.name(), tlRslt);
	//closedQuorumListWriter!ulong(tl.write);

	gnuPlot(format("Results/GridVLattice%sX%s", nr, nc), "", rsltGrid,
			rsltMCS, rsltTL);
}

void lattice(int nc, int nr) {
	logf("lattice %d x %d from %d to %d", nc, nr,
		getConfig().permutationStart, getConfig().permutationStop);
	auto tl = LatticeImpl!64(nc, nr);
	auto tlRslt = tl.calcAC();
	auto rsltTL = ResultPlot(tl.name(), tlRslt);

	/*closedQuorumListWriter(tl.read, 
		format("./CQL/Lattice_%02d_%02d/read_%02d_%02d.json", nc, nr, 
			getConfig().permutationStart(), getConfig().permutationStop()));

	closedQuorumListWriter(tl.write, 
		format("./CQL/Lattice_%02d_%02d/write_%02d_%02d.json", nc, nr, 
			getConfig().permutationStart(), getConfig().permutationStop()));
	*/

	//gnuPlot(format("Results/Lattice%sX%s", nr, nc), "", rsltTL);
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

	auto rnd = Random(25378);

	GraphGenConfig ggc;
	ggc.numNodes = 12;
	ggc.minEdges = 1;
	ggc.maxEdges = 11;

	log("Here");
	auto gg = graphGenerator!16(64, 64, ggc, rnd);
	int id;
	while(!gg.empty) {
		auto f = gg.front;
		f.id = id++;
		writeln(gg.maxTries, "\n", f.toString());
		graphs.insertBack(f);
		gg.popFront(graphs);
	}

	graphsToJSON("graphs12nodes3.json", graphs);
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
	ggc.numNodes = 8;
	ggc.minEdges = 1;
	ggc.maxEdges = 6;
	auto gg = graphGenerator!16(numGraphsToAdd, numGraphsToAdd * 3, ggc, rnd);

	while(!gg.empty) {
		writefln("%4d\n%s", gg.maxTries, gg.front.toString());
		graphs.insertBack(gg.front);
		gg.popFront(graphs);
	}

	logf("Generated %d new graphs. File now contains %d graphs tries left", gg.cnt,
			graphs.length, gg.maxTries);

	long id = 0;
	foreach(ref it; graphs) {
		if(it.id != long.min && it.id != id) {
			throw new Exception("ID mismatch");
		}
		it.id = id++;
	}

	graphsToJSON(filename, graphs);
}

void addGraphsToFile() {
	addGraphsToFile!16("graph8nodes.json", 64);
}

void runMappings(string graphsFilename, string[] args) {
	import std.getopt;
	int start = 0;
	int upto = 0;
	StatsType stype = StatsType.all;

	getopt(args, "start", &start, "upto", &upto, "statstype", &stype);
	
	auto runner = new StatsRunner!16(graphsFilename, start, upto, stype);
	runner.runMappings();
	/*try {
		runner.runMappingsThreaded();
	} catch(Exception e) {
		logf("%s", e.toString());
	}*/
}

void buildSublist(string folderName) {
	import sublistjoiner;

	auto slj = SubListJoinerImpl!64(folderName);
	auto sljRslt = slj.calcAC();
	gnuPlot("Results/LatticeJoin", "", ResultPlot("SLJ", sljRslt));
}

void main(string[] args) {
	//parseConfig(args);
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
	//runMappings("6nodegraphs.json", args);
	//runMappings("graphs8nodes.json", args);
	//runMappings("9nodegraphs.json", args);
	//MCSForm();
	//GridFormXY();
	//gridVLattice(3,3);
	//gridVLattice(4,2);
	//gridVLattice(2,4);
	//crossingVLattice();
	//crossingVCrossing();
	//gridVLattice(6,6);
	//lattice(6,6);
	//LatticeXX();
	//LatticeXY();
	//buildSublist("CQL/Lattice_03_03");
	//statsAna!16("graphs7nodes.json");
	//statsAna!32("6nodegraphs.json");
	//statsAna!32("9nodegraphs.json");
	doLearning!32("6nodegraphs.json");
	//doLearning!32("graphs9nodes2.json");
}

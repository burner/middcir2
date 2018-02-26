module app;

static import std.array;
import std.stdio;
import std.container.array;
import std.range : lockstep;
import std.format : format;
import std.algorithm : permutations, Permutations;
import std.experimental.logger;
import std.datetime.stopwatch : StopWatch;
import std.array : empty;

import protocols;
import protocols.mcs;
import protocols.grid;
import protocols.lattice;
import protocols.crossing;
import protocols.circle;
//import learning;
import learning2;
import plot;
import planar;
import plot.gnuplot;
import plot.mappingplot;
import utils;
import graph;
import mapping;
import stats;
import statsanalysis;
import sortingbystats;
import boxplotmapping;
import config;

class ShortLogger : Logger {
	import std.stdio : writefln;
    this(LogLevel lv) @safe {
        super(lv);
    }

    override void writeLogMsg(ref LogEntry payload) {
		import std.string : lastIndexOf;
		import std.datetime : DateTime;
		auto i = payload.file.lastIndexOf("/");
		string f = payload.file;
		if(i != -1) {
			f = f[i+1 .. $];
		}

    	const auto dt = cast(DateTime)payload.timestamp;
    	const auto fsec = payload.timestamp.fracSecs.total!"msecs";

    	writefln("%04d-%02d-%02dT%02d:%02d:%02d.%03d %s:%s %s",
    	    dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second,
    	    fsec, f, payload.line, payload.msg);
    }
}

//version(release) {
	//version = exceptionhandling_release_asserts;
//}

void fiveMapping() {
	auto mcs = MCS(5);
	Result mcsR = mcs.calcAC();
	logf("mcs\n%s", mcs.read);

	auto pnt = makeFive!32();
	auto f = File("5pnt.tex", "w");
	f.write(pnt.toTikz());

	auto mapping = new Mapping!(32,32)(mcs.getGraph(), pnt, [4,3,2,1,0]);
	Result mapR = mapping.calcAC(mcs.read, mcs.write);

	logf("map\n%s", mapping.read);
}

void MCSForm() {
	const NN = 1;
	MCSFormula[NN] formula;
	Result[NN] rslt;
	ResultPlot[NN] rsltPlot;

	//int[NN] nns = [3,5,8,9,16,33,63];
	int[NN] nns = [5];

	for(int i = 0; i < nns.length; ++i) {
		formula[i] = MCSFormula(nns[i]);
		logf("a %d", i);
		rslt[i] = formula[i].calcAC();
		logf("b %d", i);
		rsltPlot[i] = ResultPlot(formula[i].name(), rslt[i]);
		logf("c %d", i);
	}
	gnuPlot("Result/MCS_Many", "", 
			rsltPlot[0]);
			//rsltPlot[1],
			//rsltPlot[2],
			//rsltPlot[3],
			//rsltPlot[4],
			//rsltPlot[5],
			//rsltPlot[6]);
}

void crossingVCrossing() {
	for(int i = 4; i < 5; ++i) {
		logf("%d x %d", i, i);
		auto tl = LatticeImpl!32(i, i);
		auto tlRslt = tl.calcAC();
		auto rsltTL = ResultPlot(tl.name(), tlRslt);

		auto crossings1 = CrossingsImpl!32(tl.getGraph(), 
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

void latticeBoxplot() {
	foreach(it; [[3,3], [2,4], [4,2]]) {
		auto l = Lattice(it[0],it[1]);
		auto r = l.calcAC();
		auto rp = ResultPlot(format("Lattice%dx%d", it[0], it[1]), r);
		gnuPlot(format("Results/Lattice%dx%d", it[0], it[1]), "", rp);
	}
}

void mcsBoxplot() {
	foreach(it; [8, 9]) {
		auto l = MCS(it);
		auto r = l.calcAC();
		auto rp = ResultPlot(format("MCS%d", it), r);
		gnuPlot(format("Results/MCS%d", it), "", rp);
	}
}

void gridBoxplot() {
	foreach(it; [[3,3], [2,4], [4,2]]) {
		auto l = Grid(it[0],it[1]);
		auto r = l.calcAC();
		auto rp = ResultPlot(format("Grid%dx%d", it[0], it[1]), r);
		gnuPlot(format("Results/Grid%dx%d", it[0], it[1]), "", rp);
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
	// import std.datetime : StopWatch, to;
	//import std.datetime : to;
	const NN = 4;
	LatticeImpl!(32)[NN] formula;
	Result[NN] rslt;
	ResultPlot[NN] rsltPlot;

	//Tuple!(int,int)[NN] nns = [tuple(8,1),tuple(2,2),tuple(4,2),tuple(5,5)];
	Tuple!(int,int)[NN] nns = [tuple(4,3), tuple(3,4), tuple(4,4), tuple(4,5)];

	auto sw = StopWatch();
	sw.start();
	for(int i = 0; i < nns.length; ++i) {
		formula[i] = LatticeImpl!(32)(nns[i][0],nns[i][1]);
		logf("a %d", i);
		rslt[i] = formula[i].calcAC();
		logf("b %d", i);
		rsltPlot[i] = ResultPlot(formula[i].name(), rslt[i]);
		logf("c %d", i);
	}
	logf("%s mssecs", sw.peek.total!("msecs")());
	gnuPlot("Results/Lattice_XtimesY", "", 
			rsltPlot[0],
			rsltPlot[1],
			rsltPlot[2],
			rsltPlot[3],
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

	//logf("mcs");
	//auto mcs = MCSFormula(nc * nr);
	//auto mcsRslt = mcs.calcAC();
	//auto rsltMCS = ResultPlot(format("MCS-%d", nc * nr) , mcsRslt);

	logf("lattice");
	//auto tl = LatticeImpl!64(nc, nr);
	auto tl = LatticeImpl!64(nc, nr);
	auto tlRslt = tl.calcAC();
	auto rsltTL = ResultPlot(tl.name(), tlRslt);
	//closedQuorumListWriter!ulong(tl.write);

	logf("gnuplot");

	gnuPlot(format("Results/GridVLattice%sX%s", nr, nc), "", rsltGrid,
			/*rsltMCS,*/ rsltTL);
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
	auto lattice = LatticeImpl!32(3,3);
	auto latticeRslt = lattice.calcAC();
	auto pnt = makeSix!32();

	auto map = Mappings!(32,32)(lattice.graph, pnt, QTF(1.0), ROW(0.5));
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

void mcsCrossing16() {
	auto pnt = genTestGraph!32();
	//auto pnt = makeFive!32();
	auto mcs = MCS(16);
	auto cro = Crossings(pnt);
	mappingPlot2("Results/MCSCrossing16", pnt, mcs, cro);
}

void mcsMapped() {
	auto mcs = MCS(5);
	//auto mcsRslt = mcs.calcAC();
	auto pnt = makeFive!32();

	//auto map = Mappings!(32,16)(mcs.graph, pnt, QTF(1.0), ROW(0.5));
	//auto mapRslt = map.calcAC(mcs.read, mcs.write);

	mappingPlot2("Results/MCS5_Mapped",	pnt, mcs);
}

void printProperties() {
	import graphmeasures;
	auto g = makeFive!16();
	auto d = computeDegree(g);
	writefln("Degree:");
	writefln("\tMin & %s", d.min);
	writefln("\tAvg & %s", d.average);
	writefln("\tMedian & %s", d.median);
	writefln("\tMode & %s", d.mode);
	writefln("\tMax & %s\n", d.max);

	auto dia = computeDiameter(g);
	writefln("Diameter:");
	writefln("\tMin & %s", dia.min);
	writefln("\tAvg & %s", dia.average);
	writefln("\tMedian & %s", dia.median);
	writefln("\tMode & %s", dia.mode);
	writefln("\tMax & %s\n", dia.max);

	auto bc = betweennessCentrality(g);
	writefln("Betweenness Centrality:");
	writefln("\tMin & %s", bc.min);
	writefln("\tAvg & %s", bc.average);
	writefln("\tMedian & %s", bc.median);
	writefln("\tMode & %s", bc.mode);
	writefln("\tMax & %s\n", bc.max);

	auto c = computeConnectivity(g);
	writefln("Connectivity: %s", c);
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

void circle() {
	//auto pnt = genTestGraph12!32();
	auto pnt = genTestGraph!32();

	auto crs = Circles(pnt);
	auto crsRslt = crs.calcAC();
	gnuPlot("Results/Circle_12", "", ResultPlot("Circle", crsRslt));

	auto f = File("Results/Circle_12/graph.tex", "w");
	auto ltw = f.lockingTextWriter();
	pnt.toTikz(ltw);
}

void manyCirclesRun() {
	manyCircles("graphs6nodes3.json", "Results/graph6nodes3");
	//manyCircles("graphs8nodes3.json", "Results/graph8nodes3");
	//manyCircles("graphs9nodes3.json", "Results/graph9nodes3");
	//manyCircles("graphs12nodes3.json", "Results/graph12nodes3");
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

		td[idx] = sw.peek().total!"msecs"();
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

void checkGraphUnique(string filename) {
	import graphgen;
	import graphisomorph;
	import graphisomorph2;
	import floydmodule;
	logf("filename %s", filename);
	auto f = File(filename ~ "_graphs.tex", "w");
	f.write(
`\documentclass[tikz]{standalone}
\usepackage{tikz}
\usepackage{pgfplots}
\usetikzlibrary{decorations.markings, arrows, decorations.pathmorphing,
   backgrounds, positioning, fit, shapes.geometric}
\IfFileExists{../config.tex}%
	{\input{../config}}%
	{
	\tikzstyle{place} = [shape=circle,
    draw, align=center,minimum width=0.70cm,
    top color=white, bottom color=blue!20]
	}
\begin{document}
`);
	auto graphs = loadGraphsFromJSON!(16)(filename);
	for(size_t i = 0; i < graphs.length; ++i) {
		logf("Graph %d", i);
		FloydImpl!16 floyd;
		floyd.reserveArrays(graphs[i].numNodes);
		floyd.execute(graphs[i]);
		for(int ii = 0; ii < graphs[i].numNodes; ++ii) {
			for(int jj = ii + 1; jj < graphs[i].numNodes; ++jj) {
				if(!floyd.pathExists(ii, jj)) {
					logf("Graph %d is not connected", i);
				}
			}
		}
		for(size_t j = i + 1; j < graphs.length; ++j) {
			if(areGraphsIsomorph(graphs[i], graphs[j])) {
				logf("Graphs %d and %d are isomorph");
			}
			if(areGraphsIso2(graphs[i], graphs[j])) {
				logf("Graphs %d and %d are isomorph test 3");
			}
			if(areHomomorph(graphs[i], graphs[j])) {
				logf("Graphs %d and %d are homomorph");
			}
			if(graphs[i].isHomomorph(graphs[j])) {
				logf("Graphs %d and %d are homomorph test 2");
			}
		}
		f.write(graphs[i].toTikzShort());
	}
	f.write("\\end{document}");
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
	//import std.getopt;
	//int start = 0;
	//int upto = 0;
	//StatsType stype = StatsType.all;

	//getopt(args, "start", &start, "upto", &upto, "statstype", &stype);
	
	logf("%s %s %s", 
			getConfig().start, getConfig().upto, getConfig().statstype
		);
	auto runner = new StatsRunner!16(graphsFilename, 
			getConfig().start, getConfig().upto, getConfig().statstype
		);
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
	sharedLog = new ShortLogger(LogLevel.all);
	parseConfig(args);

	if(getConfig().testSupsetFast) {
		import testfastsupset;
		testFastSupset();
		return;
	}

	//circle();
	manyCirclesRun();
	//boxplot();
	//checkGraphUnique("graphs6nodes3.json");
	//checkGraphUnique("graphs8nodes3.json");
	//checkGraphUnique("graphs9nodes3.json");
	//fiveMapping();
	//lattice(4,4);
	//gridAgainstGrid(4,4);
	//MCSAgainstMCS(15);
	//latticeMapped();
	//latticeMCSMapped6();
	//latticeMCSMapped9();
	//latticeMCSMappedCrossing6();
	//latticeMCSMappedCrossing9();
	//latticeMCSMappedCrossing12();
	//crossing12();
	//latticeMapped2();
	//MCSForm();
	//mcsMapped();
	//printProperties();
	//gridMapped();
	//crossings9();
	//crossingSixteen();
	//crossingMCSSixteen();
	//mcsCrossing16();
	//latticeMapped9quantil();
	//genRandomGraphs();
	//addGraphsToFile();
	//runMappings("6nodegraphs.json", args);
	//runMappings("graphs8nodes.json", args);
	//runMappings("9nodegraphs.json", args);
	//MCSForm();
	//GridFormXY();
	//gridVLattice(4,7);
	//gridVLattice(4,4);
	//gridVLattice(5,5);
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
	//doLearning!32("6nodegraphs.json");
	if(!getConfig().learning2filename.empty) {
		logf("%s %s", getConfig().learning2filename,
				getConfig().learning2k
			);
		doLearning2!32(getConfig().learning2filename, 
				getConfig().learning2k
			);
	}

	if(!getConfig().sortBy.filename.empty) {
		logf("sort by filename %s", getConfig().sortBy.filename);
		sortMappedQP!32(getConfig().sortBy.filename);
	}
	//doLearning2!32("graphs8nodes3.json");
	//doLearning2!32("graphs9nodes3.json");
	//doLearning2!32("graphs9nodes2.json");
	logf("done");
}

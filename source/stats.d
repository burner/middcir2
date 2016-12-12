module stats;

import std.experimental.logger;

import utils;
import mapping;
import graph;
import graphgen;
import protocols;
import protocols.mcs;
import protocols.grid;
import protocols.lattice;
import protocols.crossing;

void runMappings(string graphsFilename) {
	import std.file : exists;
	import graphgen;

	enum Size = 32;
	Array!(Graph!Size) graphs;
	if(exists(graphsFilename)) {
		graphs = loadGraphsFromJSON!Size(graphsFilename);
	}
	assert(!graphs.empty);

	const(long) size = graphs.front.length;
	Lattice[] lattices;
	Grid[] grids;
	buildGraphBased(lattices, grids, size);
	auto mcs = MCS(cast(int)size);

	Result[] latticeResults;	
	Result[] gridResults;	
	Result mcsResult;	

	logf("%s", latticeResults.length);
	runNormal(lattices, latticeResults, grids, gridResults, mcs, mcsResult);
	logf("%s", latticeResults.length);

	foreach(g; graphs) {
		runMapping(g);
	}
}

void runNormal(ref Lattice[] lattices, ref Result[] latticeResults, 
		ref Grid[] grids, ref Result[] gridResults,
		ref MCS mcs, ref Result mcsResult) 
{
	foreach(ref it; lattices) {
		latticeResults ~= it.calcAC();
	}

	foreach(ref it; grids) {
		gridResults ~= it.calcAC();
	}

	mcsResult = mcs.calcAC();
}

void buildGraphBased(ref Lattice[] lattices, ref Grid[] grids,
	   	const(ulong) size) 
{
	auto dimensions = bestGridDiffs(size);

	foreach(rc; dimensions) {
		lattices ~= Lattice(rc[0], rc[1]);
		grids ~= Grid(rc[0], rc[1]);
	}
}

void runMapping(int Size)(auto ref Graph!Size g, Lattice[] lattices,
	   	Grid[] grids, MCS mcs)
{
	auto row = [ROW(0.01), ROW(0.1), ROW(0.25), ROW(0.5), ROW(0.75),
			ROW(0.9), ROW(0.99)
		];
	auto rowc = [ROWC(0.01), ROWC(0.1), ROWC(0.25), ROWC(0.5), ROWC(0.75),
			ROWC(0.9), ROWC(0.99)
		];
}

void runMapping(int Size)(auto ref Graph!Size g, Lattice[] lattices) {

}

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

class StatsRunner(int Size) {
	import std.file : exists, rmdir, mkdir, isDir;
	import graphgen;
	import std.format : format;

	const(string) graphsFilename;
	const(string) graphsResultFolderName;
	Array!(Graph!Size) graphs;

	Lattice[] lattices;
	Grid[] grids;
	MCS mcs;

	Result[] latticeResults;
	Result[] gridResults;	
	Result mcsResult;	

	ROW[] row;
	ROWC[] rowc;

	this(string graphsFilename) {
		this.graphsFilename = graphsFilename;
		this.graphsResultFolderName = this.graphsFilename ~ "_Results";
		if(exists(graphsFilename)) {
			this.graphs = loadGraphsFromJSON!Size(this.graphsFilename);
		}
		assert(!graphs.empty);
	
		const(long) size = graphs.front.length;
		buildGraphBased(size);
		this.mcs = MCS(cast(int)size);

		this.row = [ROW(0.01), ROW(0.1), ROW(0.25), ROW(0.5), ROW(0.75),
			ROW(0.9), ROW(0.99)
		];
		this.rowc = [ROWC(0.01), ROWC(0.1), ROWC(0.25), ROWC(0.5), ROWC(0.75),
			ROWC(0.9), ROWC(0.99)
		];
	}

	void runMappings() {
		this.createResultFolder();
		this.runNormal();

		int cnt;
		foreach(g; this.graphs) {
			logf("%3d of %3d", cnt++, this.graphs.length);
			this.runMapping(g);
		}
	}
	
	void runNormal() {
		foreach(ref it; this.lattices) {
			this.latticeResults ~= it.calcAC();
		}
	
		foreach(ref it; this.grids) {
			this.gridResults ~= it.calcAC();
		}
	
		this.mcsResult = this.mcs.calcAC();
	}
	
	void buildGraphBased(const(ulong) size) {
		auto dimensions = bestGridDiffs(size);
	
		foreach(rc; dimensions) {
			this.lattices ~= Lattice(rc[0], rc[1]);
			this.grids ~= Grid(rc[0], rc[1]);
		}
	}
	
	void runMapping(int Size)(auto ref Graph!Size g) {
		import core.memory : GC;
		GC.collect();
		GC.minimize();

		auto path = format("%s/%05d", this.graphsResultFolderName, g.id);
		if(exists(path)) {
			logf("Data for graph %s existed, therefore we skip it", path);
			return;
		} else {
			mkdir(path);
		}

		foreach(it; this.lattices) {
			auto map = Mappings!(Size,Size)(it.graph, g, row, rowc);
			map.calcAC(it.read, it.write);
			this.mappingToDataFile(map, "Lattice", path);
			this.mappingToJson(map, "Lattice", path);
		}

		foreach(it; this.grids) {
			auto map = Mappings!(Size,Size)(it.graph, g, row, rowc);
			map.calcAC(it.read, it.write);
			this.mappingToDataFile(map, "Grid", path);
			this.mappingToJson(map, "Grid", path);
		}

		{
			auto map = Mappings!(Size,Size)(this.mcs.graph, g, row, rowc);
			map.calcAC(this.mcs.read, this.mcs.write, true);
			this.mappingToDataFile(map, "MCS", path);
			this.mappingToJson(map, "MCS", path);
		}
	}

	void mappingToJson(ref Mappings!(Size,Size) map, string type,
		   	string folderPath) 
	{
		import utils : format;
		import std.stdio : File;
		auto pathStr = format("%s/%s.json", folderPath, type);
		auto af = File(pathStr, "w");
		auto app = af.lockingTextWriter();

		format(app, 0, "{\n");
		format(app, 1, "\"row\" : {\n");
		bool first = true;
		foreach(it; this.row) {
			if(!first) {
				format(app, 2, ",");
			} else {
				format(app, 2, " ");
			}
			first = false;
			format(app, 0, "\"%.2f\" : [%(%d, %)]\n", it.value,
					map.results.get(it).mapping.mapping
				);
		}
		format(app, 1, "},\n");
		format(app, 1, "\"rowc\" : {\n");
		first = true;
		foreach(it; this.row) {
			if(!first) {
				format(app, 2, ",");
			} else {
				format(app, 2, " ");
			}
			first = false;
			format(app, 0, "\"%.2f\" : [%(%d, %)]\n", it.value,
					map.results.get(it).mapping.mapping
				);
		}
		format(app, 1, "}\n");
		format(app, 0, "}");
	}

	void mappingToDataFile(ref Mappings!(Size,Size) map, string type, 
			string folderPath)
	{
		foreach(it; this.row) {
			this.mappingToDataFile(map, type, folderPath, it);
		}
		foreach(it; this.rowc) {
			this.mappingToDataFile(map, type, folderPath, it);
		}
	}

	void mappingToDataFile(ref Mappings!(Size,Size) map, string type, 
			string folderPath, ROW row)
	{
		auto pathROWStr = format("%s/%s_row_%.2f_", folderPath, type,
				row.value
			);

		foreach(it; this.row) {
			this.mappingToDataFileImpl(map.results.get(it).result,
					pathROWStr
				);
		}
	}

	void mappingToDataFile(ref Mappings!(Size,Size) map, string type, 
			string folderPath, ROWC rowc)
	{
		auto pathROWStr = format("%s/%s_rowc_%.2f_", folderPath, type,
				rowc.value
			);

		foreach(it; this.rowc) {
			this.mappingToDataFileImpl(map.results.get(it).result,
					pathROWStr
				);
		}
	}

	void mappingToDataFileImpl(ref Result rslt, string fileName) {
		import std.stdio : File;
		import std.format : formattedWrite;

		auto af = File(fileName ~ "avail.data", "w");
		auto ac = File(fileName ~ "costs.data", "w");

		auto afLTW = af.lockingTextWriter();
		auto acLTW = ac.lockingTextWriter();

		for(size_t i = 0; i < 101; ++i) {
			formattedWrite(afLTW, "%.5f ", i/100.0);
			formattedWrite(acLTW, "%.5f ", i/100.0);
			formattedWrite(afLTW, "%.15f ", rslt.readAvail[i]);
			formattedWrite(afLTW, "%.15f ", rslt.writeAvail[i]);

			formattedWrite(acLTW, "%.15f ", rslt.readCosts[i]);
			formattedWrite(acLTW, "%.15f ", rslt.writeCosts[i]);
			formattedWrite(afLTW, "\n");
			formattedWrite(acLTW, "\n");
		}
	}

	bool doesResultFolderExists(string path) {
		return exists(path) && isDir(path);
	}

	void createResultFolder() {
		if(!exists(this.graphsResultFolderName)) {
			mkdir(this.graphsResultFolderName);	
		}
	}
}

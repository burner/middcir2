module stats;

import std.experimental.logger;

import core.thread;

import utils;
import mapping;
import graph;
import graphgen;
import protocols;
import protocols.mcs;
import protocols.grid;
import protocols.lattice;
import protocols.crossing;

import config;

align(8)
class StatsRunner(int Size) {
	import core.memory : GC;
	import std.file : exists, rmdir, mkdir, isDir;
	import std.container.array;
	import graphgen;
	import std.format : format;

	align(8) {
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

	int start;
	int upTo;

	StatsType statsType;
	}

	this(string graphsFilename, int start, int upTo) {
		this(graphsFilename, start, upTo, StatsType.all);
	}

	this(string graphsFilename, int start, int upTo, StatsType statsType) {
		this.graphsFilename = graphsFilename;
		this.statsType = statsType;
		this.graphsResultFolderName = this.graphsFilename ~ "_Results";
		if(exists(graphsFilename)) {
			this.graphs = loadGraphsFromJSON!Size(this.graphsFilename);
		}
		assert(!this.graphs.empty);
		bool[size_t] ids;
		foreach(g; this.graphs[]) {
			if(cast(size_t)(g.id) in ids) {
				throw new Exception(format(
						"id %d already present check file %s",
						g.id, graphsFilename
					));
			}
			ids[cast(size_t)g.id] = true;
		}

		this.start = start;
		this.upTo = upTo == 0 ? cast(int)this.graphs.length : upTo;
	
		const(long) size = this.graphs.front.length;
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

		int cnt = 0;
		foreach(g; this.graphs[this.start .. this.upTo]) {
			logf("%3d of range %3d -- %3d", cnt++, this.start, this.upTo);
			this.runMapping(g);
			GC.collect();
			GC.minimize();
		}
	}

	void runMappingsThreaded() {
		import std.range : chunks;
		this.createResultFolder();
		this.runNormal();

		enum chunkSize = 4;

		int cnt;
		foreach(ch; chunks(this.graphs[], chunkSize)) {
			{
				Thread[chunkSize] threads;
				//logf("%3d of %3d", cnt++, this.graphs.length);
				logf("ch.length(%d)", ch.length);
				for(int i = 0; i < ch.length; ++i) {
					logf("\tid %d", ch[i].id);
					threads[i] = new StatsThread!Size(
							cast(shared(const(StatsRunner!Size)))this,
							ch[i]
						);
					threads[i].start();
				}
				for(int i = 0; i < ch.length; ++i) {
					threads[i].join();
				}
			}
			GC.collect();
			GC.minimize();
		}
	}
	
	void runNormal() {
		if(this.statsType == StatsType.all 
				|| this.statsType == StatsType.Lattice)
		{
			foreach(ref it; this.lattices) {
				logf("Lattice %s %s", it.width, it.height);
				this.latticeResults ~= it.calcAC();
			}
		}
	
		if(this.statsType == StatsType.all 
				|| this.statsType == StatsType.Grid)
		{
			foreach(ref it; this.grids) {
				logf("Grid %s %s", it.width, it.height);
				this.gridResults ~= it.calcAC();
			}
		}
	
		if(this.statsType == StatsType.all 
				|| this.statsType == StatsType.MCS)
		{
			this.mcsResult = this.mcs.calcAC();
		}
	}
	
	void buildGraphBased(const(ulong) size) {
		auto dimensions = bestGridDiffs(size);
		foreach(rc; dimensions) {
			if(this.statsType == StatsType.all 
					|| this.statsType == StatsType.Lattice)
			{
				this.lattices ~= Lattice(cast(size_t)rc[0], cast(size_t)rc[1]);
			}
			if(this.statsType == StatsType.all 
					|| this.statsType == StatsType.Grid)
			{
				this.grids ~= Grid(cast(size_t)rc[0], cast(size_t)rc[1]);
			}
		}
	}
	
	void runMapping(int Size)(const(Graph!Size) g) const {
		auto path = format("%s/%05d", this.graphsResultFolderName, g.id);
		//	logf("Data for graph %s existed, therefore we skip it", path);
		//} else {
		if(!exists(path)) {
			mkdir(path);
		}

		if(this.statsType == StatsType.all 
				|| this.statsType == StatsType.Lattice)
		{
			foreach(it; this.lattices) {
				logf("Lattice");
				{
					auto map = Mappings!(32,Size)(it.graph, g, row, rowc);
					map.calcAC(it.read, it.write);
					this.mappingToDataFile(map, "Lattice", path, it.width,
							it.height);
					this.mappingToJson(map, "Lattice", path, it.width, it.height);
				}
				GC.collect();
				GC.minimize();
			}
		}

		if(this.statsType == StatsType.all 
				|| this.statsType == StatsType.Grid)
		{
			foreach(it; this.grids) {
				logf("Grid");
				{
					auto map = Mappings!(32,Size)(it.graph, g, row, rowc);
					map.calcAC(it.read, it.write);
					this.mappingToDataFile(map, "Grid", path, it.width, it.height);
					this.mappingToJson(map, "Grid", path, it.width, it.height);
				}
				GC.collect();
				GC.minimize();
			}
		}

		if(this.statsType == StatsType.all 
				|| this.statsType == StatsType.MCS)
		{
			logf("MCS");
			auto map = Mappings!(32,Size)(this.mcs.graph, g, row, rowc);
			map.calcAC(this.mcs.read, this.mcs.write, true);
			this.mappingToDataFile(map, "MCS", path, 0, 0);
			this.mappingToJson(map, "MCS", path, 0, 0);
		}
	}

	void mappingToJson(M)(ref const(M) map, string type,
		   	string folderPath, ulong width, ulong height) const
	{
		import utils : format;
		import std.stdio : File;
		auto pathStr = format("%s/%s_%dx%d.json", folderPath, type, width,
				height);
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
			format(app, 0, "\"%.2f\" : [%(%s, %)]\n", it.value,
					map.results.get(it).mapping.mapping[]
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
			format(app, 0, "\"%.2f\" : [%(%s, %)]\n", it.value,
					map.results.get(it).mapping.mapping[]
				);
		}
		format(app, 1, "}\n");
		format(app, 0, "}");
	}

	void mappingToDataFile(M)(ref const(M) map, string type, 
			string folderPath, ulong width, ulong height) const
	{
		foreach(it; this.row) {
			this.mappingToDataFile(map, type, folderPath, it, width, height);
		}
		foreach(it; this.rowc) {
			this.mappingToDataFile(map, type, folderPath, it, width, height);
		}
	}

	void mappingToDataFile(M)(ref const(M) map, string type, 
			string folderPath, ROW row, ulong width, ulong height) const
	{
		auto pathROWStr = format("%s/%s_%dx%d_row_%.2f_", folderPath, type,
				width, height, row.value
			);

		foreach(it; this.row) {
			this.mappingToDataFileImpl(map.results.get(it).result,
					pathROWStr
				);
		}
	}

	void mappingToDataFile(M)(ref const(M) map, string type, 
			string folderPath, ROWC rowc, ulong width, ulong height) const
	{
		auto pathROWStr = format("%s/%s_%dx%d_rowc_%.2f_", folderPath, type,
				width, height, rowc.value
			);

		foreach(it; this.rowc) {
			this.mappingToDataFileImpl(map.results.get(it).result,
					pathROWStr
				);
		}
	}

	void mappingToDataFileImpl(ref const(Result) rslt, string fileName) const {
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

class StatsThread(int Size) : Thread {
	const(StatsRunner!Size) stats;
	const(Graph!Size) graph;

	this(shared(const(StatsRunner!Size)) stats, const(Graph!Size) graph) {
		super(&run);
		this.stats = cast(const(StatsRunner!Size))stats;
		this.graph = cast(const(Graph!Size))graph;
	}

	void run() {
		this.stats.runMapping(graph);
	}
}

module statsanalysis;

import std.container.array;
import std.experimental.logger;
import std.algorithm.sorting : sort;

import graphmeasures;
import graph;
import protocols;

struct GraphStats(int Size) {
	Graph!Size graph;
	DiameterResult diameter;
	Result[7] avails;
	Result[7] costs;

	this(Graph!Size g, string filename) {
		this.graph = g;
		this.loadResults(this.graph.id, filename, "row");
	}

	void loadResults(long id, string filename, string availOrCosts) {
		import std.file : dirEntries, SpanMode;
		import std.format : format;
		import std.algorithm.iteration : filter;
		import std.algorithm.searching : canFind;
		string folderName = format("%s_Results/%05d/", filename, id);
		auto files = dirEntries(folderName, SpanMode.depth)
			.filter!(f =>
				canFind(f.name, "data") && canFind(f.name, availOrCosts)
			);
		foreach(f; files) {
			logf("%s", f.name);
		}
	}
}

Array!(GraphStats!Size) loadGraphs(int Size)(string filename) {
	import stdx.data.json;
	import std.file : readText;

	Array!(GraphStats!Size) ret;

	auto j = toJSONValue(readText(filename));
	foreach(it; j["graphs"].get!(JSONValue[])) {
		ret.insertBack(GraphStats!Size(Graph!Size(it), filename));
	}

	return ret;
}

void statsAna(int Size)(string jsonFileName) {
	auto graphs = loadGraphs!Size(jsonFileName);

	foreach(ref it; graphs) {
		it.diameter = diameter!Size(it.graph);
	}

	sort!"a.diameter.average < b.diameter.average"(graphs[]);
	//logf("%(%s\n\n%)", graphs[]);
}

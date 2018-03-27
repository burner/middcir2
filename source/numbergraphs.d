module numbergraphs;

import std.experimental.logger;
import std.container.array;

import graph;
import bitsetmodule;
import graphmeasures;

Graph!Size numberToGraph(int Size = 64)(ulong num, ulong graphSize) {
	Graph!Size ret = Graph!Size(cast(int)graphSize);

	int l = 0;
	--graphSize;
	for(; graphSize > 0; --graphSize, ++l) {
		auto bs = Bitset!ulong(num);
		for(size_t i = 0; i < graphSize; ++i) {
			//logf("%s %s %s %s", l, i, graphSize, bs.toString());
			if(bs.test(i)) {
				int r = cast(int)i;
				r += l + 1;
				//logf("inserted %s %s", l, r);
				ret.setEdge(l, r);
			}
		}
		//logf("%s", Bitset!(ulong)(num).toString());
		num = num >>> graphSize;
		//logf("%s", Bitset!(ulong)(num).toString());
	}

	return ret;
}

unittest {
	import floydmodule;
	auto g = numberToGraph(0b1_01_001, 4);
	logf("\n%s", g.toString());
	assert(isConnected(g), g.toString());

	auto fl = floyd(g);
}

class GraphMeasurements {
	DiameterResult dia;
	DegreeResult dgr;
	double connectivity;
	BetweennessCentrality between;

	void build(G)(auto ref G graph) {
		import graphmeasures;
		this.dia = computeDiameter(graph);
		this.dgr = computeDegree(graph);
		this.connectivity = computeConnectivity(graph);
		this.between = betweennessCentrality(graph);
	}
}

abstract class GTNodeA {
	GraphMeasurements gm;
}

class GTNode : GTNodeA {
	GTNodeA[double] follow;
}

class GTLeaf : GTNodeA {
	Array!(Graph!64) graphs;
}

pure double diaMin(const GraphMeasurements gm) { return gm.dia.min; }
pure double diaAvg(const GraphMeasurements gm) { return gm.dia.average; }
pure double diaMode(const GraphMeasurements gm) { return gm.dia.mode; }
pure double diaMedian(const GraphMeasurements gm) { return gm.dia.median; }
pure double diaMax(const GraphMeasurements gm) { return gm.dia.max; }

pure double dgrMin(const GraphMeasurements gm) { return gm.dgr.min; }
pure double dgrAvg(const GraphMeasurements gm) { return gm.dgr.average; }
pure double dgrMode(const GraphMeasurements gm) { return gm.dgr.mode; }
pure double dgrMedian(const GraphMeasurements gm) { return gm.dgr.median; }
pure double dgrMax(const GraphMeasurements gm) { return gm.dgr.max; }

pure double btwMin(const GraphMeasurements gm) { return gm.between.min; }
pure double btwAvg(const GraphMeasurements gm) { return gm.between.average; }
pure double btwMode(const GraphMeasurements gm) { return gm.between.mode; }
pure double btwMedian(const GraphMeasurements gm) { return gm.between.median; }
pure double btwMax(const GraphMeasurements gm) { return gm.between.max; }

pure double con(const GraphMeasurements gm) { return gm.connectivity; }

alias SelectorFuncType = pure double function(const GraphMeasurements);

SelectorFuncType[] selectorArray = [
		&diaMin, &diaAvg, &diaMode, &diaMedian, &diaMax,
		&dgrMin, &dgrAvg, &dgrMode, &dgrMedian, &dgrMax,
		&btwMin, &btwAvg, &btwMode, &btwMedian, &btwMax,
		&con
	];

unittest {
	auto n = new GTLeaf();
	auto n2 = new GTNode();
}

void insertGraph(GTNodeA cur, Graph!64 graph) {
	if(isConnected(graph)) {
		insertGraph(cur, graph, selectorArray);
	}
}

void insertGraph(GTNodeA cur, Graph!64 graph, SelectorFuncType[] sels) {
	import graphisomorph2;
	auto gm = new GraphMeasurements();
	gm.build(graph);

	foreach(idx, func; sels) {
		double val = func(gm);
		//logf("%s %s", idx, val);
		GTNode curT = cast(GTNode)cur;
		if(val !in curT.follow) {
			if(idx + 1 < sels.length) {
				curT.follow[val] = new GTNode();
			} else {
				curT.follow[val] = new GTLeaf();
			}
		}
		cur = curT.follow[val];
	}
	GTLeaf leaf = cast(GTLeaf)cur;
	foreach(it; leaf.graphs[]) {
		if(areGraphsIso2(it, graph)) {
			return;
		}
	}
	leaf.graphs.insertBack(graph);
}

string graphTreeToString(GTNodeA cur) {
	import std.array : appender;
	auto app = appender!string();
	graphTreeToString(app, 0, cur);
	return app.data;
}

void graphTreeToString(App)(ref App app, int indent, GTNodeA cur) {
	import std.format : formattedWrite;
	GTNode curT = cast(GTNode)cur;
	if(curT !is null) {
		foreach(key, value; curT.follow) {
			for(int i = 0; i < indent; ++i) { 
				formattedWrite(app, " "); 
			}
			formattedWrite(app, "%s\n", key);
			graphTreeToString(app, indent + 1, value);
		}
	} else {
		for(int i = 0; i < indent; ++i) { 
			formattedWrite(app, " "); 
		}
		GTLeaf l = cast(GTLeaf)cur;
		formattedWrite(app, "num graphs %s\n", l.graphs.length);
	}
}

size_t countGraphsInTree(GTNodeA cur) {
	GTNode curT = cast(GTNode)cur;
	size_t ret = 0;
	if(curT !is null) {
		foreach(key, value; curT.follow) {
			ret += countGraphsInTree(value);
		}
	} else {
		GTLeaf l = cast(GTLeaf)cur;
		ret += l.graphs.length;
	}
	return ret;
}

unittest {
	auto g = numberToGraph(0b1_01_001, 4);
	auto g2 = numberToGraph(0b1_11_101, 4);

	auto n = new GTNode();
	insertGraph(n, g);
	insertGraph(n, g2);
	logf("\n%s\nnum graphs%s", graphTreeToString(n), countGraphsInTree(n));
}

/*unittest {
	auto n = new GTNode();
	size_t gs = 5;
	size_t p = ((gs - 1) * (gs - 1)) / 2;
	logf("%s %s", gs, p);
	for(ulong i = 0; i < 2^^p; ++i) {
		auto g = numberToGraph(i, gs);
		insertGraph(n, g);
	}
	logf("\n%s\nnum graphs %s for a gs with %s", graphTreeToString(n),
			countGraphsInTree(n), gs);
}

unittest {
	auto n = new GTNode();
	size_t gs = 6;
	size_t p = ((gs - 1) * (gs - 1)) / 2;
	logf("%s %s", gs, p);
	for(ulong i = 0; i < 2^^p; ++i) {
		auto g = numberToGraph(i, gs);
		insertGraph(n, g);
	}
	logf("\n%s\nnum graphs %s for a gs with %s", graphTreeToString(n),
			countGraphsInTree(n), gs);
}

unittest {
	auto n = new GTNode();
	immutable size_t gs = 7;
	immutable size_t p = ((gs - 1) * (gs - 1)) / 2;
	logf("%s %s", gs, p);
	for(ulong i = 0; i < 2^^p; ++i) {
		if(i && i % 1000 == 0) {
			logf("%s %s %6s", gs, p, i);
		}
		auto g = numberToGraph(i, gs);
		insertGraph(n, g);
	}
	logf("\n%s\nnum graphs %s for a gs with %s", graphTreeToString(n),
			countGraphsInTree(n), gs);
}*/

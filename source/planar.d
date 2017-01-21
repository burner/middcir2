module planar;

import std.container.array : Array;
import std.experimental.logger;
import std.typecons : Flag;

import exceptionhandling;

import graph;

void makePlanar(Graph)(Graph orignal, ref Array!Graph result) {
	Array!Graph stack;
	stack.insertBack(orignal);
	const numNodes = assertNotEqual(orignal.nodePositions.length, 0UL);

	while(!stack.empty()) {
		Graph cur = stack.back();
		stack.removeBack();

		IsPlanar testRslt = isPlanar(cur);
		if(testRslt.planar == Planar.yes) {
			result.insertBack(cur);
		} else {
			Graph a = cur.dup;
			Graph b = cur.dup;

			assert(a.testEdge(testRslt.aBegin, testRslt.aEnd));
			assert(b.testEdge(testRslt.bBegin, testRslt.bEnd));

			a.unsetEdge(testRslt.aBegin, testRslt.aEnd);
			b.unsetEdge(testRslt.bBegin, testRslt.bEnd);

			assert(!a.testEdge(testRslt.aBegin, testRslt.aEnd));
			assert(!b.testEdge(testRslt.bBegin, testRslt.bEnd));

			stack.insertBack(a);
			stack.insertBack(b);
		}
	}
}

alias Planar = Flag!"Planar";

struct IsPlanar {
	Planar planar;
	int aBegin;
	int aEnd;

	int bBegin;
	int bEnd;
}

IsPlanar isPlanar(Graph)(const ref Graph graph) {
	import std.conv : to;
	IsPlanar ret;
	const int nn = to!int(graph.length);
	for(int ai = 0; ai < nn; ++ai) {
		for(int aj = 0; aj < nn; ++aj) {
			if(ai == aj || !graph.testEdge(ai, aj)) {
				continue;
			}

			for(int bi = 0; bi < nn; ++bi) {
				if(bi == ai || bi == aj) {
					continue;
				}
				for(int bj = 0; bj < nn; ++bj) {
					if(bj == ai || bj == aj || !graph.testEdge(bi, bj)) {
						continue;
					}

					if(graph.testEdgeIntersection(ai, aj, bi, bj)) {
						//logf("%s -> %s XX %s -> %s", ai, aj, bi, bj);
						return IsPlanar(Planar.no, ai, aj, bi, bj);
					}
				}
			}
		}
	}

	return IsPlanar(Planar.yes, 0, 0, 0, 0);
}

size_t countEdgeIntersections(Graph)(const auto ref Graph graph) {
	size_t count = 0;
	const int nn = to!int(graph.length);
	for(int ai = 0; ai < nn; ++ai) {
		for(int aj = 0; aj < nn; ++aj) {
			if(ai == aj || !graph.testEdge(ai, aj)) {
				continue;
			}

			for(int bi = 0; bi < nn; ++bi) {
				if(bi == ai || bi == aj) {
					continue;
				}
				for(int bj = 0; bj < nn; ++bj) {
					if(bj == ai || bj == aj || !graph.testEdge(bi, bj)) {
						continue;
					}

					if(graph.testEdgeIntersection(ai, aj, bi, bj)) {
						//logf("%s -> %s XX %s -> %s", ai, aj, bi, bj);
						++count;
					}
				}
			}
		}
	}

	return count;
}

unittest {
	auto g = makeTwoTimesTwo();

	Array!(Graph!16) planarGraphs;
	makePlanar(g, planarGraphs);

	assert(g.testEdgeIntersection(0, 3, 1, 2));
}

unittest {
	import std.stdio : File;
	import std.format : format;
	auto g =  genTestGraph!16();
	g.setEdge(2, 13);

	auto f = File("testGraph_Orig.tex", "w");
	g.toTikz(f.lockingTextWriter());

	Array!(Graph!16) planarGraphs;
	makePlanar(g, planarGraphs);

	for(size_t i = 0; i < planarGraphs.length; ++i) {
		auto o = File(format("testGraph_planar_%d.tex", i), "w");
		planarGraphs[i].toTikz(o.lockingTextWriter());
	}
}

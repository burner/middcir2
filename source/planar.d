module planar;

import std.container.array : Array;
import std.experimental.logger;
import std.typecons : Flag;

import exceptionhandling;

import graph;

void makePlanar(Graph)(Graph orignal, ref Array!Graph result) {
	import std.algorithm.searching : canFind;
	import std.random : randomShuffle;
	Array!Graph stack;
	stack.insertBack(orignal);
	assertNotEqual(orignal.nodePositions.length, 0UL);
	const numNodes = orignal.nodePositions.length;

	size_t iterations = 0;
	size_t planarCount = 0;
	outer: while(!stack.empty()) {
		iterations++;
		if(iterations % 1000 == 0) {
			logf("stack size %10s iterations %10s", stack.length, iterations);
		}
		if(iterations > 1_000_000 && planarCount > 0) {
			logf("broke after 1_000_000 iterations");
			break;
		}
		//logf("stack size %s", stack.length);
		Graph cur = stack.back();
		stack.removeBack();

		if(!isConnected(cur)) {
			continue;
		}

		IsPlanar testRslt = isPlanar(cur);
		if(testRslt.planar == Planar.yes) {
			randomShuffle(stack[]);
			bool found = canFind(result[], cur);
			if(!found) {
				planarCount++;
				result.insertBack(cur);
				logf("\n%s\n result size %s\niterations %s\nplanar count %s", 
						cur, result.length, iterations, planarCount
					);
			}
			if(planarCount > 100) {
				break outer;
			}
		} else {
			//logf("%s ", testRslt.edges.length);
			foreach(idx, it; testRslt.edges) {
				//logf("idx %s", idx);
				Graph a = cur.dup;
				Graph b = cur.dup;
				ensure(simpleGraphCompare(a, cur));
				ensure(simpleGraphCompare(b, cur));

				ensure(a.testEdge(it.aBegin, it.aEnd));
				ensure(b.testEdge(it.bBegin, it.bEnd));

				a.unsetEdge(it.aBegin, it.aEnd);
				b.unsetEdge(it.bBegin, it.bEnd);

				ensure(!a.testEdge(it.aBegin, it.aEnd));
				ensure(!b.testEdge(it.bBegin, it.bEnd));

				bool foundA = canFind(stack[], a);
				bool foundB = canFind(stack[], b);

				if(!foundA && isConnected(a)) {
					stack.insertBack(a);
				}

				if(!foundB && isConnected(b)) {
					stack.insertBack(b);
				}

				/*bool foundA = false;
				foreach(ref jt; stack[]) {
					if(simpleGraphCompare(jt, a)) {
						foundA = true;
						break;
					}
				}
				if(!foundA) {
					logf("insert a");
					stack.insertBack(a);
				}
				bool foundB = false;
				foreach(ref jt; stack[]) {
					if(simpleGraphCompare(jt, b)) {
						foundB = true;
						break;
					}
				}
				if(!foundB) {
					logf("insert b");
					stack.insertBack(b);
				}*/
			}
		}
	}
	logf("result size result size result size %s", result.length);
}

alias Planar = Flag!"Planar";

struct Edge {
	int aBegin;
	int aEnd;

	int bBegin;
	int bEnd;

	static Edge opCall(int aB, int aE, int bB, int bE) {
		Edge ret;
		if(aB < aE) {
			ret.aBegin = aB;
			ret.aEnd = aE;
		} else {
			ret.aBegin = aE;
			ret.aEnd = aB;
		}

		if(bB < bE) {
			ret.bBegin = bB;
			ret.bEnd = bE;
		} else {
			ret.bBegin = bE;
			ret.bEnd = bB;
		}

		return ret;
	}

	bool opEquals(const ref typeof(this) other) const {
		return this.aBegin == other.aBegin
			&& this.aEnd == other.aEnd
			&& this.bBegin == other.bBegin
			&& this.bEnd == other.bEnd;
	}
}

struct IsPlanar {
	Planar planar;
	Edge[] edges;
}

IsPlanar isPlanar(Graph)(const ref Graph graph) {
	import std.conv : to;
	IsPlanar ret;
	ret.planar = Planar.yes;
	const int nn = to!int(graph.length);
	for(int ai = 0; ai < nn; ++ai) {
		for(int aj = ai + 1; aj < nn; ++aj) {
			if(ai == aj || !graph.testEdge(ai, aj)) {
				continue;
			}

			for(int bi = ai + 1; bi < nn; ++bi) {
				if(bi == ai || bi == aj) {
					continue;
				}
				inner: for(int bj = bi + 1; bj < nn; ++bj) {
					if(bj == ai || bj == aj || !graph.testEdge(bi, bj)) {
						continue;
					}

					if(graph.testEdgeIntersection(ai, aj, bi, bj)) {
						//logf("%s -> %s XX %s -> %s", ai, aj, bi, bj);
						ret.planar = Planar.no;
						Edge tmp = Edge(ai, aj, bi, bj);
						foreach(ref it; ret.edges) {
							if(it == tmp) {
								continue inner;
							}
						}
						ret.edges ~= tmp;
					}
				}
			}
		}
	}

	return ret;
}

size_t countEdgeIntersections(Graph)(const auto ref Graph graph) {
	import std.conv : to;
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

/*
unittest {
	auto g = makeTwoTimesTwo();

	Array!(Graph!16) planarGraphs;
	makePlanar(g, planarGraphs);

	assert(g.testEdgeIntersection(0, 3, 1, 2));
}
*/

unittest {
	import std.stdio : File;
	import std.format : format;
	auto g =  genTestGraph!16();
	g.setEdge(2, 13);
	g.setEdge(1, 10);

	auto f = File("testGraph_Orig.tex", "w");
	g.toTikz(f.lockingTextWriter());

	Array!(Graph!16) planarGraphs;
	makePlanar(g, planarGraphs);

	for(size_t i = 0; i < planarGraphs.length; ++i) {
		auto o = File(format("testGraph_planar_%d.tex", i), "w");
		planarGraphs[i].toTikz(o.lockingTextWriter());
	}
}

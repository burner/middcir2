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
	Array!Graph dump;
	stack.insertBack(orignal);
	assertNotEqual(orignal.nodePositions.length, 0UL);
	const numNodes = orignal.nodePositions.length;

	size_t iterations = 0;
	size_t planarCount = 0;
	size_t createdMultipleTimes = 0;
	outer: while(!stack.empty()) {
		iterations++;
		//if(iterations % 1000 == 0) {
			//logf("stack size %10s iterations %10s dump size %10s",
			//		stack.length, iterations, dump.length);
		//}
		if(iterations > 500_000) {
			logf("broke out after X stack.length %s dump.length %s",
					stack.length, dump.length
				);
			break outer;
		}
		if(iterations > 100_000 && planarCount > 0) {
			//logf("broke after 1_000_000 iterations");
			break;
		}
		//logf("stack size %s", stack.length);
		Graph cur = stack.back();
		stack.removeBack();

		if(canFind(dump[], cur)) {
			continue;
		}

		//if(!isConnected(cur)) {
		//	dump.insert(cur);
		//	continue;
		//}

		IsPlanar testRslt = isPlanar(cur);
		if(testRslt.planar == Planar.yes) {
			randomShuffle(stack[]);
			bool found = canFind(result[], cur);
			if(!found) {
				planarCount++;
				result.insertBack(cur);
				//logf("\n%s\n result size %s\niterations %s\nplanar count %s", 
				//		cur, result.length, iterations, planarCount
				//	);
			} else {
				++createdMultipleTimes;
			}
			if(planarCount > 100) {
				break outer;
			}
		} else {
			//logf("%s ", testRslt.edges.length);
			foreach(idx, it; testRslt.edges) {
				//logf("idx %s", idx);
				{
					Graph a = cur.dup;
					ensure(simpleGraphCompare(a, cur));
					ensure(a.testEdge(it.aBegin, it.aEnd));
					a.unsetEdge(it.aBegin, it.aEnd);
					ensure(!a.testEdge(it.aBegin, it.aEnd));

					bool foundA = canFind(stack[], a);
					if(!foundA && isConnected(a)) {
						if(!canFind(dump[], a)) {
							stack.insertBack(a);
						}
					} else {
						dump.insert(a);
					}
				}

				{
					Graph b = cur.dup;
					ensure(simpleGraphCompare(b, cur));
					ensure(b.testEdge(it.bBegin, it.bEnd));
					b.unsetEdge(it.bBegin, it.bEnd);
					ensure(!b.testEdge(it.bBegin, it.bEnd));

					bool foundB = canFind(stack[], b);

					if(!foundB && isConnected(b)) {
						if(!canFind(dump[], b)) {
							stack.insertBack(b);
						}
					} else {
						dump.insert(b);
					}
				}
			}
		}
	}
	logf("result size %s in %,s iterations, created multiple times %s, " 
			~ "dump %s, stack %s",
			result.length, iterations, createdMultipleTimes, dump.length,
			stack.length
		);
}

alias Planar = Flag!"Planar";

struct Edge {
	int aBegin;
	int aEnd;

	int bBegin;
	int bEnd;

	static Edge opCall(int aB, int aE, int bB, int bE) {
		Edge ret;
		//ret.aBegin = aB;
		//ret.aEnd = aE;

		//ret.bBegin = bB;
		//ret.bEnd = bE;
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

		if(ret.bBegin < ret.aBegin) {
			int tmp = ret.aBegin;
			ret.aBegin = ret.bBegin;
			ret.bBegin = tmp;

			tmp = ret.aEnd;
			ret.aEnd = ret.bEnd;
			ret.bEnd = tmp;
		} else if(ret.bBegin == ret.aBegin && ret.bEnd < ret.aEnd) {
			int tmp = ret.aBegin;
			ret.aBegin = ret.bBegin;
			ret.bBegin = tmp;

			tmp = ret.aEnd;
			ret.aEnd = ret.bEnd;
			ret.bEnd = tmp;
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
		for(int aj = 0; aj < nn; ++aj) {
			if(ai == aj || !graph.testEdge(ai, aj)) {
				continue;
			}

			for(int bi = 0; bi < nn; ++bi) {
				inner: for(int bj = 0; bj < nn; ++bj) {
					if(bi == bj || !graph.testEdge(bi, bj)) {
						continue;
					}

					if(ai == bi && aj == bj) {
						continue;
					}

					if(ai == bj && aj == bi) {
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

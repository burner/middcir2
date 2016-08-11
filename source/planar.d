module planar;

import std.container.array : Array;

import exceptionhandling;

import graph;

void makePlanar(Graph)(const ref Graph orignal, Array!Graph result) {
	const numNodes = assertNotEqual(orignal.nodePositions.length, 0);
}

unittest {
	auto g = makeTwoTimesTwo();

	Array!(Graph!16) planarGraphs;
	makePlanar(g, planarGraphs);

	assert(g.testEdgeIntersection(0, 3, 1, 2));
}

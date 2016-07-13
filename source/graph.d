module graph;

import std.traits : isIntegral;
import gfm.math.vector;

void populate(A,V)(ref A arr, size_t size, V defaultValue) {
	arr.reserve(size);
	for(size_t i = 0; i < size; ++i) {
		arr.insertBack(defaultValue);
	}
}

struct Graph(int Size) {
	import bitsetmodule;
	import std.container.array;

	static if(Size <= 8) {
		alias Node = Bitset!ubyte;
	} else static if(Size <= 16) {
		alias Node = Bitset!ushort;
	} else static if(Size <= 32) {
		alias Node = Bitset!uint;
	} else static if(Size <= 64) {
		alias Node = Bitset!ulong;
	}

	int numNodes;

	this(int numNodes) {
		this.numNodes = numNodes;
	}

	Node[Size] nodes;

	Array!vec3d nodePositions;

	void setNodePos(size_t nodeId, vec3d newPos) {
		assert(nodeId < this.numNodes);
		if(this.nodePositions.empty) {
			this.nodePositions.populate(this.numNodes, vec3d(0.0, 0.0, 0.0));
		}

		this.nodePositions[nodeId] = newPos;
	}

	void setEdge(int f, int t) pure {
		assert(f < this.numNodes);
		assert(t < this.numNodes);

		nodes[f].set(t);
		nodes[t].set(f);
	}

	bool testEdge(int f, int t) pure const {
		assert(f < this.numNodes);
		assert(t < this.numNodes);

		return this.nodes[f][t];
	}

	@property size_t length() pure const {
		return this.numNodes;
	}
}

unittest {
	Graph!7 g1;
	Graph!8 g2;
	Graph!11 g3;
	Graph!12 g4;
	Graph!17 g5;
	Graph!28 g6;
	auto g7 = Graph!63(32);

	g7.setNodePos(18, vec3d(1.0,2.0,3.0));

	//pragma(msg, Graph!9.sizeof);
}

unittest {
	int len = 8;
	auto g = Graph!16(len);
	g.setEdge(4,5);
	assert(g.testEdge(4,5));
}

unittest {
	import std.random : uniform;
	int len = 16;

	bool[][] test = new bool[][](16,16);
	auto g = Graph!16(len);

	const upTo = (len * len) / 5;
	for(int i = 0; i < upTo; ++i) {
		const f = uniform(0, 16);
		const t = uniform(0, 16);
		test[f][t] = true;

		g.setEdge(f,t);
	}

	foreach(int ridx, row; test) {
		foreach(int cidx, col; row) {
			if(col) {
				assert(g.testEdge(ridx, cidx));
				assert(g.testEdge(cidx, ridx));
			}
		}
	}
}

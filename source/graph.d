module graph;

import std.math;
import std.traits : isIntegral;
import std.experimental.logger;
import gfm.math.vector;
import math;

void populate(A,V)(ref A arr, size_t size, V defaultValue) {
	arr.reserve(size);
	for(size_t i = 0; i < size; ++i) {
		arr.insertBack(defaultValue);
	}
}

struct Graph(int Size) {
	import bitsetmodule;
	import std.container.array;
	import std.array : appender;
	import std.format : formattedWrite;

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

	Graph!Size dup() const {
		auto ret = Graph!Size(this.numNodes);
		for(size_t i = 0; i < this.numNodes; ++i) {
			ret.nodes[i] = this.nodes[i];
		}

		for(size_t i = 0; i < this.nodePositions.length; ++i) {
			ret.nodePositions.insertBack(this.nodePositions[i]);
		}
		return ret;
	}

	void setNodePos(size_t nodeId, vec3d newPos) {
		assert(nodeId < this.numNodes);
		while(this.nodePositions.length < this.numNodes) {
			this.nodePositions.insertBack(vec3d(0.0, 0.0, 0.0));
		}

		this.nodePositions[nodeId] = newPos;
	}

	@property size_t length() pure const {
		return this.numNodes;
	}

	void setEdge(int f, int t) pure {
		assert(f < this.numNodes);
		assert(t < this.numNodes);

		nodes[f].set(t);
		nodes[t].set(f);
	}

	void unsetEdge(int f, int t) pure {
		assert(f < this.numNodes);
		assert(t < this.numNodes);

		nodes[f].reset(t);
		nodes[t].reset(f);
	}

	bool testEdge(int f, int t) pure const {
		assert(f < this.numNodes);
		assert(t < this.numNodes);

		return this.nodes[f][t];
	}


	int getLeftMostNode() const {
		int ret;
		bool first = true;
		vec3d vec;
		for(int i = 0; i < this.length; ++i) {
			if(first || this.nodePositions[i].x < vec.x) {
				ret = i;
				vec = this.nodePositions[i];
				first = false;
			}
		}
		return ret;
	}

	vec3d startEdgeStartNode(vec3d leftMost) const {
		return vec3d(leftMost.x - 1.0, leftMost.y, leftMost.z);
	}

	/** This function sets the nextNodeId to id of the next node, additionally
	the curEdgeDir will be a vector pointing from the node edgeEnd to the node 
	nextNodeId
	*/
	void nextNode(int edgeStart, int edgeEnd, ref vec3d curEdgeDir, 
			out int nextNodeId) const
	{
		double maxAngle;
		for(int i = 0; i < this.numNodes; ++i) {
			if(i != edgeStart && this.testEdge(edgeEnd, i)) {
				vec3d dir = dirOfEdge(this.nodePositions[edgeEnd],
						this.nodePositions[i]
				);
				double angle = angleFunc(curEdgeDir, dir);
				if(isNaN(maxAngle) || angle > maxAngle) {
					maxAngle = angle;
					nextNodeId = i;
				}
			}
		}

		if(isNaN(maxAngle)) {
			nextNodeId = edgeStart;
		}

		curEdgeDir = dirOfEdge(this.nodePositions[edgeEnd],
			this.nodePositions[nextNodeId]
		);
	}

	Array!int computeBorder() const {
		Array!int ret;

		// compute fake start edge
		int startNode = this.getLeftMostNode();
		vec3d startNodeVec = startEdgeStartNode(this.nodePositions[startNode]);
		vec3d curEdgeDir = dirOfEdge(startNodeVec, this.nodePositions[startNode]);

		int lastNode = int.min;
		int curNode = startNode;
		do {
			int nextNode;
			ret.insertBack(curNode);
			this.nextNode(lastNode, curNode, curEdgeDir, nextNode);
			lastNode = curNode;
			curNode = nextNode;
		} while(curNode != startNode);

		return ret;
	}

	string toTikz() const {
		auto app = appender!string();
		toTikz(app);
		return app.data;
	}

	void toTikz(T)(auto ref T app) const {
		import std.exception : enforce;
		string topMatter =
`\documentclass[tikz]{standalone}
\usepackage{tikz}
\usepackage{pgfplots}
\usetikzlibrary{decorations.markings, arrows, decorations.pathmorphing,
   backgrounds, positioning, fit, shapes.geometric}
\IfFileExists{../config.tex}%
	{\input{../config}}%
	{
	\tikzstyle{place} = [shape=circle,
    draw, align=center,minimum width=0.70cm,
    top color=white, bottom color=blue!20]
	}
\begin{document}
\begin{tikzpicture}
`;
		string bottomMatter = 
`\end{tikzpicture}
\end{document}
`;
		enforce(this.nodePositions.length == this.numNodes);
		app.put(topMatter);
		for(int i = 0; i < this.numNodes; ++i) {
			formattedWrite(app, "\t\\node at(%4.1f, %4.1f) [place] (%s) {%s};\n",
				this.nodePositions[i].x, this.nodePositions[i].y, i, i
			);
		}

		for(int f = 0; f < this.numNodes; ++f) {
			for(int t = f; t < this.numNodes; ++t) {
				if(this.testEdge(f, t)) {
					formattedWrite(app, 
						"\t\\draw[-,line width=0.5mm,black] (%s) -- (%s);\n",
						f, t
					);
				}
			}
		}

		app.put(bottomMatter);
	}

	bool testEdgeIntersection(int aFrom, int aTo, int bFrom, int bTo) const
			pure 
	{
		auto tStart = this.nodePositions[aFrom];
		auto tEnd = this.nodePositions[aTo];
	
		auto oStart = this.nodePositions[bFrom];
		auto oEnd = this.nodePositions[bTo];
	
	    auto s1_x = tEnd.x - tStart.x; 
		auto s1_y = tEnd.y - tStart.y; 
		auto s2_x = oEnd.x - oStart.x;
		auto s2_y = oEnd.y - oStart.y;
	
	    double s = (-s1_y * (tStart.x - oStart.x) + s1_x * (tStart.y - oStart.y)) / (-s2_x * s1_y + s1_x * s2_y);
	    double t = ( s2_x * (tStart.y - oStart.y) - s2_y * (tStart.x - oStart.x)) / (-s2_x * s1_y + s1_x * s2_y);
	
	    if(s >= 0 && s <= 1 && t >= 0 && t <= 1) {
	        // Collision detected
	        return true;
	    }
	
	    return false; // No collision
	}

	string toString() const {
		auto app = appender!string();
		toString(app);
		return app.data;
	}

	void toString(A)(ref A app) const {
		for(int i = 0; i < this.length; ++i) {
			if(i < this.nodePositions.length) {
				formattedWrite(app, "%2s(%3.1f,%3.1f):", i,
						this.nodePositions[i].x, this.nodePositions[i].y
				);
			} else {
				formattedWrite(app, "%2s:", i);
			}
			for(int j = 0; j < this.length; ++j) {
				if(j != i && testEdge(i, j)) {
					formattedWrite(app, "%2s ", j);
				}
			}
			formattedWrite(app, "\n");
		}
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

unittest {
	import std.stdio : File, writeln;

	auto g = genTestGraph!16();
	auto f = File("tikztest.tex", "w");
	f.write(g.toTikz());
}

Graph!Size genTestGraph(int Size)() {
	auto g = Graph!Size(16);
	g.setNodePos(0, vec3d(0.5,2,0.0));
	g.setNodePos(1, vec3d(1.5,1,0.0));
	g.setNodePos(2, vec3d(1.5,3.5,0.0));
	g.setNodePos(3, vec3d(4,4,0.0));
	g.setNodePos(4, vec3d(2,2.5,0.0));
	g.setNodePos(5, vec3d(4.5,2,0.0));
	g.setNodePos(6, vec3d(5,3,0.0));
	g.setNodePos(7, vec3d(4,3,0.0));
	g.setNodePos(8, vec3d(4,1.4,0.0));
	g.setNodePos(9, vec3d(2.5,4.5,0.0));
	g.setNodePos(10, vec3d(2.8,3.8,0.0));
	g.setNodePos(11, vec3d(3.3,2.2,0.0));
	g.setNodePos(12, vec3d(3,0.5,0.0));
	g.setNodePos(13, vec3d(3,3,0.0));
	g.setNodePos(14, vec3d(2.5,1.5,0.0));
	g.setNodePos(15, vec3d(1.5,4.5,0.0));

	g.setEdge( 0,  1);
	g.setEdge( 1,  4);
	g.setEdge( 0,  2);
	g.setEdge( 0,  4);
	g.setEdge( 2,  4);
	g.setEdge( 4, 14);
	g.setEdge( 2, 10);
	g.setEdge( 7,  8);
	g.setEdge( 7,  5);
	g.setEdge( 7,  3);
	g.setEdge( 2, 15);
	g.setEdge( 1, 14);
	g.setEdge( 5,  8);
	g.setEdge( 5,  6);
	g.setEdge( 7,  6);
	g.setEdge( 7, 13);
	g.setEdge( 3,  6);
	g.setEdge(15,  9);
	g.setEdge( 9,  3);
	g.setEdge( 9, 10);
	g.setEdge(10, 13);
	g.setEdge( 4, 13);
	g.setEdge( 4, 10);
	g.setEdge( 4, 11);
	g.setEdge(14, 12);
	g.setEdge( 1, 12);
	g.setEdge(14, 11);
	g.setEdge(14,  8);
	g.setEdge(12,  8);
	g.setEdge(11, 13);
	g.setEdge(11,  8);
	g.setEdge(11,  8);
	g.setEdge(11,  7);
	g.setEdge(10,  3);
	g.setEdge(10,  7);	
	
	return g;
}

unittest {
	auto g = genTestGraph!32();

	auto id = g.getLeftMostNode();
	assert(id == 0);

	auto border = g.computeBorder();
	auto test = [0, 2, 15, 9, 3, 6, 5, 8, 12, 1];
	assert(border.length == test.length);
	for(size_t i = 0; i < border.length; ++i) {
		assert(border[i] == test[i]);
	}
}

Graph!16 makeTwoTimesTwo() {
	auto ret = Graph!16(4);
	ret.setNodePos(0, vec3d(0.0, 0.0, 0.0));
	ret.setNodePos(1, vec3d(1.0, 0.0, 0.0));
	ret.setNodePos(2, vec3d(0.0, 1.0, 0.0));
	ret.setNodePos(3, vec3d(1.0, 1.0, 0.0));

	ret.setEdge(0, 1);
	ret.setEdge(0, 2);
	ret.setEdge(0, 3);
	ret.setEdge(1, 3);
	ret.setEdge(1, 2);
	ret.setEdge(2, 3);

	return ret;
}

Graph!16 makeLineOfFour() {
	auto ret = Graph!16(4);
	ret.setNodePos(0, vec3d(0.0, 0.0, 0.0));
	ret.setNodePos(1, vec3d(1.0, 0.0, 0.0));
	ret.setNodePos(2, vec3d(2.0, 0.0, 0.0));
	ret.setNodePos(3, vec3d(3.0, 0.0, 0.0));

	ret.setEdge(0, 1);
	ret.setEdge(1, 2);
	ret.setEdge(2, 3);

	return ret;
}

Graph!Size makeSix(int Size)() {
	auto g = Graph!Size(6);
	g.setNodePos(2, vec3d(2,2.5,0.0));
	g.setNodePos(3, vec3d(4.5,2,0.0));
	g.setNodePos(5, vec3d(4,3,0.0));
	g.setNodePos(4, vec3d(3.3,2.2,0.0));
	g.setNodePos(0, vec3d(3,0.5,0.0));
	g.setNodePos(1, vec3d(2.5,1.5,0.0));

	g.setEdge(0, 1);
	g.setEdge(1, 2);
	g.setEdge(2, 4);
	g.setEdge(1, 4);
	g.setEdge(4, 5);
	g.setEdge(4, 3);
	g.setEdge(1, 3);

	return g;
}

Graph!Size makeNine(int Size)() {
	auto g = Graph!Size(9);
	g.setNodePos(2, vec3d(2,2.5,0.0));
	g.setNodePos(6, vec3d(4.5,2,0.0));
	g.setNodePos(8, vec3d(5,3,0.0));
	g.setNodePos(7, vec3d(4,3,0.0));
	g.setNodePos(3, vec3d(4,1.4,0.0));
	g.setNodePos(4, vec3d(3.3,2.2,0.0));
	g.setNodePos(0, vec3d(3,0.5,0.0));
	g.setNodePos(5, vec3d(3,3,0.0));
	g.setNodePos(1, vec3d(2.5,1.5,0.0));

	g.setEdge(0, 1);
	g.setEdge(0, 3);
	g.setEdge(1, 3);
	g.setEdge(1, 2);
	g.setEdge(1, 4);
	g.setEdge(2, 5);
	g.setEdge(2, 4);
	g.setEdge(5, 7);
	g.setEdge(7, 8);
	g.setEdge(6, 8);
	g.setEdge(6, 7);
	g.setEdge(4, 6);
	g.setEdge(4, 7);
	g.setEdge(3, 6);

	return g;
}

unittest {
	{
	import std.stdio : File;
	auto g = makeNine!16();
	auto f = File("tikztest9.tex", "w");
	f.write(g.toTikz());
	}

	{
	import std.stdio : File;
	auto g = makeSix!16();
	auto f = File("tikztest6.tex", "w");
	f.write(g.toTikz());
	}
}

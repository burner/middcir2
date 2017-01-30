module graph;

import std.math;
import std.traits : isIntegral;
import std.experimental.logger;
import gfm.math.vector;
import math;
import exceptionhandling;

void populate(A,V)(ref A arr, size_t size, V defaultValue) {
	arr.reserve(size);
	for(size_t i = 0; i < size; ++i) {
		arr.insertBack(defaultValue);
	}
}

struct Graph(int Size) {
	import bitsetmodule;
	import fixedsizearray;
	import std.container.array;
	import std.array : appender;
	import std.format : formattedWrite;

	import stdx.data.json;

	enum Length = Size;

	static if(Size <= 8) {
		alias Node = Bitset!ubyte;
		alias NodeType = ubyte;
	} else static if(Size <= 16) {
		alias Node = Bitset!ushort;
		alias NodeType = ushort;
	} else static if(Size <= 32) {
		alias Node = Bitset!uint;
		alias NodeType = uint;
	} else static if(Size <= 64) {
		alias Node = Bitset!ulong;
		alias NodeType = ulong;
	}

	int numNodes;
	Node[Size] nodes;
	Array!vec3d nodePositions;
	//FixedSizeArray!(vec3d,Length) nodePositions;

	long id;

	this(int numNodes) {
		this.numNodes = numNodes;
		this.id = long.min;
	}

	this(const(JSONValue) j) {
		import std.conv : to;
		this.numNodes = to!int(j["numNodes"].get!long());
		this.id = long.min;

		for(int i = 0; i < this.numNodes; ++i) {
			this.nodePositions.insertBack(vec3d());
		}
		foreach(ref it; j["nodes"].get!(JSONValue[])) {
			this.nodes[it["id"].get!long()].store = cast(NodeType)(it["adjacency"].get!long());
			this.nodePositions[it["id"].get!long()] = vec3d(
					it["x"].get!double(),
					it["y"].get!double(), 
					0.0
				);
		}

		enum idStr = "id";
		if(idStr in j) {
			this.id = j[idStr].get!long();
		}
	}

	string isomorphName() const {
		import std.array : appender;
		import std.format : formattedWrite;
		auto app = appender!string();

		formattedWrite(app, "%d", this.numNodes);
		foreach(it; nodes) {
			formattedWrite(app, "_%d", it.store);
		}
		return app.data;
	}

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
		assertLess(nodeId, cast(size_t)this.numNodes);
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

	void setAdjancy(size_t id, Node node) {
		this.nodes[id] = node;
	}

	Node getAdjancy(size_t id) const {
		return this.nodes[id];
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

	bool isHomomorph(const ref Graph other) const {
		import std.conv : to;
		import std.stdio : writeln;
		import std.algorithm : nextPermutation;
		import permutation;
		import fixedsizearray;
		if(this.length != other.length) {
			return false;
		}

		FixedSizeArray!(byte,32) perm;
		for(byte i = 0; i < this.length; ++i) {
			perm.insertBack(i);
		}

		// Lets test all combinations to see if there is a homomorphic mapping
		// Yeah, fun all combinations again.
		do {
			//writeln(perm[]);
			size_t idx;
			foreach(it; perm[]) {
				if(this.nodes[idx] != other.nodes[it]) {
					goto next;
				}
				++idx;
			}
			return true;
			next:
		} while(nextPermutation(perm[]));

		return false;

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

	void toJSON(A)(auto ref A app) const {
		import utils : format;
		format(app, 1, "{\n");
		format(app, 2, "\"numNodes\" : %d,\n", this.numNodes);
		format(app, 2, "\"id\" : %d,\n", this.id);
		format(app, 2, "\"nodes\" : [\n");
		bool first = true;
		for(int i = 0; i < this.numNodes; ++i) {
			if(first) {
				format(app, 3, "{\n");
			} else {
				format(app, 0, ",\n");
				format(app, 3, "{\n");
			}
			first = false;
			format(app, 4, "\"id\" : %d,\n", i);
			format(app, 4, "\"x\" : %f,\n", this.nodePositions[i].x);
			format(app, 4, "\"y\" : %f,\n", this.nodePositions[i].y);
			format(app, 4, "\"adjacency\" : %d\n", this.nodes[i].store);
			format(app, 3, "}");
		}
		format(app, 0, "\n");
		format(app, 2, "]\n");
		format(app, 1, "}");
	}

	bool opEquals(const ref typeof(this) other) const {
		if(this.numNodes != other.numNodes) {
			return false;
		}

		foreach(idx, it; this.nodes) {
			if(it.store != other.nodes[idx].store) {
				return false;
			}
		}

		if(this.nodePositions.length != other.nodePositions.length) {
			return false;
		}

		int idx = 0;
		foreach(it; this.nodePositions) {
			import std.math : approxEqual;

			if(!approxEqual(it.x, other.nodePositions[idx].x) 
					|| !approxEqual(it.y, other.nodePositions[idx].y) )
			{
				return false;
			}

			++idx;
		}

		return true;
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

	import std.array : appender;
	auto app = appender!string();
	g.toJSON(app);
	//writeln(app.data);

	import stdx.data.json;

	auto js = toJSONValue(app.data);
	auto g2 = typeof(g)(js);

	import std.format : format;

	assert(g == g2, format("\n%s\n%s", g, g2));
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

Graph!Size genTestGraph12(int Size)() {
	auto g = Graph!Size(12);
	g.setNodePos(0, vec3d(0.5,2,0.0));
	g.setNodePos(1, vec3d(1.5,1,0.0));
	g.setNodePos(2, vec3d(1.5,3.5,0.0));
	g.setNodePos(3, vec3d(2,2.5,0.0));
	g.setNodePos(4, vec3d(4.5,2,0.0));
	g.setNodePos(5, vec3d(4,3,0.0));
	g.setNodePos(6, vec3d(4,1.4,0.0));
	g.setNodePos(7, vec3d(2.8,3.8,0.0));
	g.setNodePos(8, vec3d(3.3,2.2,0.0));
	g.setNodePos(9, vec3d(3,0.5,0.0));
	g.setNodePos(10, vec3d(3,3,0.0));
	g.setNodePos(11, vec3d(2.5,1.5,0.0));

	g.setEdge( 0, 1);
	g.setEdge( 0, 2);
	g.setEdge( 0, 3);
	g.setEdge( 9, 6);
	g.setEdge( 9,11);
	g.setEdge( 1, 9);
	g.setEdge( 1, 3);
	g.setEdge( 1,11);
	g.setEdge( 3,11);
	g.setEdge( 6, 4);
	g.setEdge( 6, 5);
	g.setEdge( 6, 8);
	g.setEdge( 6,11);
	g.setEdge(11, 3);
	g.setEdge(11, 8);
	g.setEdge( 4, 5);
	g.setEdge( 8, 3);
	g.setEdge( 8, 5);
	g.setEdge( 8,10);
	g.setEdge( 3, 2);
	g.setEdge( 3,10);
	g.setEdge( 5, 7);
	g.setEdge( 2, 7);
	g.setEdge( 3, 7);
	g.setEdge(10, 7);
	g.setEdge(10, 5);
	
	return g;
}

unittest {
	import std.stdio : File;
	auto g = genTestGraph12!32();
	auto f = File("testgraph12.tex", "w");
	f.write(g.toTikz());
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

Graph!Size makeNine2(int Size)() {
	auto g = Graph!Size(9);
	g.setNodePos(2, vec3d(2,2.5,0.0));
	g.setNodePos(6, vec3d(4.5,2,0.0));
	g.setNodePos(8, vec3d(5,3,0.0));
	g.setNodePos(7, vec3d(1,3,4.0));
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

Graph!Size makeCircle(int Size)(const int nn) {
	// http://stackoverflow.com/questions/5300938/calculating-the-position-of-points-in-a-circle
	import std.math;
	auto ret = Graph!Size(nn);

	const(double) radius = 3.0;

	double slice = 2.0 * PI / nn;
	for(int i = 0; i < nn; ++i) {
		double angle = slice * i;
        double newX = 0.0 + radius * cos(angle);
        double newY = 0.0 + radius * sin(angle);
		ret.setNodePos(i, vec3d(newX, newY, 0.0));
	}

	return ret;
}

void completeConnectGraph(G)(ref G graph) {
	for(int i = 0; i < graph.numNodes; ++i) {
		for(int j = i; j < graph.numNodes; ++j) {
			graph.setEdge(i, j);
		}
	}
}

unittest {
	auto six = makeSix!16();
	assert(six.isHomomorph(six));	

	auto nine = makeNine!16();
	assert(!six.isHomomorph(nine));	
	assert(nine.isHomomorph(nine));	
}

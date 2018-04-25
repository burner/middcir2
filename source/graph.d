module graph;

import std.math;
import std.traits : isIntegral;
import std.experimental.logger;
import gfm.math.vector;
import math;
import exceptionhandling;
import fixedsizearray;

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
			this.nodes[cast(size_t)it["id"].get!long()].store = 
				cast(NodeType)(cast(size_t)it["adjacency"].get!long());
			this.nodePositions[cast(size_t)it["id"].get!long()] = vec3d(
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
		double maxAngle = double.nan;
		for(int i = 0; i < this.numNodes; ++i) {
			if(i != edgeStart && i != edgeEnd && this.testEdge(edgeEnd, i)) {
			//if(i != edgeEnd && this.testEdge(edgeEnd, i)) {
				/*logf("from %s(%s) -- %s(%s) to %s(%s)", 
						edgeStart, edgeStart < 200 && edgeStart >= 0?
						this.nodePositions[edgeStart] : vec3d(0,0,0), 
						edgeEnd, this.nodePositions[edgeEnd],
						i, this.nodePositions[i]
					);
				*/
				vec3d dir = dirOfEdge(this.nodePositions[edgeEnd],
						this.nodePositions[i]
				);
				//logf("cureEdgeDir %s dir %s", curEdgeDir, dir);
				double angle = angleFunc(curEdgeDir, dir);
				//logf("angle %s", angle);
				if(isNaN(maxAngle) || angle > maxAngle) {
					maxAngle = angle;
					nextNodeId = i;
				}
			}
		}

		// no edge was found
		if(isNaN(maxAngle)) {
			nextNodeId = edgeStart;
		}

		curEdgeDir = dirOfEdge(this.nodePositions[edgeEnd],
			this.nodePositions[nextNodeId]
		);
	}

	Array!int computeBorder() {
		Array!int ret;

		//log();
		// compute fake start edge
		int startNode = this.getLeftMostNode();
		const vec3d startNodeVec = startEdgeStartNode(this.nodePositions[startNode]);
		vec3d curEdgeDir = dirOfEdge(startNodeVec, this.nodePositions[startNode]);
		vec3d curNodePos;

		scope(exit) {
			this.unsetEdge(this.numNodes-1, startNode);
			this.numNodes--;
			this.nodePositions.removeBack();
		}

		bool first = true;
		int lastNode = int.min;
		int curNode = startNode;
		curNodePos = startNodeVec;
		do {
			if(ret.length > this.length * 4) {
				throw new Exception("Unable to find border overflow");
			}
			//logf("curNode %s lastNode %s", curNode, lastNode);
			int nextNode;
			ret.insertBack(curNode);
			this.nextNode(lastNode, curNode, curEdgeDir, nextNode);
			if(first) {
				this.numNodes++;
				this.setEdge(this.numNodes-1, startNode);
				this.setNodePos(this.numNodes-1, startNodeVec);
				first = false;
			}
			lastNode = curNode;
			curNode = nextNode;
			curNodePos = this.nodePositions[curNode];
			/*logf("cur %s, start %s approx %s", curNodePos, startNodeVec,
					vec3dSuperClose(startNodeVec, curNodePos));
			*/
		} while(!vec3dSuperClose(startNodeVec, curNodePos));
		//} while(curNode != startNode);

		ensure(this.nodePositions.length == this.numNodes);

		return ret;
	}

	static bool vec3dSuperClose(const vec3d a, const vec3d b) {
		import std.math : approxEqual;
		return approxEqual(a.x, b.x) && approxEqual(a.y, b.y);
	}

	string toTikz() const {
		auto app = appender!string();
		toTikz(app);
		return app.data;
	}

	string toTikzShort() const {
		auto app = appender!string();
		this.toTikzShort(app);
		return app.data;
	}

	void toTikzShort(T)(auto ref T app) const {
		import std.exception : enforce;
		string topMatter =
`\begin{tikzpicture}
`;
		string bottomMatter = 
`\end{tikzpicture}
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
	{
		double slope(vec3d a, vec3d b) {
			return (b.y - a.y) / (b.x - a.x);
		}
		import lineintersect;
		import std.math : approxEqual;
		vec3d tStart = this.nodePositions[aFrom];
		vec3d tEnd = this.nodePositions[aTo];
		//logf("old t %s %s", tStart, tEnd);

		auto tDir = tEnd - tStart;
		tDir.normalize();
		tDir *= 0.1;
		tStart += tDir;
		tEnd -= tDir;
	
		vec3d oStart = this.nodePositions[bFrom];
		vec3d oEnd = this.nodePositions[bTo];
		//logf("old o %s %s", oStart, oEnd);
		auto oDir = oEnd - oStart;
		oDir.normalize();
		oDir *= 0.1;
		oStart += oDir;
		oEnd -= oDir;

		//logf("new t %s %s", tStart, tEnd);
		//logf("new o %s %s", oStart, oEnd);

		return doIntersect(tStart, tEnd, oStart, oEnd);

		/+
		ensure(!isNaN(tStart.x));
		ensure(!isNaN(tStart.y));
		ensure(!isNaN(tEnd.x));
		ensure(!isNaN(tEnd.y));
		ensure(!isNaN(oStart.x));
		ensure(!isNaN(oStart.y));
		ensure(!isNaN(oEnd.x));
		ensure(!isNaN(oEnd.y));

		/*return doIntersect(tStart, tEnd, oStart, oEnd) 
			//&& approxEqual(slope(tStart, tEnd), slope(oStart, oEnd))
			;
		*/
	
	    auto s1_x = tEnd.x - tStart.x; 
		auto s1_y = tEnd.y - tStart.y; 
		auto s2_x = oEnd.x - oStart.x;
		auto s2_y = oEnd.y - oStart.y;

		ensure(!isNaN(s1_x));
		ensure(!isNaN(s1_y));
		ensure(!isNaN(s2_x));
		ensure(!isNaN(s2_y));
	
	    double s = (-s1_y * (tStart.x - oStart.x) + s1_x * (tStart.y - oStart.y)) / (-s2_x * s1_y + s1_x * s2_y);
		//if(isNaN(s)) {
		//	s = 0.0;
		//}

	    double t = ( s2_x * (tStart.y - oStart.y) - s2_y * (tStart.x - oStart.x)) / (-s2_x * s1_y + s1_x * s2_y);
		//if(isNaN(t)) {
		//	t = 0.0;
		//}

		////logf("tStart (%s:%s), tEnd (%s:%s), oStart (%s:%s), oEnd (%s:%s)",
		////		tStart.x, tStart.y, tEnd.x, tEnd.y, 
		////		oStart.x, oStart.y, oEnd.x, oEnd.y
		////	);
		////logf("s1_x %s, s1_y %s, s2_x %s, s2_y %s", s1_x, s1_y, s2_x, s2_y);
	    //////if(s >= 0 && s <= 1 && t >= 0 && t <= 1) {
		////logf("s %s >= 0 && s %s <= 1 && t %s >= 0 && t %s <= 1",
		////		s, s, t, t
		////	);
	    if(greaterEqual(s, 0) && lessEqual(s, 1) && greaterEqual(t, 0) &&
				lessEqual(t, 1)) 
		{
	        // Collision detected
	        return true;
	    }
	
		return doLinesIntersect(tStart, tEnd, oStart, oEnd);
	    //return false; // No collision
		+/
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
		if(this.id != long.min) {
			formattedWrite(app, "%d:\n", this.id);
		}
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
			formattedWrite(app, " |\n");
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

bool simpleGraphCompare(G)(auto ref G g1, auto ref G g2) {
	if(g1.numNodes != g2.numNodes) {
		return false;
	}

	for(size_t i = 0; i < g1.numNodes; ++i) {
		if(g1.nodes[i] != g2.nodes[i]) {
			return false;
		}
	}
	return true;
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
	import std.format : format;
	auto g = genTestGraph!32();

	auto id = g.getLeftMostNode();
	assert(id == 0);

	auto border = g.computeBorder();
	auto test = [0, 2, 15, 9, 3, 6, 5, 8, 12, 1, 0];
	assertEqual(border.length, test.length, format("[%(%s, %)]", border[]));
	for(size_t i = 0; i < border.length; ++i) {
		assertEqual(border[i], test[i], format("%s", i));
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
	import std.format : format;
	auto g = genTestGraph12!32();
	auto f = File("testgraph12.tex", "w");
	f.write(g.toTikz());
	auto border = g.computeBorder();
	auto test = [0, 2, 7, 5, 4, 6, 9, 1, 0];
	assertEqual(border.length, test.length, format("[%(%s, %)]", border[]));
	for(size_t i = 0; i < border.length; ++i) {
		assertEqual(border[i], test[i], format("%s", i));
	}

	g.numNodes++;
	g.setEdge(9, 12);
	g.setNodePos(12, vec3d(3, -0.5, 0));
	f = File("testgraph12_2.tex", "w");
	f.write(g.toTikz());
	border = g.computeBorder();
	test = [0, 2, 7, 5, 4, 6, 9, 12, 9, 1, 0];
	assertEqual(border.length, test.length, format("[%(%s, %)]", border[]));
	for(size_t i = 0; i < border.length; ++i) {
		assertEqual(border[i], test[i], format("%s", i));
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

unittest {
	import std.stdio : File;
	import std.format : format;
	auto g = makeTwoTimesTwo;
	auto f = File("testgraph2x2.tex", "w");
	f.write(g.toTikz());
	auto border = g.computeBorder();
	auto test = [0, 2, 3, 1, 0];
	assertEqual(border.length, test.length, format("[%(%s, %)]", border[]));
	for(size_t i = 0; i < border.length; ++i) {
		assertEqual(border[i], test[i], format("%s", i));
	}
}

Graph!Size makeLine(int Size)(int len) {
	auto ret = Graph!Size(len);
	for(int i = 0; i < len; ++i) {
		ret.setNodePos(1, vec3d(i, 0.0, 0.0));
		if(i > 0) {
			ret.setEdge(i-1, i);
		}
	}
	return ret;
}

Graph!16 makeLineOfFour() {
	return makeLine!(16)(4);
}

Graph!Size makeFive(int Size)() {
	auto g = Graph!Size(5);
	g.setNodePos(0, vec3d(0.0,0.0,0.0));
	g.setNodePos(1, vec3d(3.0,0.0,0.0));
	g.setNodePos(2, vec3d(0.0,3.0,0.0));
	g.setNodePos(3, vec3d(3.0,3.0,0.0));
	g.setNodePos(4, vec3d(5.5,0.0,0.0));

	g.setEdge(0, 1);
	g.setEdge(0, 2);
	g.setEdge(2, 3);
	g.setEdge(3, 1);
	g.setEdge(1, 4);

	return g;
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

void fillWithPerm(int Size)(ref const(FixedSizeArray!(byte,32)) perm,
		ref const(Graph!Size) graph,
		ref FixedSizeArray!(FixedSizeArray!(byte,32),32) mat)
{
	import std.exception : enforce;
	import std.algorithm.sorting : sort;
	import std.conv : to;
	mat.removeAll();
	mat.insertBack(FixedSizeArray!(byte,32)(), graph.length);
	assert(mat.length == graph.length);

	for(size_t i = 0; i < graph.length; ++i) {
		for(size_t b = 0; b < graph.length; ++b) {
			if(graph.nodes[i].test(b)) {
				mat[perm[i]].insertBack(perm[b]);
			}
		}
	}
	for(size_t i = 0; i < graph.length; ++i) {
		sort(mat[i][]);
	}
}

unittest {
	import bitsetmodule;
	import std.stdio : writef, writeln;
	import std.format : format;

	auto g = Graph!16(6);
	g.nodes[0] = bitset!(ushort)([1,3,4,5]);
	g.nodes[1] = bitset!(ushort)([0,2,3]);
	g.nodes[2] = bitset!(ushort)([1,3]);
	g.nodes[3] = bitset!(ushort)([0,1,2]);
	g.nodes[4] = bitset!(ushort)([0,5]);
	g.nodes[5] = bitset!(ushort)([0,4]);

	FixedSizeArray!(byte,32) perm;
	foreach(it; [0,2,4,5,1,3]) {
		perm.insertBack(it);
	}

	FixedSizeArray!(FixedSizeArray!(byte,32),32) mat;

	fillWithPerm(perm, g, mat);

	writeln("Graph\n", g, "\nMat");
	foreach(it; mat[]) {
		foreach(jt; it[]) {
			writef("%3d", jt);
		}
		writeln();
	}

	auto tta = [
		[1,2,3,5],
		[0,3],
		[0,4,5],
		[0,1],
		[2,5],
		[0,2,4]
	];

	foreach(idx, it; tta) {
		foreach(jdx, jt; it) {
			assert(mat[idx][jdx] == jt,
				format("%d %d\n%d != %d\n%(%(%2d %)\n%)", idx, jdx, 
					mat[idx][jdx], jt, tta
				)
			);
		}
	}
}

unittest {
	auto g = Graph!16(4);
	g.setEdge(0,2);
	g.setEdge(0,3);
	g.setEdge(2,3);

	FixedSizeArray!(byte,32) perm;
	perm.insertBack(1);
	perm.insertBack(0);
	perm.insertBack(2);
	perm.insertBack(3);

	FixedSizeArray!(FixedSizeArray!(byte,32)) rslt;
	fillWithPerm!16(perm, g, rslt);

	assertEqual(rslt.length, 4);
	for(size_t i = 1; i < rslt.length; ++i) {
		assertEqual(rslt[i].length, 2);
	}

	auto tca = [
		[],
		[2,3],
		[1,3],
		[1,2]
	];

	foreach(idx, it; tca) {
		foreach(jdx, jt; it) {
			assertEqual(rslt[idx][jdx], jt);
		}
	}
}

bool isConnected(int Size)(auto ref Graph!Size g) {
	import floydmodule;
	auto fr = floyd(g);
	for(uint i = 0; i < g.length; ++i) {
		for(uint j = i+1; j < g.length; ++j) {
			if(!fr.pathExists(i,j)) {
				return false;
			}
		}
	}
	return true;
}

unittest {
	auto g = Graph!16(4);
	g.setEdge(0,2);
	g.setEdge(0,3);
	g.setEdge(2,3);

	assert(!isConnected(g));
	ensure(!isConnected(g));
	g.setEdge(2,1);
	assert(isConnected(g));
}

bool compare(int Size)(ref const(FixedSizeArray!(FixedSizeArray!(byte,32))) a,
		ref const(FixedSizeArray!(FixedSizeArray!(byte,32))) b) 
{
	if(a.length != b.length) {
		return false;
	}

	for(size_t i = 0; i < a.length; ++i) {
		if(a[i].length != b[i].length) {
			return false;
		}
		for(size_t j = 0; j < a[i].length; ++j) {
			if(a[i][j] != b[i][j]) {
				return false;
			}
		}
	}

	return true;
}

bool areHomomorph(int Size)(const(Graph!Size) a, const(Graph!Size) b) {
	import std.algorithm.sorting : sort;
	if(a.length != b.length) {
		return false;
	}

	FixedSizeArray!(FixedSizeArray!(byte,32),32) aMatrix;
	aMatrix.insertBack(FixedSizeArray!(byte,32)(), a.length);
	for(size_t i = 0; i < a.length; ++i) {
		for(size_t j = 0; j < a.length; ++j) {
			if(a.nodes[i].test(j)) {
				aMatrix[i].insertBack(j);
			}
		}
		sort(aMatrix[i][]);
	}

	FixedSizeArray!(FixedSizeArray!(byte,32),32) bMatrix;

	FixedSizeArray!(byte,32) perm;
	for(byte i = 0; i < a.length; ++i) {
		perm.insertBack(i);
	}

	bool ret = areHomomorph!(Size)(aMatrix, bMatrix, perm, b);

	return ret;
}

bool areHomomorph(int Size)(
		ref const(FixedSizeArray!(FixedSizeArray!(byte,32),32)) aMatrix,
		ref FixedSizeArray!(FixedSizeArray!(byte,32),32) bMatrix,
		ref FixedSizeArray!(byte,32) perm, const(Graph!Size) b)
{
	import std.conv : to;
	import std.stdio : writeln;
	import std.algorithm : nextPermutation;
	import permutation;

	// Lets test all combinations to see if there is a homomorphic mapping
	// Yeah, fun all combinations again.
	do {
		fillWithPerm(perm, b, bMatrix);
		if(compare!Size(aMatrix, bMatrix)) {
			return true;
		}
	} while(nextPermutation(perm[]));

	return false;
}

unittest {
	auto six = makeSix!16();
	assert(areHomomorph(six, six));	
	assert(simpleGraphCompare(six, six));

	auto nine = makeNine!16();
	assert(!areHomomorph(six, nine));	
	assert(!simpleGraphCompare(six, nine));
	assert(areHomomorph(nine, nine));	
	assert(simpleGraphCompare(nine, nine));
}

unittest {
	import std.format : format;
	auto six = makeSix!16();
	auto sixD = six.dup();
	assert(areHomomorph(six, sixD));	

	auto z = six.nodes[0];
	auto f = six.nodes[5];

	for(int i = 0; i < sixD.length; ++i) {
		sixD.unsetEdge(i, 0);
		sixD.unsetEdge(i, 5);
	}

	assert(!areHomomorph!16(six, sixD));
	assert(!simpleGraphCompare(six, sixD));

	for(int i = 0; i < six.length; ++i) {
		if(i != 0 && f.test(i)) {
			sixD.setEdge(0, i);
		}
	}
	for(int i = 0; i < six.length; ++i) {
		if(i != 5 && z.test(i)) {
			sixD.setEdge(5, i);
		}
	}

	assert(areHomomorph!16(six, sixD));
}

Graph!Size stupidGraph(int Size)() {
	auto g = Graph!Size(8);
	g.setEdge(0, 1);
	g.setEdge(0, 2);
	g.setEdge(0, 4);
	g.setEdge(0, 7);
	g.setNodePos(0, vec3d(0.0, 4.0, 0.0));

	g.setEdge(1, 2);
	g.setEdge(1, 5);
	g.setNodePos(1, vec3d(1.0, 4.0, 0.0));

	g.setEdge(2, 3);
	g.setEdge(2, 5);
	g.setNodePos(2, vec3d(2.0, 4.0, 0.0));

	g.setEdge(3, 6);
	g.setNodePos(3, vec3d(3.0, 4.0, 0.0));
	
	g.setEdge(4, 7);
	g.setNodePos(4, vec3d(0.0, 3.0, 0.0));

	g.setEdge(5, 7);
	g.setNodePos(5, vec3d(1.0, 3.0, 0.0));
	
	g.setEdge(6, 7);
	g.setNodePos(6, vec3d(2.0, 3.0, 0.0));

	g.setNodePos(7, vec3d(0.0, 2.0, 0.0));

	return g;
}

unittest {
	import std.stdio;
	import planar;
	import std.container.array : Array;
	auto g = stupidGraph!64();

	auto f = File("nonplanartestgraph.tex", "w");
	auto ltw = f.lockingTextWriter();

	g.toTikz(ltw);
	assert(g.testEdgeIntersection(0, 4, 0, 7));
	assert(g.testEdgeIntersection(0, 7, 0, 4));

	auto p = isPlanar(g);
	assert(p.planar == Planar.no);

	Array!(Graph!64) planarGs;
	makePlanar(g, planarGs);
	assert(planarGs.length > 0);

	for(int i = 0; i < planarGs.length; ++i) {
		import std.format : format;
		auto f2 = File(format("nonplanartestgraph%s.tex", i), "w");
		auto ltw2 = f2.lockingTextWriter();
		planarGs[i].toTikz(ltw2);
	}
}

void graphToFile(G,A...)(auto ref G g, string foldername, A args) {
	import std.file : mkdirRecurse;
	import std.stdio;
	import std.conv : text;
	mkdirRecurse(foldername);

	auto f = File(foldername ~ "/" ~ text(args) ~ ".tex", "w");
	auto ltw = f.lockingTextWriter();
	g.toTikz(ltw);
}

unittest {
	import std.stdio;
	import planar;
	import std.container.array : Array;
	import std.algorithm.searching : canFind;
	import std.format : format;
	auto g = stupidGraph!64();

	Array!(Graph!64) planarGs;
	makePlanar(g, planarGs);

	size_t i = 0;
	foreach(ref it; planarGs[]) {
		graphToFile(it, "Test/Border1", "planar", i);
		const size_t gs = it.length();
		auto b = it.computeBorder();
		assertEqual(gs, it.length);
		logf("%s, %(%s, %)", i, b[]);
		foreach(cnt; 0 .. it.length) {
			assert(canFind(b[], cnt), format("should have found %s, in "
					~ "[%(%s,)])", cnt, b[])
				);
		}
		++i;
	}
}

Graph!Size graph8Planar(int Size)() {
	auto g = Graph!Size(8);
	g.setEdge(0, 1);
	g.setEdge(0, 2);
	g.setEdge(0, 3);
	g.setEdge(1, 3);
	g.setEdge(1, 4);
	g.setEdge(2, 5);
	g.setEdge(2, 6);
	g.setEdge(2, 7);
	g.setEdge(3, 4);
	g.setEdge(3, 5);
	g.setEdge(3, 6);
	g.setEdge(3, 7);
	g.setEdge(4, 4);
	g.setEdge(4, 7);
	g.setEdge(5, 5);
	g.setEdge(6, 6);
	g.setEdge(6, 7);
	g.setNodePos(0, vec3d(4.0,  0.0, 0.0));
	g.setNodePos(1, vec3d(7.0,  0.0, 0.0));
	g.setNodePos(2, vec3d(1.0,  1.0, 0.0));
	g.setNodePos(3, vec3d(5.0,  2.0, 0.0));
	g.setNodePos(4, vec3d(6.0,  3.0, 0.0));
	g.setNodePos(5, vec3d(3.0,  3.0, 0.0));
	g.setNodePos(6, vec3d(3.0,  7.0, 0.0));
	g.setNodePos(7, vec3d(3.0,  8.0, 0.0));
	return g;
}

unittest {
	import std.stdio;
	import planar;
	import std.container.array : Array;
	import std.algorithm.searching : canFind;
	import std.format : format;

	auto g = graph8Planar!64();

	Array!(Graph!64) planarGs;
	makePlanar(g, planarGs);
	size_t i = 0;
	foreach(ref it; planarGs[]) {
		graphToFile(it, "Test/Border1", "planar", i);
		const size_t gs = it.length();
		auto b = it.computeBorder();
		logf("%s, %(%s, %)", i, b[]);
		auto bCmp = [0,1,2,4,7];
		auto bCmpNot = [3,5,6];
		foreach(jt; bCmp) {
			assert(canFind(b[], jt), format("should have found %s, in "
					~ "[%(%s,)])", jt, b[])
				);
		}
		foreach(jt; bCmpNot) {
			assert(!canFind(b[], jt), format("should not have found %s, in "
					~ "[%(%s,)])", jt, b[])
				);
		}
		++i;
	}
}

unittest {
	import std.stdio;
	import planar;
	import std.container.array : Array;
	import std.algorithm.searching : canFind;
	import std.format : format;

	auto g = graph8Planar!64();
	g.numNodes++;
	g.setEdge(4, 8);
	g.setNodePos(8, vec3d(7.0, 2.5, 0.0));

	Array!(Graph!64) planarGs;
	makePlanar(g, planarGs);
	size_t i = 0;
	foreach(ref it; planarGs[]) {
		graphToFile(it, "Test/Border2", "planar", i);
		const size_t gs = it.length();
		logf("\n\n\n\n");
		auto b = it.computeBorder();
		logf("%s, %(%s, %)", i, b[]);
		auto bCmp = [0,1,2,4,7,8];
		auto bCmpNot = [3,5,6];
		foreach(jt; bCmp) {
			assert(canFind(b[], jt), format("should have found %s, in "
					~ "[%(%s,)])", jt, b[])
				);
		}
		foreach(jt; bCmpNot) {
			assert(!canFind(b[], jt), format("should not have found %s, in "
					~ "[%(%s,)])", jt, b[])
				);
		}
		++i;
	}
}

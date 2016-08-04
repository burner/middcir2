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
		while(this.nodePositions.length < this.numNodes) {
			this.nodePositions.insertBack(vec3d(0.0, 0.0, 0.0));
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

	string toTikz() const {
		import std.array : appender;
		auto app = appender!string();
		toTikz(app);
		return app.data;
	}

	void toTikz(T)(auto ref T app) const {
		import std.exception : enforce;
		import std.format : formattedWrite;
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
	auto g = Graph!16(16);
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
/*for(int i = 0; i < 4; ++i) {
		for(int j = 0; j < 4; ++j) {
			auto v = vec3d(i, j, 0.0);
			writeln(i*4+j, " ", v);
			g.setNodePos(i*4+j, v);
		}
	}*/

	auto f = File("tikztest.tex", "w");
	f.write(g.toTikz());
}

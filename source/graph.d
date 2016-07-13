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

	Node[Size] nodes;

	Array!vec3d nodePositions;

	void setNodePos(size_t nodeId, vec3d newPos) {
		assert(nodeId < Size);
		if(this.nodePositions.empty) {
			this.nodePositions.populate(Size, vec3d(0.0, 0.0, 0.0));
		}

		this.nodePositions[nodeId] = newPos;
	}
}

unittest {
	Graph!7 g1;
	Graph!8 g2;
	Graph!11 g3;
	Graph!12 g4;
	Graph!17 g5;
	Graph!28 g6;
	Graph!63 g7;

	g7.setNodePos(18, vec3d(1.0,2.0,3.0));

	//pragma(msg, Graph!9.sizeof);
}

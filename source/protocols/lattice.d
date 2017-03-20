module protocols.lattice;

import std.experimental.logger;
import std.stdio;
import std.typecons : Flag;

import bitsetmodule;
import graph;
import protocols;

long[][] bestGridDiffs(long size) {
	long[][] ret;

	for(long i = 1; i <= size; ++i) {
		long r = size / i;
		if(r * i == size) {
			ret ~= [r,i];
		}
	}

	return ret;
}

unittest {
	import exceptionhandling;

	auto six = bestGridDiffs(6);
	assertEqual(six.length, 4);
	assertEqual(six[0], cast(long[])[6,1]);
	assertEqual(six[1], cast(long[])[3,2]);
	assertEqual(six[2], cast(long[])[2,3]);
	assertEqual(six[3], cast(long[])[1,6]);

	auto nine = bestGridDiffs(9);
	assertEqual(nine.length, 3);
	assertEqual(nine[0], cast(long[])[9,1]);
	assertEqual(nine[1], cast(long[])[3,3]);
	assertEqual(nine[2], cast(long[])[1,9]);
}

alias Lattice = LatticeImpl!(32);

struct LatticeImpl(int Size) {
	import core.bitop : popcnt;
	import std.container.array : Array;
	import bitsetrbtree;
	import floydmodule;
	import bitfiddle;
	import utils : removeAll, testQuorumIntersection, testAllSubsetsSmaller,
		   sortBitsetStore;
	import gfm.math.vector;

	alias BSType = TypeFromSize!Size;

	static if(Size == 64) {
		BitsetArrayArrayRC!BSType read;
		BitsetArrayArrayRC!BSType write;
	} else {
		BitsetStore!BSType read;
		BitsetStore!BSType write;
	}

	size_t width;
	size_t height;

	alias LGraph = Graph!Size;

	LGraph graph;

	this(size_t width, size_t height) {
		this.width = width;
		this.height = height;
		this.graph = LGraph(cast(int)(this.width * this.height));
		this.createNodeAndEdges();

		static if(Size == 64) {
			logf("init BSAARC");
			import std.format : format;
			this.read = BitsetArrayArrayRC!BSType(
				format("TMP/Lattice%dX%dRead/", width, height)
			);
			this.write = BitsetArrayArrayRC!BSType(
				format("TMP/Lattice%dX%dWrite/", width, height)
			);
		}
	}

	void createNodeAndEdges() {
		int x = 0;
		int y = 0;
		const int numNodes = cast(int)(this.width * this.height);
		for(int i = 0; i < numNodes; ++i) {
			bool right;
			// right edge
			if((i + 1) % this.width != 0) {
				//logf("%s %s", i, i + 1);
				this.graph.setEdge(i, i + 1);
				right = true;
			}

			// top
			bool top;
			if(i / this.width < (this.height - 1)) {
				//logf("%s %s", i, i + this.width);
				this.graph.setEdge(i, cast(int)(i + this.width));
				top = true;
			}

			if(right && top) {
				//logf("%s %s", i, i + this.width + 1);
				this.graph.setEdge(i, cast(int)(i + this.width + 1));
				top = true;
			}

			this.graph.setNodePos(i, vec3d(x, y, 0.0));
			++x;
			if(x == this.width) {
				x = 0;
				++y;
			}
		}
	}

	private void fillSides(ref Array!int bottom, ref Array!int top, 
			ref Array!int left, ref Array!int right) 
	{
		for(int i = 0; i < this.width; ++i) {
			bottom.insert(i);
		}

		for(int i = 0; i < this.width; ++i) {
			top.insert(cast(int)((this.width * (this.height - 1)) + i));
		}

		for(int i = 0; i < this.height; ++i) {
			left.insert(cast(int)(i * this.width));
		}

		for(int i = 0; i < this.height; ++i) {
			right.insert(cast(int)(i * this.width + this.width - 1));
		}
	}

	Result calcAC() {
		import std.conv : to;
		import protocols.pathbased;

		const int highestId = to!int((this.width * this.height) - 1);
		Array!int bottom;
		Array!int top;
		Array!int left;
		Array!int right;
		Array!(int[2]) diagonalPairs;
		diagonalPairs.insertBack(cast(int[2])[0, highestId]);
		this.fillSides(bottom, top, left, right);
		
		auto paths = floyd!(typeof(this.graph),64)(this.graph);

		const uint numNodes = to!uint(this.width * this.height);
		//auto ret = calcACforPathBased!(typeof(this.read),BSType)(paths, this.graph, bottom, top, left,
		//	right, diagonalPairs, this.read, this.write, numNodes
		//);

		auto ret = calcACforPathBasedFast!(typeof(this.read),BSType)(paths, this.graph, bottom, top, 
			left, right, diagonalPairs, this.read, this.write, numNodes
		);

		bool test;
		debug {
			test = true;
		}
		version(unittest) {
			test = true;
		}

		if(test) {
			testQuorumIntersection(this.read, this.write);
			testAllSubsetsSmaller(this.read, this.write);
		}

		return ret;
	}

	string name() const pure {
		import std.format : format;
		return format("TLP-%sx%s", this.width, this.height);
	}

	ref auto getGraph() {
		return this.graph;
	}
}

unittest {
	import std.format;
	int w = 4;
	int h = 3;
	auto l = Lattice(w, h);

	int[2][] toExist = [
		[0,1], [1,2], [2,3], [4,5], [5,6], [6,7], [8,9], [9,10], [10,11],
		[0,4], [1,5], [2,6], [3,7], [4,8], [5,9], [6,10], [7,11],
		[0,5], [1,6], [2,7], [4,9], [5,10], [6,11]
	];

	bool[] toExistTest = new bool[toExist.length];

	for(int i = 0; i < w * h; ++i) {
		inner: for(int j = 0; j < i; ++j) {
			foreach(idx, ref it; toExist) {
				if(it[1] == i && it[0] == j) {
					assert(l.graph.testEdge(j, i), format("%s %s", j, i));
					toExistTest[idx] = true;
					continue inner;
				}
			}
			assert(!l.graph.testEdge(j, i), format("%s %s", j, i));
		}
	}

	foreach(idx, it; toExistTest) {
		assert(it);
	}
}

unittest {
	import std.format;
	int w = 2;
	int h = 2;
	auto l = Lattice(w, h);

	int[2][] toExist = [
		[0,1], [2,3], [0,2], [1,3], [0,3]
	];

	bool[] toExistTest = new bool[toExist.length];

	for(int i = 0; i < w * h; ++i) {
		inner: for(int j = 0; j < i; ++j) {
			foreach(idx, ref it; toExist) {
				if(it[1] == i && it[0] == j) {
					assert(l.graph.testEdge(j, i), format("%s %s", j, i));
					toExistTest[idx] = true;
					continue inner;
				}
			}
			assert(!l.graph.testEdge(j, i), format("%s %s", j, i));
		}
	}

	foreach(idx, it; toExistTest) {
		assert(it);
	}

	Result rslt = l.calcAC();

}

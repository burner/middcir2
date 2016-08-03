module protocols.lattice;

import std.experimental.logger;
import std.stdio;
import std.typecons : Flag;

import bitsetmodule;
import graph;
import protocols;

struct Lattice {
	import core.bitop : popcnt;
	import std.container.array : Array;
	import bitsetrbtree;
	import floydmodule;
	import bitfiddle;
	import utils : removeAll, testQuorumIntersection, testAllSubsetsSmaller;

	BitsetStore!uint read;
	BitsetStore!uint write;

	size_t width;
	size_t height;

	Graph!32 graph;

	this(size_t width, size_t height) {
		this.width = width;
		this.height = height;
		this.graph = Graph!32(cast(int)(this.width * this.height));
		this.createNodeAndEdges();
	}

	void createNodeAndEdges() {
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
		this.fillSides(bottom, top, left, right);
		
		auto paths = floyd!32(this.graph);

		Array!uint tmpPathStore;

		Array!(Bitset!uint) verticalPaths;
		Array!(Bitset!uint) horizontalPaths;
		Array!(Bitset!uint) diagonalPaths;

		const uint upto = to!uint(1 << (this.width * this.height));
		for(uint perm = 0; perm < upto; ++perm) {
			paths.execute(this.graph, bitset(perm));
			//writefln("%4d, %s", perm, paths);

			verticalPaths.removeAll();
			horizontalPaths.removeAll();
			diagonalPaths.removeAll();

			testPathsBetween(paths, top, bottom, verticalPaths, tmpPathStore);	
			testPathsBetween(paths, left, right, horizontalPaths, tmpPathStore);	
			//writefln("%(%s %)", verticalPaths[]);
			//writefln("%(%s %)", horizontalPaths[]);

			PathResult dia = testDiagonal(paths, 0, highestId, tmpPathStore);
			if(dia.validPath == ValidPath.yes) {
				diagonalPaths.insertBack(dia.minPath);
			}

			PathResult readQuorum = selectReadQuorum(verticalPaths,
					horizontalPaths, diagonalPaths
			);
			PathResult writeQuorum = selectWriteQuorum(verticalPaths,
					horizontalPaths, diagonalPaths
			);

			if(readQuorum.validPath == ValidPath.yes) {
				//writefln("read  %b %b", readQuorum.minPath.store, perm);
				this.read.insert(readQuorum.minPath, bitset!uint(perm));
			}

			if(writeQuorum.validPath == ValidPath.yes) {
				//writefln("write %b %b", writeQuorum.minPath.store, perm);
				this.write.insert(writeQuorum.minPath, bitset!uint(perm));
			}
		}

		version(unittest) {
			testQuorumIntersection(this.read, this.write);
			testAllSubsetsSmaller(this.read, this.write);
		}

		//writefln("%s", this.read.toString());

		return calcAvailForTree(to!int(this.width * this.height), this.read, this.write);
	}

	string name() const pure {
		import std.format : format;
		return format("Tri Lattice %sx%s", this.width, this.height);
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

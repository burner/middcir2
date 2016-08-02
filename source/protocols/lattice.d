module lattice;
import graph;
import protocols;
import std.experimental.logger;

struct Lattice {
	import bitsetrbtree;

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

	Result calcAC() {
		import std.conv : to;
		import std.container : Array;

		Array!int bottom;
		for(int i = 0; i < this.width; ++i) {
			bottom.insert(i);
		}

		Array!int top;
		for(int i = 0; i < this.width; ++i) {
			top.insert(cast(int)((this.width * (this.height - 1)) + i));
		}

		Array!int left;
		for(int i = 0; i < this.height; ++i) {
			left.insert(cast(int)(i * this.width));
		}

		Array!int right;
		for(int i = 0; i < this.height; ++i) {
			right.insert(cast(int)(i * this.width + this.width - 1));
		}

		const uint upto = to!uint(1 << (this.width * this.height));
		for(uint perm = 0; perm < upto; ++perm) {
		}

		return calcAvailForTree(to!int(this.width * this.height), this.read, this.write);
	}
}

unittest {
	import std.format;
	int w = 4;
	int h = 3;
	auto l = Lattice(w, h);
	auto rslt = l.calcAC();

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

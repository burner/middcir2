module protocols.lattice;
import graph;
import protocols;
import std.experimental.logger;

struct Lattice {
	import core.bitop : popcnt;
	import std.container.array : Array;
	import bitsetrbtree;
	import bitsetmodule;
	import floydmodule;
	import utils : removeAll;

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

	
	Bitset!uint selectReadQuorum(ref const(Array!(Bitset!uint)) vert,
			ref const(Array!(Bitset!uint)) hori)
	{
		Bitset!uint min;
		min.set();

		foreach(it; vert) {
			if(popcnt(it.store) < popcnt(min.store)) {
				min = it;
			}
		}

		foreach(it; hori) {
			if(popcnt(it.store) < popcnt(min.store)) {
				min = it;
			}
		}

		return min;
	}

	Bitset!uint selectWriteQuorum(ref const(Array!(Bitset!uint)) vert,
			ref const(Array!(Bitset!uint)) hori, const(Bitset!uint) diagonal)
	{
		Bitset!uint min;
		min.set();

		foreach(it; vert) {
			foreach(jt; hori) {
				auto join = bitset!uint(it.store | jt.store);
				if(popcnt(join.store) < popcnt(min.store)) {
					min = join;
				}
			}
		}

		if(popcnt(diagonal.store) < popcnt(min.store)) {
			min = diagonal;
		}

		return min;
	}

	static void testPathsBetween(ref const(Floyd) paths, ref const(Array!int) a, 
			ref const(Array!int) b, ref Array!(Bitset!uint) rslt, 
			ref Array!uint tmpPathStore)
	{
		for(uint ai = 0; ai < a.length; ++ai) {
			for(uint bi = 0; bi < b.length; ++bi) {
				tmpPathStore.removeAll();
				if(paths.path(ai, bi, tmpPathStore)) {
					rslt.insertBack(bitset!uint(tmpPathStore));
				}
			}
		}

	}

	static Bitset!uint testDiagonal(ref const(Floyd) paths, const int bl,
			const int tr, ref Array!uint tmpPathStore)
	{
		Bitset!uint ret;
		ret.set();

		tmpPathStore.removeAll();
		if(paths.path(bl, tr, tmpPathStore)) {
			ret = bitset!uint(tmpPathStore);
		}

		return ret;
	}

	Result calcAC() {
		import std.conv : to;

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

		const uint upto = to!uint(1 << (this.width * this.height));
		for(uint perm = 0; perm < upto; ++perm) {
			paths.execute(this.graph, bitset(perm));

			verticalPaths.removeAll();
			horizontalPaths.removeAll();

			testPathsBetween(paths, top, bottom, verticalPaths, tmpPathStore);	
			testPathsBetween(paths, left, right, horizontalPaths, tmpPathStore);	
			Bitset!uint dia = testDiagonal(paths, 0, highestId, tmpPathStore);

			Bitset!uint readQuorum = selectReadQuorum(verticalPaths, horizontalPaths);
			Bitset!uint writeQuorum = selectWriteQuorum(verticalPaths,
					horizontalPaths, dia
			);

			this.read.insert(readQuorum);
			this.write.insert(writeQuorum);

		}

		log(this.read.toString());

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

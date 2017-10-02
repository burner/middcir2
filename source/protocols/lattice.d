module protocols.lattice;

import std.experimental.logger;
import std.stdio;
import std.typecons : Flag;

import bitsetmodule;
import graph;
import protocols;
import utils;

alias Lattice = LatticeImpl!(32);

align(8)
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

	align(8) {
	static if(Size == 64) {
		BitsetArrayArrayRC!BSType read;
		BitsetArrayArrayRC!BSType write;
	} else {
		BitsetStore!BSType read;
		BitsetStore!BSType write;
	}

	alias LGraph = Graph!Size;

	size_t width;
	size_t height;

	LGraph graph;
	}

	static string readWriteFolder(string prefix, string rw, size_t width, 
			size_t height, bool output, size_t numNodes) 
	{
		import std.format : format;
		import config;

		if(output && getConfig().permutationStart() != 1) {
			return format("%s%dX%d%s%d-%d/", prefix, width, height, rw,
				getConfig().permutationStart(),
				getConfig().permutationStop(cast(int)numNodes));
		} else {
			return format("%s%dX%d%s", prefix, width, height, rw);
		}
	}

	this(size_t width, size_t height) {
		import config;
		import std.file : isDir, exists;
		this.width = width;
		this.height = height;
		this.graph = LGraph(cast(int)(this.width * this.height));
		this.createNodeAndEdges();
		size_t numNodes = this.width * this.height;

		static if(Size == 64) {
			import std.format : format;
			import std.conv : to;

			//string rf = format("TMP/Lattice%dX%dRead/", width, height);
			//string wf = format("TMP/Lattice%dX%dWrite/", width, height);
			string rf = readWriteFolder("TMP/Lattice", "Read/", width, height,
					false, numNodes);
			string wf = readWriteFolder("TMP/Lattice", "Write/", width,
					height, false, numNodes);
			string rfOut = readWriteFolder("TMP/Lattice", "Read/", width,
					height, true, numNodes);
			string wfOut = readWriteFolder("TMP/Lattice", "Write/", width,
					height, true, numNodes);

			logf("init BSAARC %s %s\n%s %s", rf, wf, rfOut, wfOut);
			this.read = BitsetArrayArrayRC!BSType(rfOut);
			this.write = BitsetArrayArrayRC!BSType(wfOut);

			if(getConfig().continueLattice) {
				logf("continue lattice");
				size_t maxNodes = 1;
				if(exists(rf) && isDir(rf)) {
					logf("read %s", rf);
					size_t rmn = loadFrom(rf, this.read);
					logf("read maxNodes %s", rmn);
					if(rmn > maxNodes) {
						maxNodes = rmn;
					}
				}
				if(exists(wf) && isDir(wf)) {
					logf("write %s", wf);
					size_t wmn = loadFrom(wf, this.write);
					logf("write maxNodes %s", wmn);
					if(wmn > maxNodes) {
						maxNodes = wmn;
					}
				}
				logf("rq %s wq %s", this.read.length, this.write.length);
				if(getConfig().permutationStart == -1) {
					getWriteableConfig().permutationCountStart =
						to!(int)(maxNodes + 1);
				}
			}
		} else {
			this.read = BitsetStore!uint();
			this.write = BitsetStore!uint();
		}
	}

	static size_t loadFrom(string folderName, ref BitsetArrayArrayRC!BSType store) {
		import std.file : dirEntries, SpanMode;
		import std.string : indexOf, lastIndexOf;
		import std.conv : to;
		size_t ret = 1;
		foreach(string name; dirEntries(folderName, SpanMode.depth)) {
			//logf("%s/%s", folderName, name);
			auto i = name.indexOf('.');
			auto s = name.lastIndexOf('/');
			if(i != -1 && s != -1) {
				string sname = name[s + 1 .. i];
				//logf("foldername %s sname %s", folderName, sname);
				auto bs = Bitset!BSType(to!BSType(sname));
				size_t c = bs.count();
				if(store.insertUnique(bs)) {
					if(c > ret) {
						ret = c;
					}
				}
			} else {
				logf("damaged filename %s/%s", folderName, name);
			}
		}
		return ret;
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
		/*auto ret = calcACforPathBased!(typeof(this.read),BSType)(paths, 
			this.graph, bottom, top, left, right, diagonalPairs, this.read, 
			this.write, numNodes
		);*/

		auto ret = calcACforPathBasedFast!(typeof(this.read),BSType)(paths, 
			this.graph, bottom, top, left, right, diagonalPairs, this.read, 
			this.write, numNodes
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

module protocols.crossing;

import std.experimental.logger;
import std.stdio;
import std.typecons : Flag;
import std.math : approxEqual;
import std.container.array : Array;

import gfm.math.vector;

import bitsetmodule;
import graph;
import protocols;

struct Crossing {
	import core.bitop : popcnt;
	import bitsetrbtree;
	import floydmodule;
	import bitfiddle;
	import utils : removeAll, testQuorumIntersection, testAllSubsetsSmaller;

	BitsetStore!uint read;
	BitsetStore!uint write;

	Array!int bottom;
	Array!int top;
	Array!int left;
	Array!int right;
	Array!(int[2]) diagonalPairs;

	Graph!32 graph;

	this(ref Graph!32 graph) {
		this.graph = graph;
	}

	static void makeArrayUnique(ref Array!int notUnique, ref Array!int unique) {
		Bitset!uint set;
		foreach(it; notUnique) {
			if(!set.test(it)) {
				unique.insertBack(it);
				set.set(it);
			}
		}
	}

	static void calcDiagonalPairs(ref Array!int bottom, ref Array!int top,
		ref Array!int left, ref Array!int right, 
		ref Array!(int[2]) diagonalPairs)
	{
		{
			auto tl = bitset!uint(bitset!uint(top).store & bitset!uint(left).store);
			auto br = bitset!uint(bitset!uint(bottom).store & bitset!uint(right).store);

			for(size_t a; a < tl.size(); ++a) {
				if(tl.test(a)) {
					for(size_t b; b < br.size(); ++b) {
						if(br.test(b)) {
							diagonalPairs.insertBack(cast(int[2])([a, b]));
						}
					}
				}
			}
		}

		{
			auto tr = bitset!uint(bitset!uint(top).store & bitset!uint(right).store);
			auto bl = bitset!uint(bitset!uint(bottom).store & bitset!uint(left).store);
			for(size_t a; a < tr.size(); ++a) {
				if(tr.test(a)) {
					for(size_t b; b < bl.size(); ++b) {
						if(bl.test(b)) {
							diagonalPairs.insertBack(cast(int[2])([a, b]));
						}
					}
				}
			}
		}
	}

	void splitBorderIntoTBLR(ref Array!int bottom, ref Array!int top,
		ref Array!int left, ref Array!int right, 
		ref Array!(int[2]) diagonalPairs)
	{
		import std.algorithm.iteration : sum;
		import std.math;
		Array!int border = this.graph.computeBorder();
		auto borderSet = bitset!uint(border);

		Array!(int)*[4] store;
		store[0] = &left;
		store[1] = &top;
		store[2] = &right;
		store[3] = &bottom;

		Array!int uniqueBorder;
		makeArrayUnique(border, uniqueBorder);
		const len = uniqueBorder.length + 4;
		//logf("[%(%s, %)] len(%s) %s", uniqueBorder[], len, len / 4.0);

		long[4] setCount;
		setCount[0] = lrint(floor(len / 4.0));
		setCount[1] = lrint(floor((len - setCount[0 .. 1].sum()) / 3.0));
		setCount[2] = lrint(floor((len - setCount[0 .. 2].sum()) / 2.0));
		setCount[3] = len - setCount[0 .. 3].sum();

		//logf("[%(%s, %)]", setCount[]);

		for(int i = 0; i < store.length; ++i) {
			long startIdx = i == 0 ? 0 : setCount[0 .. i].sum() - i;
			//logf("startIdx %s uniqueBorder.length(%s)", startIdx,
			//		uniqueBorder.length
			//);
			for(int j = 0; j < setCount[i]; ++j) {
				//logf("j %s", j);
				(*store[i]).insertBack(
					uniqueBorder[(startIdx + j) % uniqueBorder.length]
				);
			}
		}

		calcDiagonalPairs(bottom, top, left, right, diagonalPairs);
		//logf("lft [%(%s %)] tp [%(%s %)] rght[%(%s %)] btm [%(%s %)] dia [%(%s, %)]",
		//	left[], top[], right[], bottom[], diagonalPairs[]
		//);
	}

	Result calcAC() {
		import std.conv : to;
		import protocols.pathbased;

		//Array!int bottom;
		//Array!int top;
		//Array!int left;
		//Array!int right;
		//Array!(int[2]) diagonalPairs;
		this.splitBorderIntoTBLR(this.bottom, this.top, this.left, this.right,
				this.diagonalPairs);

		auto paths = floyd!32(this.graph);

		const uint numNodes = to!uint(this.graph.length);
		auto ret = calcACforPathBased(paths, this.graph, bottom, top, left, right,
			diagonalPairs, this.read, this.write, numNodes
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
		return format("Crossing-%s", this.graph.length);
	}

	auto ref getGraph() {
		return this.graph;
	}
}

unittest {
	auto g = genTestGraph!32();
	auto c = Crossing(g);

	Array!int bottom;
	Array!int top;
	Array!int left;
	Array!int right;
	Array!(int[2]) diagonal;

	c.splitBorderIntoTBLR(bottom, top, left, right, diagonal);
}

module protocols.crossing;

import std.experimental.logger;
import std.stdio;
import std.typecons : Flag;
import std.math : approxEqual;
import std.container.array : Array;

import gfm.math.vector;

import bitsetrbtree;
import bitsetmodule;
import graph;
import protocols;

struct Crossings {
	Crossing bestCrossing;
	Result bestResult;
	double bestSum;

	Graph!32 graph;

	this(ref Graph!32 graph) {
		this.graph = graph;
		this.bestSum = 0.0;
	}

	static double sumResult(ref Result curRslt, const double writeBalance = 0.5) {
		import utils : sum;

		return sum(curRslt.writeAvail)  * writeBalance + 
			sum(curRslt.readAvail) * 1.0 - writeBalance;
	}

	@property ref BitsetStore!uint read() {
		return this.bestCrossing.read;
	}

	@property ref BitsetStore!uint write() {
		return this.bestCrossing.write;
	}

	Result calcAC() {
		import std.algorithm.mutation : bringToFront;
		Array!int border = this.graph.computeBorder();
		Array!int uniqueBorder;
		makeArrayUnique(border, uniqueBorder);
		bringToFront(uniqueBorder[0 .. 1], uniqueBorder[1 .. $]);

		for(int i = 0; i < uniqueBorder.length; ++i) {
			//logf("[%(%s, %)]", uniqueBorder[]);
			if(i == 0) {
				this.bestCrossing = Crossing(this.graph);
				this.bestResult = this.bestCrossing.calcAC(uniqueBorder);
				this.bestSum = sumResult(this.bestResult);
				logf("%f", this.bestSum);
			} else {
				auto tmp = Crossing(this.graph);
				auto tmpRslt = tmp.calcAC(uniqueBorder);
				double tmpSum = sumResult(tmpRslt);

				logf("%f %f", this.bestSum, tmpSum);

				if(tmpSum > this.bestSum) {
					this.bestCrossing = tmp;
					this.bestResult = tmpRslt;
					this.bestSum = tmpSum;
				}
			}
			bringToFront(uniqueBorder[0 .. 1], uniqueBorder[1 .. $]);
		}

		return this.bestResult;
	}

	string name() const pure {
		import std.format : format;
		return format("Crossings-%s", this.graph.length);
	}

	auto ref getGraph() {
		return this.graph;
	}
}

struct Crossing {
	import core.bitop : popcnt;
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

	void splitBorderIntoTBLR(ref Array!int uniqueBorder, ref Array!int bottom, 
		ref Array!int top, ref Array!int left, ref Array!int right, 
		ref Array!(int[2]) diagonalPairs)
	{
		import std.algorithm.iteration : sum;
		import std.math;
		Array!(int)*[4] store;
		store[0] = &left;
		store[1] = &top;
		store[2] = &right;
		store[3] = &bottom;

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
	}

	Result calcAC(ref Array!int uniqueBorder) {
		import std.conv : to;
		import protocols.pathbased;

		this.splitBorderIntoTBLR(uniqueBorder, this.bottom, this.top, this.left, 
				this.right, this.diagonalPairs);
		logf("lft [%(%s %)] tp [%(%s %)] rght[%(%s %)] btm [%(%s %)] dia [%(%s, %)]",
			this.left[], this.top[], this.right[], this.bottom[], this.diagonalPairs[]
		);
		testEmptyIntersection(this.top, this.bottom);
		testEmptyIntersection(this.left, this.right);
		testEmptyIntersection(this.diagonalPairs);

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

	Result calcAC() {
		Array!int border = this.graph.computeBorder();
		Array!int uniqueBorder;
		makeArrayUnique(border, uniqueBorder);
		return this.calcAC(uniqueBorder);
	}

	string name() const pure {
		import std.format : format;
		return format("Crossing-%s", this.graph.length);
	}

	auto ref getGraph() {
		return this.graph;
	}
}

void makeArrayUnique(ref Array!int notUnique, ref Array!int unique) {
	Bitset!uint set;
	foreach(it; notUnique) {
		if(!set.test(it)) {
			unique.insertBack(it);
			set.set(it);
		}
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
	auto border = g.computeBorder();

	c.splitBorderIntoTBLR(border, bottom, top, left, right, 
			diagonal
	);
}

unittest {
	import std.algorithm.mutation : bringToFront;
	import exceptionhandling;

	auto arr = Array!int([0,1,2,3]);
	bringToFront(arr[0 .. 1], arr[1 .. $]);
	//assertEqual(arr[], [1,2,3,0]);
}

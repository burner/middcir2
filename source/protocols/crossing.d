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

struct CrossingsConfig {
	int sumStart;
	int sumStop;
}

alias Crossings = CrossingsImpl!32;

struct CrossingsImpl(int Size) {
	alias BSType = TypeFromSize!Size;

	CrossingImpl!Size bestCrossing;
	Result bestResult;
	double bestSum;

	Graph!Size graph;

	CrossingsConfig config;

	this(ref Graph!Size graph) {
		this(graph, CrossingsConfig(0, 101));
	}

	this(ref Graph!Size graph, CrossingsConfig cc) {
		this.graph = graph;
		this.bestSum = 0.0;
		this.config = cc;
	}

	double sumResult(ref Result curRslt, const double writeBalance = 0.5) const 
	{
		import utils : sum;

		return 
			sum(
				curRslt.writeAvail[this.config.sumStart ..  this.config.sumStop]
			)  * writeBalance 
			+ sum(
				curRslt.readAvail[this.config.sumStart ..  this.config.sumStop]
			) * 1.0 - writeBalance;
	}

	@property ref BitsetStore!BSType read() {
		return this.bestCrossing.read;
	}

	@property ref BitsetStore!BSType write() {
		return this.bestCrossing.write;
	}

	Result calcAC() {
		import std.algorithm.mutation : bringToFront;
		Array!int border = this.graph.computeBorder();
		Array!int uniqueBorder;

		makeArrayUnique!BSType(border, uniqueBorder);
		bringToFront(uniqueBorder[0 .. 1], uniqueBorder[1 .. $]);

		for(int i = 0; i < uniqueBorder.length; ++i) {
			//logf("[%(%s, %)]", uniqueBorder[]);
			if(i == 0) {
				this.bestCrossing = CrossingImpl!Size(this.graph);
				this.bestResult = this.bestCrossing.calcAC(uniqueBorder);
				this.bestSum = sumResult(this.bestResult);
				logf("%f", this.bestSum);
			} else {
				auto tmp = CrossingImpl!Size(this.graph);
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

alias Crossing = CrossingImpl!32;

struct CrossingImpl(int Size) {
	import core.bitop : popcnt;
	import floydmodule;
	import bitfiddle;
	import utils : removeAll, testQuorumIntersection, testAllSubsetsSmaller;

	alias BSType = TypeFromSize!Size;

	BitsetStore!BSType read;
	BitsetStore!BSType write;

	Array!int bottom;
	Array!int top;
	Array!int left;
	Array!int right;
	Array!(int[2]) diagonalPairs;

	Graph!Size graph;

	this(ref Graph!Size graph) {
		this.graph = graph;
	}

	static void calcDiagonalPairs(ref Array!int bottom, ref Array!int top,
		ref Array!int left, ref Array!int right, 
		ref Array!(int[2]) diagonalPairs)
	{
		{
			auto tl = bitset!BSType(bitset!BSType(top).store & bitset!BSType(left).store);
			auto br = bitset!BSType(bitset!BSType(bottom).store & bitset!BSType(right).store);

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
			auto tr = bitset!BSType(bitset!BSType(top).store & bitset!BSType(right).store);
			auto bl = bitset!BSType(bitset!BSType(bottom).store & bitset!BSType(left).store);
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
				(*store[cast(size_t)i]).insertBack(
					uniqueBorder[cast(size_t)((startIdx + j) % uniqueBorder.length)]
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

		auto paths = floyd(this.graph);

		const uint numNodes = to!uint(this.graph.length);
		auto ret = calcACforPathBased!BSType(paths, this.graph, bottom, top, left, right,
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
		makeArrayUnique!BSType(border, uniqueBorder);
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

void makeArrayUnique(BSType)(ref Array!int notUnique, ref Array!int unique) {
	Bitset!BSType set;
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

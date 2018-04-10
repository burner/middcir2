module protocols.crossing;

import std.experimental.logger;
import std.stdio;
import std.typecons : Flag;
import std.math : approxEqual;
import std.container.array : Array;

import gfm.math.vector;

import fixedsizearray;
import exceptionhandling;

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
		import planar;
		bool atLeastOne = false;
		Array!(Graph!Size) planarGraphs;
		makePlanar(this.graph, planarGraphs);
		logf("%s planar graphs", planarGraphs.length);
		size_t itCnt = 0;
		foreach(it; planarGraphs[]) {
			Array!(TBLR) tblrSets = possibleBorders(it);
			logf("%s possible borders", tblrSets.length);
			for(int i = 0; i < tblrSets.length; ++i) {
				if(i == 0) {
					atLeastOne = true;
					this.bestCrossing = CrossingImpl!Size(this.graph);
					this.bestResult = this.bestCrossing.calcAC(tblrSets[i]);
					this.bestSum = sumResult(this.bestResult, 0.99999);
					logf("%f", this.bestSum);
				} else {
					auto tmp = CrossingImpl!Size(this.graph);
					auto tmpRslt = tmp.calcAC(tblrSets[i]);
					double tmpSum = sumResult(tmpRslt);

					logf("%f %f tblrSet %s of %s planarGraph %s of %s", this.bestSum, tmpSum, i,
							tblrSets.length, itCnt, planarGraphs.length
						);

					if(tmpSum > this.bestSum) {
						this.bestCrossing = tmp;
						this.bestResult = tmpRslt;
						this.bestSum = tmpSum;
					}
				}
			}
			++itCnt;
		}
		ensure(atLeastOne);
		logf("lft [%(%s %)] tp [%(%s %)] rght[%(%s %)] btm [%(%s %)] dia [%(%s, %)]",
			this.bestCrossing.left[], this.bestCrossing.top[], this.bestCrossing.right[],
			this.bestCrossing.bottom[], this.bestCrossing.diagonalPairs[]
		);
		return this.bestResult;
	}

	Result calcACOld() {
		import std.algorithm.mutation : bringToFront;
		Array!int border = this.graph.computeBorder();
		Array!int uniqueBorder;

		makeArrayUnique!BSType(border, uniqueBorder);
		bringToFront(uniqueBorder[0 .. 1], uniqueBorder[1 .. $]);

		for(int i = 0; i < uniqueBorder.length; ++i) {
			//logf("[%(%s, %)]", uniqueBorder[]);
			if(i == 0) {
				this.bestCrossing = CrossingImpl!Size(this.graph);
				this.bestResult = this.bestCrossing.calcACOld(uniqueBorder);
				this.bestSum = sumResult(this.bestResult);
				logf("%f", this.bestSum);
			} else {
				auto tmp = CrossingImpl!Size(this.graph);
				auto tmpRslt = tmp.calcACOld(uniqueBorder);
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

	Result calcAC(ref TBLR tblr) {
		import std.conv : to;
		import protocols.pathbased;

		this.top = tblr.top;
		this.bottom = tblr.bottom;
		this.left = tblr.left;
		this.right = tblr.right;
		this.diagonalPairs = tblr.diagonalPairs;

		//this.splitBorderIntoTBLR(uniqueBorder, this.bottom, this.top, this.left, 
		//		this.right, this.diagonalPairs);
		logf("lft [%(%s %)] tp [%(%s %)] rght[%(%s %)] btm [%(%s %)] dia [%(%s, %)]",
			tblr.left[], tblr.top[], tblr.right[], tblr.bottom[], tblr.diagonalPairs[]
		);
		//logf("top bottom");
		testEmptyIntersection(tblr.top, tblr.bottom);
		//logf("left right");
		testEmptyIntersection(tblr.left, tblr.right);
		//logf("diagonal");
		testEmptyIntersection(tblr.diagonalPairs);
		//logf("done");

		auto paths = floyd(this.graph);

		const uint numNodes = to!uint(this.graph.length);
		auto ret = calcACforPathBased!(typeof(this.read),BSType)(paths, 
			this.graph, tblr.bottom, tblr.top, tblr.left, tblr.right,
			tblr.diagonalPairs, this.read, this.write, numNodes
		);

		bool test;
		debug {
			test = true;
		}
		version(unittest) {
			test = true;
		}
		if(test) {
			logf("quorum intersection read write");
			testQuorumIntersection(this.read, this.write);
			logf("quorum intersection write write");
			testQuorumIntersection(this.write, this.write);
			//logf("all subsets smaller");
			testAllSubsetsSmaller(this.read, this.write);
		}
		//bool seme = true;
		//try {
		//	import utils;
		//	testSemetry(ret);
		//} catch(Exception e) {
		//	seme = false;
		//}
		//logf("%s", seme ? "semetric" : "non-semetric");

		return ret;
	}

	Result calcACOld(ref Array!int uniqueBorder) {
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
		auto ret = calcACforPathBased!(typeof(this.read),BSType)(paths, 
			this.graph, bottom, top, left, right,
			diagonalPairs, this.read, this.write, numNodes
		);

		bool test = true;
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

	/*Result calcAC() {
		Array!int border = this.graph.computeBorder();
		Array!int uniqueBorder;
		makeArrayUnique!BSType(border, uniqueBorder);
		return this.calcAC(uniqueBorder);
	}*/

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

void splitOutN(S,D)(ref S src, ref D dest, int offset, int count) {
	int mod(int a, int b) {
	    int r = a % b;
	    return r < 0 ? r + b : r;
	}
	const int srcL = cast(int)src.length;
	//logf("offset %s, count %s, src.length %s", offset, count, src.length);
	for(int i = 0; i < count; ++i) {
		int m = mod((i + offset), srcL);
		//logf("%s %s", i, m);
		dest.insertBack(src[m]);
	}
}

struct TBLR {
	Array!(int) top;
	Array!(int) left;
	Array!(int) bottom;
	Array!(int) right;
	Array!(int[2]) diagonalPairs;

	bool opEquals(const ref typeof(this) other) const {
		return cmpFSA(this.top, other.top)
			&& cmpFSA(this.left, other.left)
			&& cmpFSA(this.bottom, other.bottom)
			&& cmpFSA(this.right, other.right);
	}
}

/*void computeDiagonalPairs(ref TBLR tblr) {
	import std.algorithm.searching : canFind;
	for(int t = 0; t < tblr.top.length; ++t) {
		for(int l = 0; l < tblr.left.length; ++l) {
			if(tblr.top[t] == tblr.left[l]) {
				for(int b = 0; b < tblr.bottom.length; ++b) {
					for(int r = 0; r < tblr.right.length; ++r) {
						if(tblr.bottom[b] == tblr.right[r]) {
							int[2] tmp = cast(int[2])([tblr.top[t], tblr.bottom[b]]);
							if(!canFind(tblr.diagonalPairs[], tmp)) {
								tblr.diagonalPairs.insertBack(tmp);
							}
						}
					}
				}
			}
		}
	}
	for(int t = 0; t < tblr.top.length; ++t) {
		for(int r = 0; r < tblr.right.length; ++r) {
			if(tblr.top[t] == tblr.right[r]) {
				for(int b = 0; b < tblr.bottom.length; ++b) {
					for(int l = 0; l < tblr.left.length; ++l) {
						if(tblr.bottom[b] == tblr.left[l]) {
							int[2] tmp = cast(int[2])([tblr.top[t], tblr.bottom[b]]);
							if(!canFind(tblr.diagonalPairs[], tmp)) {
								tblr.diagonalPairs.insertBack(tmp);
							}
						}
					}
				}
			}
		}
	}
}*/

void computeDiagonalPairs(ref TBLR tblr) {
	import std.algorithm.searching : canFind;
	foreach(t; tblr.top[]) {
		foreach(l; tblr.left[]) {
			if(t == l) {
				foreach(b; tblr.bottom[]) {
					foreach(r; tblr.right[]) {
						if(b == r) {
							ensure(t == l);
							ensure(b == r);
							int[2] tmp = cast(int[2])([t, b]);
							ensure(tmp[0] == t);
							ensure(tmp[1] == b);
							if(!canFind(tblr.diagonalPairs[], tmp)) {
								tblr.diagonalPairs.insertBack(tmp);
							}
						}
					}
				}
			}
		}
	}
	foreach(t; tblr.top[]) {
		foreach(r; tblr.right[]) {
			if(t == r) {
				foreach(b; tblr.bottom[]) {
					foreach(l; tblr.left[]) {
						if(b == l) {
							ensure(t == r);
							ensure(b == l);
							int[2] tmp = cast(int[2])([t, b]);
							ensure(tmp[0] == t);
							ensure(tmp[1] == b);
							if(!canFind(tblr.diagonalPairs[], tmp)) {
								tblr.diagonalPairs.insertBack(tmp);
							}
						}
					}
				}
			}
		}
	}
}

Array!int intersection(A)(auto ref A a, auto ref A b) {
	Array!int ret;
	foreach(it; a[]) {
		foreach(jt; b[]) {
			if(it == jt) {
				ret.insertBack(it);
			}
		}
	}
	return ret;
}

private bool cmpFSA(F)(auto ref F a, auto ref F b) {
	if(a.length != b.length) {
		return false;
	}

	for(size_t i = 0; i < a.length; ++i) {
		if(a[i] != b[i]) {
			return false;
		}
	}
	return true;
}

void computeDiagonalPairs2(ref TBLR tblr, ref Array!int tl, ref Array!int br,
		ref Array!int tr, ref Array!int bl)
{
	//ensure(tl.length == 1);
	//ensure(tr.length == 1);
	//ensure(bl.length == 1);
	//ensure(br.length == 1);

	foreach(tlIt; tl[]) {
		foreach(brIt; br[]) {
			tblr.diagonalPairs.insertBack(cast(int[2])([tlIt, brIt]));
		}
	}
	foreach(trIt; tr[]) {
		foreach(blIt; bl[]) {
			tblr.diagonalPairs.insertBack(cast(int[2])([trIt, blIt]));
		}
	}
}

Array!(TBLR) possibleBorders(G)(auto ref G graph) {
	import std.conv : to;
	import std.algorithm.searching : canFind;
	import protocols.pathbased;
	Array!(TBLR) ret;
	Array!int border = graph.computeBorder();
	Array!int uniqueBorder;
	makeArrayUnique!uint(border, uniqueBorder);

	const size_t len = uniqueBorder.length;
	const int lenT = cast(int)(len);
	logf("len %s, lenT %s", len, lenT);
	for(int t = 0; t < lenT; ++t) {
		TBLR tblr;
		logf("t %s", t);
		for(int tl = 1; tl < lenT; ++tl) {
			logf("tl %s", tl);
			tblr.top.clear();
			splitOutN(uniqueBorder, tblr.top, t, tl);
			ensure(tblr.top.length > 0);
			for(int l = 0; l < lenT; ++l) {
				//logf("l %s", l);
				for(int ll = 1; ll < lenT; ++ll) {
					//logf("ll %s", ll);
					tblr.left.clear();
					splitOutN(uniqueBorder, tblr.left, l, ll);
					ensure(tblr.top.length > 0);
					ensure(tblr.left.length > 0);
					bool tlNE = testNonEmptyIntersection2(tblr.top, tblr.left);
					if(!tlNE) {
						//logf("t [%20(%s %)], l [%20(%s %)], b [%20(%s %)], r [%20(%s %)]",
						//		tblr.top[], tblr.left[], tblr.bottom[], tblr.right[]
						//	);
						continue;
					}
					for(int b = 0; b < lenT; ++b) {
						//logf("b %s", b);
						for(int bl = 1; bl < lenT; ++bl) {
							//logf("bl %s", bl);
							tblr.bottom.clear();
							splitOutN(uniqueBorder, tblr.bottom, b, bl);
							ensure(tblr.top.length > 0);
							ensure(tblr.left.length > 0);
							ensure(tblr.bottom.length > 0);
							bool tbE = testEmptyIntersection2(tblr.top, tblr.bottom);
							if(!tbE) {
								//logf("t [%20(%s %)], l [%20(%s %)], b [%20(%s %)], r [%20(%s %)]",
								//		tblr.top[], tblr.left[], tblr.bottom[], tblr.right[]
								//	);
								continue;
							}

							bool blNE = testNonEmptyIntersection2(tblr.bottom, tblr.left);
							if(!blNE) {
								//logf("t [%20(%s %)], l [%20(%s %)], b [%20(%s %)], r [%20(%s %)]",
								//		tblr.top[], tblr.left[], tblr.bottom[], tblr.right[]
								//	);
								continue;
							}
							for(int r = 0; r < lenT; ++r) {
								//logf("r %s", r);
								for(int rl = 1; rl < lenT; ++rl) {
									//logf("rl %s", rl);
									tblr.right.clear();
									splitOutN(uniqueBorder, tblr.right, r, rl);
									ensure(tblr.top.length > 0);
									ensure(tblr.left.length > 0);
									ensure(tblr.bottom.length > 0);
									ensure(tblr.right.length > 0);
									//log();
									bool lrE = testEmptyIntersection2(tblr.left, tblr.right);
									if(!lrE) {
									//	logf("t [%20(%s %)], l [%20(%s %)], b [%20(%s %)], r [%20(%s %)]",
									//			tblr.top[], tblr.left[], tblr.bottom[], tblr.right[]
									//		);
										continue;
									}
									bool trNE = testNonEmptyIntersection2(tblr.top, tblr.right);
									if(!trNE) {
									//	logf("t [%20(%s %)], l [%20(%s %)], b [%20(%s %)], r [%20(%s %)]",
									//			tblr.top[], tblr.left[], tblr.bottom[], tblr.right[]
									//		);
										continue;
									}
									bool brNE = testNonEmptyIntersection2(tblr.bottom, tblr.right);
									if(!brNE) {
									//	logf("t [%20(%s %)], l [%20(%s %)], b [%20(%s %)], r [%20(%s %)]",
									//			tblr.top[], tblr.left[], tblr.bottom[], tblr.right[]
									//		);
										continue;
									}

									Array!int tlI = intersection(tblr.top, 
											tblr.left
										);
									if(tlI.length > 1) {
										continue;
									}

									Array!int trI = intersection(tblr.top, 
											tblr.right
										);
									if(trI.length > 1) {
										continue;
									}

									Array!int blI = intersection(tblr.bottom, 
											tblr.left
										);
									if(blI.length > 1) {
										continue;
									}

									Array!int brI = intersection(tblr.bottom, 
											tblr.right
										);
									if(brI.length > 1) {
										continue;
									}

									if(canFind(ret[], tblr)) {
										//logf("already present");
									} else {
										logf("new");
										logf("t [%20(%s %)], l [%20(%s %)], b [%20(%s %)], r [%20(%s %)]",
												tblr.top[], tblr.left[], tblr.bottom[], tblr.right[]
											);
								
										logf("tbE %s lrE %s tlNE %s trNE %s blNE %s brNE %s",
												tbE, lrE, tlNE, trNE, blNE, brNE
											);
										tblr.diagonalPairs.clear();
										computeDiagonalPairs2(tblr, tlI, brI,
												trI, blI
											);
										ret.insert(tblr);
									}
								}
							}
						}
					}
				}
			}
		}
	}
	logf("ret.size %s", ret.length);
	return ret;
}

/+Array!(TBLR) possibleBorders(G)(auto ref G graph) {
	import std.conv : to;
	import std.algorithm.searching : canFind;
	import protocols.pathbased;
	Array!(TBLR) ret;
	Array!int border = graph.computeBorder();
	Array!int uniqueBorder;
	makeArrayUnique!uint(border, uniqueBorder);

	const size_t len = uniqueBorder.length;
	const int lenT = cast(int)(len) - 2;
	for(int t = 1; t < lenT; ++t) {
		const int lenL = cast(int)(len) - t - 1;
		for(int l = 1; l < lenL; ++l) {
			const int lenB = cast(int)(len) - t - l - 0;
			for(int b = 1; b < lenB; ++b) {
				const int r = to!int(len - t - l - b) + 1;
				logf("%(%s %)", uniqueBorder[]);
				/*logf("len %2s, lenT %2s, lenL %2s, lenB %2s, sum"
						~ " %2s, t %2s, l %2s, b %2s, r %2s", 
						len, lenT, lenL, lenB, t + l + b + r,
						t, l, b, r
					);*/

				//const int l2 = cast(int)(uniqueBorder.length) / 2;
				//for(int tl = 1; tl < l2; ++tl) {
				//	for(int bl = 1; bl < l2; ++bl) {
				//		for(int ll = 1; ll < l2; ++ll) {
				//			for(int rl = 1; rl < l2; ++rl) {
								TBLR tblr;

								//splitOutN(uniqueBorder, tblr.top, 0 - 1, t + tl);
								//splitOutN(uniqueBorder, tblr.left, t - 1, l + ll);
								//splitOutN(uniqueBorder, tblr.bottom, t + l - 1, b + bl);
								//splitOutN(uniqueBorder, tblr.right, t + l + b - 1, r + rl);
								splitOutN(uniqueBorder, tblr.top, 0 - 1, t);
								splitOutN(uniqueBorder, tblr.left, t - 2, l + 1);
								splitOutN(uniqueBorder, tblr.bottom, t + l - 2, b + 1);
								splitOutN(uniqueBorder, tblr.right, t + l + b - 2, r + 1);

								logf("t [%20(%s %)], l [%20(%s %)], b [%20(%s %)], r [%20(%s %)]",
										tblr.top[], tblr.left[], tblr.bottom[], tblr.right[]
									);
								
								bool tbE = testEmptyIntersection2(tblr.top, tblr.bottom);
								bool lrE = testEmptyIntersection2(tblr.left, tblr.right);
								bool tlNE = testNonEmptyIntersection2(tblr.top, tblr.left);
								bool trNE = testNonEmptyIntersection2(tblr.top, tblr.right);
								bool blNE = testNonEmptyIntersection2(tblr.bottom, tblr.left);
								bool brNE = testNonEmptyIntersection2(tblr.bottom, tblr.right);

								logf("tbE %s lrE %s tlNE %s trNE %s blNE %s brNE %s",
										tbE, lrE, tlNE, trNE, blNE, brNE
									);
								if(tbE && lrE && tlNE && trNE && blNE && brNE) {
									//logf("ok");
									if(canFind(ret[], tblr)) {
										//logf("already present");
									} else {
										//logf("new");
										computeDiagonalPairs(tblr);
										ret.insert(tblr);
									}
								}
				//			}
				//		}
				//	}
				//}
			}
		}
	}
	//logf("ret.size %s", ret.length);
	return ret;
}+/

unittest {
	auto g = genTestGraph!32();
	auto borders = possibleBorders(g);
	logf("%s", borders.length);
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

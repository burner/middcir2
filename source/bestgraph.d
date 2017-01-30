module bestgraph;

import std.math : sqrt;
import std.conv : to;
import std.experimental.logger;

import gfm.math.vector;

import graph;
import planar;

/**
For size N = 16 build
x x x x x x x : 7   0 1 2 3 4 5 6
  x x x x x x : 6     7 8 9101112
    x x x x x : 5      1314151617
      x x x x : 4        18182021 

x x x x x x x x x 0 1 2 3 4 5 6 7 8 : 9
  x x x x x x x x   910111213141516 : 8
    x x x x x x x     x x x x x x x : 7
      x x x x x x       x x x x x x : 6
        x x x x x         x x x x x : 5
          x x x x           x x x x : 4
            x x x             x x x : 3
              x x               x x : 2

*/
Graph!Size findBestLNT(int Size,CMP)(auto ref Graph!Size old, auto ref CMP cmp)
{
	const nn = old.length;
	Graph!Size cur = old.dup;
} 

Graph!Size cmpEdgeIntersectionsCnt(int Size)(auto ref Graph!Size a,
		auto ref Graph!Size b)
{
	const size_t aCnt = countEdgeIntersections(a);
	const size_t bCnt = countEdgeIntersections(b);

	return aCnt < bCnt ? a : b;
}

struct EdgeCmp(int Size) {
	import math;
	size_t bestCnt;
	Graph!Size original;
	Graph!Size best;

	this(Graph!Size ori) {
		this.original = ori;
		this.bestCnt = countEdgeIntersections(this.original);
	}

	void run() {
		import std.stdio;
		import std.algorithm.sorting : nextPermutation;
		const len = this.original.length;

		vec3d[] pos = buildPosArray(len);
		ubyte[] idx = buildIndexArray(len);

		ulong cnt;
		ulong upto = factorial(pos.length);
		auto s = idx[];
		do {
			++cnt;
			logf(cnt % 500000 == 0, "%d %d %f", cnt, upto, cast(double)cnt / upto);

			auto ng = Graph!Size(cast(int)len);
			for(ulong i = 0; i < len; ++i) {
				ng.setAdjancy(i, this.original.getAdjancy(i));
			}
			for(ulong i = 0; i < len; ++i) {
				//writef("%2.1f %2.1f|", pos[s[i]].x, pos[s[i]].y);
				ng.setNodePos(i, vec3d(pos[s[i]].x, pos[s[i]].y, 0.0));
			}
			auto ec = countEdgeIntersections(ng);
			writefln("%4d %4d", this.bestCnt, ec);
			if(ec < this.bestCnt) {
				this.best = ng;
				this.bestCnt = ec;
				for(ulong i = 0; i < len; ++i) {
					writef("%2.1f %2.1f|", pos[s[i]].x, pos[s[i]].y);
				}
				writefln(" %s", ec);
			}
			if(this.bestCnt == 0) {
				logf("found a perfect one with zero intersections");
				break;
			}
		} while(nextPermutation(s));
	}
}

unittest {
	/*auto g = genTestGraph!16();

	auto lnt = findBestLNT(g, cmpEdgeIntersectionsCnt);
	*/

	logf("array size %s", buildIndexArray(16));
}

ubyte[] buildIndexArray(const size_t len) {
	import std.range : iota;
	import std.array : array;
	import std.conv : to;

	const size_t sq = to!size_t(sqrt(cast(double)len) + 0.5);
	//size_t cnt = sq * sq;
	size_t cnt;

	for(size_t i = (sq * 2) - 1; i >= sq; --i) {
		cnt += i;
	}

	return to!(ubyte[])(iota(0,cnt).array());
}

vec3d[] buildPosArray(const size_t len) {
	const size_t sq = to!size_t(sqrt(cast(double)len) + 0.5);
	size_t cnt;

	for(size_t i = (sq * 2) - 1; i >= sq; --i) {
		cnt += i;
	}

	auto ret = new vec3d[cnt];
	float y = 0.0;

	int idx = 0;
	for(size_t i = (sq * 2) - 1; i >= sq; --i) {
		for(size_t j = 0; j < i; ++j) {
			logf("x %s y %s", cast(float)j, y);
			ret[idx++] = vec3d(cast(float)j,y,0.0);
		}
		y += 1.0;
	}

	return ret;
}

unittest {
	auto g = makeNine2!16();
	auto ec = EdgeCmp!16(g);
	ec.run();
}

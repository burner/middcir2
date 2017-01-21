module bestgraph;

import std.math : sqrt;
import std.conv : to;
import std.experimental.logger;

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

ubyte[] buildIndexArray(const size_t len) {
	import std.range : iota;
	import std.array : array;
	const size_t sq = to!size_t(sqrt(cast(double)len) + 0.5);
	size_t cnt = sq * sq;

	for(size_t i = (sq * 2) - 1; i > sq; --i) {
		cnt += i;
	}

	return to!(ubyte[])(iota(0,cnt).array());
}

Graph!Size cmpEdgeIntersectionsCnt(int Size)(auto ref Graph!Size a,
		auto ref Graph!Size b)
{
	const size_t aCnt = countEdgeIntersections(a);
	const size_t bCnt = countEdgeIntersections(b);

	return aCnt < bCnt ? a : b;
}

unittest {
	/*auto g = genTestGraph!16();

	auto lnt = findBestLNT(g, cmpEdgeIntersectionsCnt);
	*/

	logf("array size %s", buildIndexArray(16));
}

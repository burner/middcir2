module numbergraphs;

import std.experimental.logger;

import graph;
import bitsetmodule;

Graph!Size numberToGraph(int Size = 64)(ulong num, ulong graphSize) {
	Graph!Size ret = Graph!Size(cast(int)graphSize);

	int l = 0;
	for(; graphSize > 1; --graphSize, ++l) {
		auto bs = Bitset!ulong(num);
		for(size_t i = 0; i < graphSize; ++i) {
			logf("%s %s %s",l, i, bs.toString());
			if(bs.test(i)) {
				int r = cast(int)i;
				r += l + 1;
				logf("inserted %s %s", l, r);
				ret.setEdge(l, r);
			}
		}
		logf("%s", Bitset!(ulong)(num).toString());
		num = num >>> graphSize;
		logf("%s", Bitset!(ulong)(num).toString());
	}

	return ret;
}

unittest {
	import floydmodule;
	auto g = numberToGraph(0b1_01_001_0001, 4);
	logf("\n%s", g.toString());
	assert(isConnected(g), g.toString());

	auto fl = floyd(g);
}

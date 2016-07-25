module mapping;

import graph;

struct Mapping(int Size) {
	const(Graph!Size)* lnt;	
	const(Graph!Size)* pnt;	

	this(ref Graph!Size lnt, ref Graph!Size pnt) {
		this.lnt = &lnt;
		this.pnt = &pnt;
	}
}

unittest {
	auto lnt = Graph!16();
	auto pnt = Graph!16();
	auto map = Mapping!16(lnt, pnt);
}

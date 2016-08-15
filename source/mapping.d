module mapping;

import std.conv : to;
import std.experimental.logger;

import gfm.math.vector;

import graph;
import bitsetrbtree;
import bitsetmodule;
import protocols;
import floydmodule;

/** Mapping will be passed a BitsetStore. It will take this BitsetStore and
for each element it will try to reconnect the element for every permutation.
*/
struct Mapping(int SizeLnt, int SizePnt) {
	const(Graph!SizeLnt)* lnt;	
	const(Graph!SizePnt)* pnt;	
	const(int[]) mapping;
	const uint upTo;
	Floyd floyd;

	BitsetStore!uint read;
	BitsetStore!uint write;

	this(ref Graph!SizeLnt lnt, ref Graph!SizePnt pnt, int[] mapping) {
		this.lnt = &lnt;
		this.pnt = &pnt;
		this.mapping = mapping;
		this.upTo = to!uint(1 << this.lnt.length);
		this.floyd.init(*this.pnt);
	}

	void reconnectQuorum(ref const(Bitset!uint) quorum, 
			ref BitsetStore!uint rsltQuorumSet)
	{
		for(uint perm = 0; perm < upTo; ++perm) {
			floyd.initArrays(*this.pnt, bitset(perm));
		}
	}

	void reconnectQuorums(ref BitsetStore!uint quorumSet, 
			ref BitsetStore!uint rsltQuorumSet)
	{
		foreach(ref it; quorumSet[]) {
			this.reconnectQuorum(it.bitset, rsltQuorumSet);
			foreach(ref sub; it.subsets[]) {
				this.reconnectQuorum(sub, rsltQuorumSet);
			}
		}
	}

	/**
	oRead = Original Read
	oWrite = Original Write
	*/
	Result calcAC(ref BitsetStore!uint oRead, ref BitsetStore!uint oWrite) {
		this.reconnectQuorums(oRead, this.read);
		this.reconnectQuorums(oWrite, this.write);

		return calcAvailForTree(to!int(this.lnt.length), this.read, this.write);
	}
}

unittest {
	auto lnt = Graph!16();
	auto pnt = Graph!16();
	auto map = Mapping!(16,16)(lnt, pnt, [0,2,1,3,5,4]);
}

unittest {
	import protocols.lattice;
	auto lnt = Lattice(2,2);
	auto pnt = makeLineOfFour();

	auto map = Mapping!(32,16)(lnt.graph, pnt, [1,2,3,0]);
}

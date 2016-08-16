module mapping;

import std.conv : to;
import std.stdio;
import std.experimental.logger;

import gfm.math.vector;

import graph;
import bitsetrbtree;
import bitsetmodule;
import protocols;
import floydmodule;
import fixedsizearray;
import protocols.lattice;
import plot.gnuplot;
import plot;
import utils : sum;

/** Mapping will be passed a BitsetStore. It will take this BitsetStore and
for each element it will try to reconnect the element for every permutation.
*/
class Mapping(int SizeLnt, int SizePnt) {
	const(Graph!SizeLnt)* lnt;	
	const(Graph!SizePnt)* pnt;	
	const(int[]) mapping;
	const uint upTo;
	Floyd floyd;

	BitsetStore!uint read;
	BitsetStore!uint write;

	this(ref const Graph!SizeLnt lnt, ref const Graph!SizePnt pnt, int[] mapping) {
		this.lnt = &lnt;
		this.pnt = &pnt;
		this.mapping = mapping;
		this.upTo = to!uint(1 << this.lnt.length);
		this.floyd.init(*this.pnt);
	}

	void reconnectQuorum(ref const(Bitset!uint) quorum, 
			ref BitsetStore!uint rsltQuorumSet, uint perm)
	{
		FixedSizeArray!(int,32) whichNodesToReconnect;
		getBitsSet(quorum, whichNodesToReconnect);
		const int numNodesToReconnect = to!int(whichNodesToReconnect.length);

		for(int fidx = 0; fidx < numNodesToReconnect; ++fidx) {
			for(int tidx = 0; tidx < numNodesToReconnect; ++tidx) {
				if(!floyd.pathExists(
						mapping[whichNodesToReconnect[fidx]], 
						mapping[whichNodesToReconnect[tidx]])) 
				{
					return;
				}
			}
		}

		rsltQuorumSet.insertUnique(bitset(perm));
	}

	void reconnectQuorums(const ref BitsetStore!uint quorumSet, 
			ref BitsetStore!uint rsltQuorumSet)
	{
		import core.bitop : popcnt;
		for(uint perm = 0; perm < upTo; ++perm) {
			//logf(perm == (upTo / 1000), "%5.4f", cast(double)(perm)/upTo);
			logf("%5.4f", cast(double)(perm)/upTo);
			int numBitsInPerm = popcnt(perm);
			floyd.execute(*this.pnt, bitset(perm));

			foreach(const ref it; quorumSet[]) {
				if(numBitsInPerm >= popcnt(it.bitset.store)) {
					this.reconnectQuorum(it.bitset, rsltQuorumSet, perm);
					foreach(sub; it.subsets[]) {
						this.reconnectQuorum(sub, rsltQuorumSet, perm);
					}
				}
			}
		}
	}

	/**
	oRead = Original Read
	oWrite = Original Write
	*/
	Result calcAC(const ref BitsetStore!uint oRead, 
			const ref BitsetStore!uint oWrite) 
	{
		this.reconnectQuorums(oRead, this.read);
		this.reconnectQuorums(oWrite, this.write);

		return calcAvailForTree(to!int(this.lnt.length), this.read, this.write);
	}

	string name(string protocolName) const pure {
		import std.format : format;
		return format("%s-Mapped", protocolName);
	}
}

struct Mappings(int SizeLnt, int SizePnt) {
	Mapping!(SizeLnt,SizePnt) bestMapping;
	Result bestResult;
	double bestAvail;

	const(Graph!SizeLnt)* lnt;	
	const(Graph!SizePnt)* pnt;	

	this(ref Graph!SizeLnt lnt, ref Graph!SizePnt pnt) {
		this.lnt = &lnt;
		this.pnt = &pnt;
		this.bestAvail = 0.0;
	}

	Result calcAC(const ref BitsetStore!uint oRead, 
			const ref BitsetStore!uint oWrite) 
	{
		import std.array : array;
		import std.range : iota;
		import std.algorithm.sorting : nextPermutation;
		int[] permutation = to!(int[])(iota(0, (*lnt).length).array);

		do {
			writefln("%(%2d, %)", permutation);
			auto cur = new Mapping!(SizeLnt,SizePnt)(*lnt, *pnt, permutation);
			Result curRslt = cur.calcAC(oRead, oWrite);
			double sumRslt = sum(curRslt.writeAvail) + sum(curRslt.readAvail);
			if(sumRslt > this.bestAvail) {
				if(this.bestMapping !is null) {
					destroy(this.bestMapping);
				}

				this.bestMapping = cur;
				this.bestAvail = sumRslt;
				this.bestResult = curRslt;
			}
		} while(nextPermutation(permutation));

		return this.bestResult;
	}

	string name(string protocolName) const pure {
		import std.format : format;
		return format("%s-Mapped", protocolName);
	}
}

unittest {
	auto lnt = Graph!16();
	auto pnt = Graph!16();
	auto map = new Mapping!(16,16)(lnt, pnt, [0,2,1,3,5,4]);
}

unittest {
	auto lattice = Lattice(2,2);
	auto latticeRslt = lattice.calcAC();
	auto pnt = makeLineOfFour();

	auto map = new Mapping!(32,16)(lattice.graph, pnt, [1,2,3,0]);
	auto mapRslt = map.calcAC(lattice.read, lattice.write);

	gnuPlot(ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt)
	);
}

unittest {
	auto lattice = Lattice(2,2);
	auto latticeRslt = lattice.calcAC();
	auto pnt = makeLineOfFour();
	
	auto map = Mappings!(32,16)(lattice.graph, pnt);
	auto mapRslt = map.calcAC(lattice.read, lattice.write);

	gnuPlot(ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt)
	);
}

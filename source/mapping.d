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
import utils;

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

	/** 
	params:
		readWriteBalance = A value between 0.0 and 1.0. The high the value the
			more reading will be favored during the mapping comparison.
	*/
	this(ref const Graph!SizeLnt lnt, ref const Graph!SizePnt pnt, 
			int[] mapping) 
	{
		this.lnt = &lnt;
		this.pnt = &pnt;
		this.mapping = mapping.dup;
		this.upTo = to!uint(this.lnt.length);
		this.floyd.init(*this.pnt);
	}

	void reconnectQuorum(ref const(Bitset!uint) quorum, 
			ref BitsetStore!uint rsltQuorumSet, Bitset!uint perm)
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

		rsltQuorumSet.insertUnique(perm);
	}

	void reconnectQuorums(const ref BitsetStore!uint quorumSetA, 
			ref BitsetStore!uint rsltQuorumSetA, 
			const ref BitsetStore!uint quorumSetB, 
			ref BitsetStore!uint rsltQuorumSetB)
	{
		import core.bitop : popcnt;
		import permutation;
		auto permu = Permutations(upTo);
		foreach(perm; permu) {
			int numBitsInPerm = popcnt(perm.store);
			floyd.execute(*this.pnt, perm);

			foreach(const ref it; quorumSetA[]) {
				if(numBitsInPerm >= popcnt(it.bitset.store)) {
					this.reconnectQuorum(it.bitset, rsltQuorumSetA, perm);
					foreach(sub; it.subsets[]) {
						this.reconnectQuorum(sub, rsltQuorumSetA, perm);
					}
				}
			}

			foreach(const ref it; quorumSetB[]) {
				if(numBitsInPerm >= popcnt(it.bitset.store)) {
					this.reconnectQuorum(it.bitset, rsltQuorumSetB, perm);
					foreach(sub; it.subsets[]) {
						this.reconnectQuorum(sub, rsltQuorumSetB, perm);
					}
				}
			}
		}

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
	}

	/**
	oRead = Original Read
	oWrite = Original Write
	*/
	Result calcAC(const ref BitsetStore!uint oRead, 
			const ref BitsetStore!uint oWrite) 
	{
		this.reconnectQuorums(oRead, this.read, oWrite, this.write);
		//this.reconnectQuorums(oWrite, this.write);

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
	const(double) readBalance;
	const(double) writeBalance;

	double bestAvail;

	const(Graph!SizeLnt)* lnt;	
	const(Graph!SizePnt)* pnt;	

	this(ref Graph!SizeLnt lnt, ref Graph!SizePnt pnt, 
			double readWriteBalance = 0.5) 
	{
		this.lnt = &lnt;
		this.pnt = &pnt;
		this.bestAvail = 0.0;
		this.readBalance = readWriteBalance;
		this.writeBalance = 1.0 - readWriteBalance;
	}

	Result calcAC(const ref BitsetStore!uint oRead, 
			const ref BitsetStore!uint oWrite) 
	{
		import std.array : array;
		import std.range : iota;
		import std.algorithm.sorting : nextPermutation;
		import math;
		int[] permutation = to!(int[])(iota(0, (*lnt).length).array);

		auto numPerm = factorial(permutation.length);

		size_t cnt = 0;
		do {
			writefln("%(%2d, %) %7d of %7d %6.2f%%", permutation,
				cnt, numPerm, (cast(double)cnt/numPerm) * 100.0);
			++cnt;
			auto cur = new Mapping!(SizeLnt,SizePnt)(*lnt, *pnt, permutation);
			Result curRslt = cur.calcAC(oRead, oWrite);
			double sumRslt = 
				sum(curRslt.writeAvail)  * this.writeBalance + 
				sum(curRslt.readAvail) * this.readBalance;

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

	gnuPlot("Results/Lattice4_Line4_1_2_3_0", 
			ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt)
	);
}

unittest {
	import plot.mappingplot;

	auto lattice = Lattice(2,2);
	auto latticeRslt = lattice.calcAC();
	auto pnt = makeLineOfFour();

	auto map = Mappings!(32,16)(lattice.graph, pnt);
	auto mapRslt = map.calcAC(lattice.read, lattice.write);

	mappingPlot("Results/Lattice4_Line4", ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt),
			map
	);
}


unittest {
	auto lattice = Lattice(2,2);
	auto latticeRslt = lattice.calcAC();

	auto map = Mappings!(32,32)(lattice.graph, lattice.graph);
	auto mapRslt = map.calcAC(lattice.read, lattice.write);

	gnuPlot("Results/Lattice4_Lattice_Graph",
			ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt)
	);

	compare(latticeRslt.readAvail, mapRslt.readAvail, &equal);
	compare(latticeRslt.writeAvail, mapRslt.writeAvail, &equal);

	compare(latticeRslt.readCosts, mapRslt.readCosts, &equal);
	compare(latticeRslt.writeCosts, mapRslt.writeCosts, &equal);
}

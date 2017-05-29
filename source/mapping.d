module mapping;

import core.thread;

import std.conv : to;
import std.stdio;
import std.experimental.logger;
import std.meta;
import std.concurrency;
import std.array : empty;

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
import units;

alias ROW = Quantity!(double, "ReadOverWrite", 0.0, 1.0);
alias ROWC = Quantity!(double, "ReadOverWriteCosts", 0.0, 1.0);
alias QTF = Quantity!(double, "QuorumTestFraction", 0.0, 1.0);

struct MappingParameter {
	const(ROW) row;
	const(QTF) quorumTestFraction;

	this(ROW row, QTF qtf) {
		this.row = row;
		this.quorumTestFraction = qtf;
	}
}

struct RCMapping(int SizeLnt, int SizePnt) {
	int rc;
	Mapping!(SizeLnt,SizePnt) mapping;
	Result result;
}

void decrementRCMapping(RC)(RC* ptr) {
	import core.memory : GC;
	assert(ptr !is null);	
	(*ptr).rc--;
	if((*ptr).rc == 0) {
		GC.removeRange(cast(void*)ptr);
		GC.free(cast(void*)(*ptr).mapping);
		(*ptr).mapping = null;
		GC.free(ptr);
	}
}

void incrementRCMapping(RC)(RC* ptr) {
	assert(ptr !is null);	
	(*ptr).rc++;
}

struct MappingResultElement(int SizeLnt, int SizePnt) {
	RCMapping!(SizeLnt, SizePnt)* mapping;
	double value;
}

struct MappingResultStore(int SizeLnt, int SizePnt) {
	import std.math : isNaN;
	MappingResultElement!(SizeLnt,SizePnt)[101] bestAvail; 
	MappingResultElement!(SizeLnt,SizePnt)[101] bestCosts; 

	const ROW[] row;
	const ROWC[] rowc;

	this(const ROW[] row, const ROWC[] rowc) {
		this.row = row;
		this.rowc = rowc;
	}

	RCMapping!(SizeLnt,SizePnt)* get(ROW row) {
		auto idx = cast(int)(row.value * 100);
		auto ret = this.bestAvail[idx].mapping;
		return ret;
	}

	const(RCMapping!(SizeLnt,SizePnt)*) get(ROW row) const {
		auto idx = cast(int)(row.value * 100);
		auto ret = this.bestAvail[idx].mapping;
		return ret;
	}

	RCMapping!(SizeLnt,SizePnt)* get(ROWC rowc) {
		auto idx = cast(int)(rowc.value * 100);
		auto ret = this.bestCosts[idx].mapping;
		return ret;
	}

	const(RCMapping!(SizeLnt,SizePnt)*) get(ROWC rowc) const {
		auto idx = cast(int)(rowc.value * 100);
		auto ret = this.bestCosts[idx].mapping;
		return ret;
	}

	static RCMapping!(SizeLnt,SizePnt)* newPtr(Mapping!(SizeLnt,SizePnt) mapping,
			ref Result rslt) 
	{
		import core.memory : GC;
		auto mem = GC.malloc(RCMapping!(SizeLnt,SizePnt).sizeof);
		GC.addRange(mem, RCMapping!(SizeLnt,SizePnt).sizeof);
		RCMapping!(SizeLnt,SizePnt)* ptr = cast(RCMapping!(SizeLnt,SizePnt)*)(
			mem	
		);
		(*ptr).rc = 1;
		(*ptr).mapping = mapping;
		(*ptr).result = rslt.dup();
		return ptr;
	}

	void compare(ref Result rslt, Mapping!(SizeLnt,SizePnt) mapping) {
		auto ptr = newPtr(mapping, rslt);
		this.compareROW(rslt, ptr);
		this.compareROWC(rslt, ptr);
		decrementRCMapping(ptr);
	}

	static void compareImpl(const(double) value, RCMapping!(SizeLnt,SizePnt)* ptr,
			const(int) idx, ref MappingResultElement!(SizeLnt,SizePnt)[101] arr)
	{
		if(arr[idx].mapping is null) {
			arr[idx].mapping = ptr;
			arr[idx].value = value;
			incrementRCMapping(ptr);
		} else if(arr[idx].mapping !is null) {
			if(value > arr[idx].value) {
				decrementRCMapping(arr[idx].mapping);
				arr[idx].mapping = ptr;
				arr[idx].value = value;
				incrementRCMapping(ptr);
			}
		}
	}

	void compareROW(ref Result rslt, RCMapping!(SizeLnt,SizePnt)* ptr) {
		const(double) sumRsltW = sum(rslt.writeAvail);
		const(double) sumRsltR = sum(rslt.readAvail);

		foreach(it; this.row) {
			const(double) value = sumRsltR * it.value
				+ sumRsltW * (1.0 - it.value);

			const(int) idx = cast(int)(it.value * 100);
			compareImpl(value, ptr, idx, this.bestAvail);
		}
	}

	void compareROWC(ref Result rslt, RCMapping!(SizeLnt,SizePnt)* ptr) {
		const(double) sumRsltW = sum(rslt.writeCosts);
		const(double) sumRsltR = sum(rslt.readCosts);

		foreach(it; this.rowc) {
			const(double) value = sumRsltR * it.value
				+ sumRsltW * (1.0 - it.value);

			const(int) idx = cast(int)(it.value * 100);
			compareImpl(value, ptr, idx, this.bestCosts);
		}
	}
}

unittest {
	MappingParameter a;
	MappingParameter b;

	static assert(!__traits(compiles, a = b));
}

import config : PlatformAlign;

/** Mapping will be passed a BitsetStore. It will take this BitsetStore and
for each element it will try to reconnect the element for every permutation.
*/
align(8)
class Mapping(int SizeLnt, int SizePnt) {
	align(8) {
	const(Graph!SizeLnt)* lnt;	
	const(Graph!SizePnt)* pnt;	
	const(int[]) mapping;
	const uint upTo;
	Floyd floyd;

	BitsetStore!uint read;
	BitsetStore!uint write;

	const(QTF) quorumTestFraction;
	}

	/** 
	params:
		readWriteBalance = A value between 0.0 and 1.0. The high the value the
			more reading will be favored during the mapping comparison.
	*/
	this(ref const Graph!SizeLnt lnt, ref const Graph!SizePnt pnt, 
			int[] mapping, QTF quorumTestFraction = QTF(1.0)) 
	{
		//this.lnt = &lnt;
		//this.pnt = &pnt;
		//this.mapping = mapping.dup;
		//this.upTo = to!uint(this.lnt.length);
		//this.floyd.init(*this.pnt);
		//this.quorumTestFraction = quorumTestFraction;
		this.init(lnt, pnt, mapping, quorumTestFraction);
	}

	void init(ref const Graph!SizeLnt lnt, ref const Graph!SizePnt pnt, 
			int[] mapping, QTF quorumTestFraction = QTF(1.0))
	{
		this.lnt = &lnt;
		this.pnt = &pnt;
		this.mapping = mapping.dup;
		this.upTo = to!uint(this.lnt.length);
		this.floyd.init(*this.pnt);
		this.quorumTestFraction = quorumTestFraction;
	}

	void reconnectQuorum(ref const(Bitset!uint) quorum, 
			ref BitsetStore!uint rsltQuorumSet, Bitset!uint perm)
	{
		enum numBits = uint.sizeof * 8;
		for(int fidx = 0; fidx < numBits; ++fidx) {
			if(quorum[fidx]) {
				for(int tidx = 0; tidx < numBits; ++tidx) {
					if(quorum[tidx]) {
						if(!floyd.pathExists(
								mapping[fidx], 
								mapping[tidx])) 
						{
							return;
						}
					}
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
		import std.algorithm.comparison : min, max;
		import std.math : lround;
		import permutation;
		auto permu = Permutations(upTo);
		const size_t quorumSetALen = cast(size_t)min(quorumSetA.length, 
				max(1, lround(quorumSetA.length * this.quorumTestFraction.value))
		);
		const size_t quorumSetBLen = cast(size_t)min(quorumSetB.length, 
				max(1, lround(quorumSetB.length * this.quorumTestFraction.value))
		);
		logf(false, "%5.6f %s <= %s || %s <= %s", 
				this.quorumTestFraction,
				quorumSetALen, quorumSetA.length, 
				quorumSetBLen, quorumSetB.length
		);
		foreach(perm; permu) {
			int numBitsInPerm = popcnt(perm.store);
			floyd.execute(*this.pnt, perm);

			foreach(const ref it; quorumSetA[cast(size_t)0UL .. quorumSetALen]) {
				if(numBitsInPerm >= popcnt(it.bitset.store)) {
					this.reconnectQuorum(it.bitset, rsltQuorumSetA, perm);
					foreach(sub; it.subsets[]) {
						this.reconnectQuorum(sub, rsltQuorumSetA, perm);
					}
				}
			}

			foreach(const ref it; quorumSetB[cast(size_t)0UL .. quorumSetBLen]) {
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

		return calcAvailForTree!(typeof(this.read))(to!int(this.lnt.length), this.read, this.write);
	}

	string name(string protocolName) const pure {
		import std.format : format;
		return format("%s-Mapped", protocolName);
	}
}

align(8)
struct Mappings(int SizeLnt, int SizePnt) {
	align(8) {
	Mapping!(SizeLnt,SizePnt) bestMappingLocal;

	Result bestResultLocal;
	MappingResultStore!(SizeLnt,SizePnt) results;

	//const(ROW) readBalance;
	//const(ROW) writeBalance;

	//double bestAvail;

	const(Graph!SizeLnt)* lnt;	
	const(Graph!SizePnt)* pnt;	

	const QTF quorumTestFraction;
	}

	this(ref const Graph!SizeLnt lnt, ref const Graph!SizePnt pnt, 
			const QTF quorumTestFraction = QTF(1.0), const ROW readWriteBalance = ROW(0.5)) 
	{
		this(lnt, pnt, [readWriteBalance], null);
		//this.bestAvail = 0.0;
		//this.readBalance = readWriteBalance;
		//this.writeBalance = ROW(1.0) - readWriteBalance;
		this.quorumTestFraction = quorumTestFraction;
	}

	this(ref const Graph!SizeLnt lnt, ref const Graph!SizePnt pnt,
			const ROW[] row, const ROWC[] rowc)
	{
		assert(!row.empty);
		this.quorumTestFraction = QTF(1.0);
		this.lnt = &lnt;
		this.pnt = &pnt;

		this.results = MappingResultStore!(SizeLnt,SizePnt)(row, rowc);
	}

	@property Mapping!(SizeLnt,SizePnt) bestMapping() {
		if(this.results.get(ROW(0.5)) !is null) {
			return this.results.get(ROW(0.5)).mapping;
		} else {
			return this.results.get(this.results.row[0]).mapping;
		}
	}

	@property const(Mapping!(SizeLnt,SizePnt)) bestMapping() const {
		return (cast(Mappings!(SizeLnt,SizePnt))(this)).bestMapping();
	}

	@property ref Result bestResult() {
		if(this.results.get(ROW(0.5)) !is null) {
			return this.results.get(ROW(0.5)).result;
		} else {
			return this.results.get(this.results.row[0]).result;
		}
	}

	@property const(Result) bestResult() const {
		return (cast(Mappings!(SizeLnt,SizePnt))(this)).bestResult();
	}

	Result calcAC(const ref BitsetStore!uint oRead, 
			const ref BitsetStore!uint oWrite, 
			const bool stopAfterFirst = false) 
	{
		import std.array : array;
		import std.range : iota;
		import std.algorithm.sorting : nextPermutation;
		import math;
		int[] permutation = to!(int[])(iota(0, (*lnt).length).array);
		ulong numPerm = factorial(permutation.length);

		this.calcACImpl(oRead, oWrite, numPerm, permutation,
				//this.bestMappingLocal, this.bestResultLocal, this.bestAvail,
				stopAfterFirst);
		return this.bestResult;
	}

	Result calcACThreaded(const ref BitsetStore!uint oRead, 
			const ref BitsetStore!uint oWrite, 
			const bool stopAfterFirst = false) 
	{
		/*import std.array : array, back;
		import std.range : iota;
		import std.algorithm.sorting : nextPermutation;
		import std.algorithm.iteration : sum;
		import fixedsizearray;

		import math;
		int[] permutation = to!(int[])(iota(0, (*lnt).length).array);
		ulong numPerm = factorial(permutation.length);

		const numThreads = 4;
		const permPerThread = numPerm / numThreads;
		long[numThreads] firstPerm;
		for(int i = 0; i < numThreads; ++i) {
			firstPerm[i] = permPerThread * i;
		}
		long[numThreads] numberPerms;
		for(int i = 0; i < numThreads-1; ++i) {
			numberPerms[i] = permPerThread;
		}
		numberPerms.back = numPerm - sum(numberPerms[0 .. numThreads-1], 0L);

		int[][numThreads] permutations;
		for(int i = 0; i < numThreads; ++i) {
			permutations[i] = nthPermutation(permutation, firstPerm[i]);
		}

		double[numThreads] bestAvails;
		Mapping!(SizeLnt,SizePnt)[numThreads] bestMappings;
		Result[numThreads] results;

		writefln("numPerm %d\npermPerThread %d\nfirstPerm %(%d, %)\nnumberPerms %(%d, %)\n" ~
				"permutations:\n%(\t%s,\n%)", numPerm, permPerThread, firstPerm,
				numberPerms, permutations);

		BitsetStore!(uint)[numThreads] oReads;
		BitsetStore!(uint)[numThreads] oWrites;

		for(int i = 0; i < numThreads; ++i) {
			oReads[i] = oRead.dup();
			oWrites[i] = oWrite.dup();
		}

		MappingImpl!(SizeLnt,SizePnt)[numThreads] threads;
		for(int i = 0; i < numThreads; ++i) {
			threads[i] = new MappingImpl!(SizeLnt,SizePnt)(i, cast(shared)&this,
					cast(shared(const(BitsetStore!uint))*)&oReads[i],
					cast(shared(const(BitsetStore!uint))*)&oWrites[i],
					numberPerms[i], cast(shared)permutations[i], stopAfterFirst);
			threads[i].start();
		}

		int best;
		for(int i = 0; i < numThreads; ++i) {
			threads[i].join();
			if(i == 0) {
				this.bestAvail = threads[i].bestAvailL;
				best = 0;
			} else if(threads[i].bestAvailL > this.bestAvail) {
				this.bestAvail = threads[i].bestAvailL;
				best = i;
			}
		}

		this.bestAvail = threads[best].bestAvailL;
		this.bestMapping = threads[best].bestMappingL;
		assert(this.bestMapping !is null);
		this.bestResultLocal = threads[best].bestResultL;

		return this.bestResult;*/
		assert(false);
	}

	void calcACImpl(const ref BitsetStore!uint oRead, 
			const ref BitsetStore!uint oWrite, const(ulong) numPerm,
			int[] permutation, /*ref Mapping!(SizeLnt,SizePnt) bestMappingL,
			ref Result bestResultL, ref double bestAvailL,*/
			const bool stopAfterFirst)
	{
		import core.memory : GC;
		import std.array : array;
		import std.range : iota;
		import std.algorithm.sorting : nextPermutation;
		import math;
		ulong numPermPercent = numPerm / 100;

		size_t cnt = 0;
		do {
			if(cnt != 0 && numPermPercent != 0 && cnt % numPermPercent == 0) {
				//logf("%(%2d, %) %7d of %7d %6.2f%%", permutation,
				logf("%7d of %7d %6.2f%%",
					cnt, numPerm, (cast(double)cnt/numPerm) * 100.0);
			}
			++cnt;
			auto cur = new Mapping!(SizeLnt,SizePnt)(*lnt, *pnt, permutation,
					this.quorumTestFraction
			);
			Result curRslt = cur.calcAC(oRead, oWrite);
			this.results.compare(curRslt, cur);
		} while(nextPermutation(permutation) && cnt < numPerm && !stopAfterFirst);
	}

	void createDummyBestMapping() {
		import std.range : iota;
		import std.array : array;
		this.bestMappingLocal = new Mapping!(SizeLnt,SizePnt)(*lnt, *pnt, 
				iota(pnt.length).array().to!(int[]));
	}

	string name(string protocolName) const pure {
		import std.format : format;
		return format("%s-Mapped", protocolName);
	}
}

/*class MappingImpl(int SizeLnt, int SizePnt) : Thread {
	Mappings!(SizeLnt,SizePnt)* mappings;
	Mapping!(SizeLnt,SizePnt) bestMappingL;
	Result bestResultL; 
	double bestAvailL;
	const(BitsetStore!uint)* oWrite;
	const(BitsetStore!uint)* oRead;
	const(ulong) numPerm;
	int[] permutation;
	const(bool) stopAfterFirst;
	const(int) tid;

	this(int tid, shared Mappings!(SizeLnt,SizePnt)* mappings, const shared BitsetStore!uint* oRead, 
			const shared BitsetStore!uint* oWrite, const(ulong) numPerm,
			shared int[] permutation, const bool stopAfterFirst)
	{
		super(&run);
		this.tid = tid;
		this.mappings = cast(Mappings!(SizeLnt,SizePnt)*)mappings;
		this.oWrite = cast(const(BitsetStore!uint)*)(oWrite);
		this.oRead = cast(const(BitsetStore!uint)*)(oRead);
		this.numPerm = numPerm;
		this.permutation = cast(int[])permutation;
		this.stopAfterFirst = stopAfterFirst;
		this.bestAvailL = 0.0;
	}

	void run() {
		import std.array : array;
		import std.range : iota;
		import std.algorithm.sorting : nextPermutation;
		import math;
		ulong numPermPercent = numPerm / 100;

		writefln("Start %.10f", this.mappings.quorumTestFraction);
		size_t cnt = 0;
		do {
			if(cnt != 0 && numPermPercent != 0 && cnt % numPermPercent == 0) {
				logf("Tid %d %7d of %7d %6.2f%%", this.tid,
					cnt, numPerm, (cast(double)cnt/numPerm) * 100.0);
			}
			++cnt;
			auto cur = new Mapping!(SizeLnt,SizePnt)(*this.mappings.lnt,
					*this.mappings.pnt, permutation,
					this.mappings.quorumTestFraction
			);
			Result curRslt = cur.calcAC(*oRead, *oWrite);
			double sumRslt = 
				sum(curRslt.writeAvail)  * this.mappings.writeBalance.value + 
				sum(curRslt.readAvail) * this.mappings.readBalance.value;

			if(sumRslt > bestAvailL) {
				writefln("%(%s, %) %.10f", permutation, sumRslt);
				if(bestMappingL !is null) {
					destroy(bestMappingL);
				}

				bestMappingL = cur;
				bestAvailL = sumRslt;
				bestResultL = curRslt;
			}
		} while(nextPermutation(permutation) && cnt < numPerm && !stopAfterFirst);

		if(this.mappings.quorumTestFraction.value < 1.0) {
			int[] mapCp = bestMappingL.mapping.dup;
			if(bestMappingL !is null) {
				destroy(bestMappingL);
			}
			bestMappingL = new Mapping!(SizeLnt,SizePnt)(*this.mappings.lnt,
					*this.mappings.pnt, mapCp, QTF(1.0)
			);
			bestResultL = bestMappingL.calcAC(*oRead, *oWrite);
			bestAvailL = 
					sum(bestResultL.writeAvail)  * this.mappings.writeBalance.value + 
					sum(bestResultL.readAvail) * this.mappings.readBalance.value;
		}
		writefln("Done Tid %d Best Mapping %(%s, %) %.10f Final", this.tid, 
				bestMappingL.mapping, bestAvailL);
	}
}*/

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

	gnuPlot("Results/Lattice4_Line4_1_2_3_0", "",
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

	mappingPlot("Results/Lattice4_Line4", map, 
			ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt),
	);
}

unittest {
	auto lattice = Lattice(2,2);
	auto latticeRslt = lattice.calcAC();

	auto map = Mappings!(32,32)(lattice.graph, lattice.graph);
	auto mapRslt = map.calcAC(lattice.read, lattice.write);

	gnuPlot("Results/Lattice4_Lattice_Graph", "",
			ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt)
	);

	compare(latticeRslt.readAvail, mapRslt.readAvail, &equal);
	compare(latticeRslt.writeAvail, mapRslt.writeAvail, &equal);

	compare(latticeRslt.readCosts, mapRslt.readCosts, &equal);
	compare(latticeRslt.writeCosts, mapRslt.writeCosts, &equal);
}

unittest {
	auto lattice = Lattice(2,2);
	auto latticeRslt = lattice.calcAC();

	logf("\n\n\n");
	auto map = Mappings!(32,32)(lattice.graph, lattice.graph, [ROW(0.91)], null);
	//auto map = Mappings!(32,32)(lattice.graph, lattice.graph);
	auto mapRslt = map.calcAC(lattice.read, lattice.write);

	//for(int i = 0; i < 101; ++i) {
	//	writefln("%.10f %.10f", map.results.get(ROW(0.91)).result.readAvail[i],
	//			map.results.get(ROW(0.91)).result.writeAvail[i]);
	//}

	gnuPlot("Results/Lattice4_Lattice_Graph_ROW(0.9)", "",
			ResultPlot(lattice.name(), latticeRslt),
			ResultPlot(map.name(lattice.name()), mapRslt)
	);

	//compare(latticeRslt.readAvail, mapRslt.readAvail, &equal);
	//compare(latticeRslt.writeAvail, mapRslt.writeAvail, &equal);

	//compare(latticeRslt.readCosts, mapRslt.readCosts, &equal);
	//compare(latticeRslt.writeCosts, mapRslt.writeCosts, &equal);
}

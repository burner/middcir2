module protocols;

import std.conv : text;
import std.container : Array;
import std.experimental.logger;
import std.math : isNaN;

import bitsetrbtree;
import mapping;
import graph;

import protocols.crossing;

Result getResult() {
	Result ret;
	ret.readAvail[] = double.nan;
	ret.writeAvail[] = double.nan;
	ret.readCosts[] = double.nan;
	ret.writeCosts[] = double.nan;
	return ret;
}

align(8)
struct Result {
	align(8) {
	double[101] readAvail;
	double[101] writeAvail;

	double[101] readCosts;
	double[101] writeCosts;
	}

	this(string avail, string costs) {
		import std.format : formattedRead;
		import std.algorithm.iteration : splitter;
		import std.math : approxEqual;
		import std.array : empty;
		if(avail.empty) {
			logf("no avail");
			return;
		}
		if(costs.empty) {
			logf("no costs");
			return;
		}
		auto asp = avail.splitter("\n");
		auto csp = costs.splitter("\n");

		double dummy;
		for(int i = 0; i < 101; ++i) {
			string a = asp.front;
			string c = csp.front;
			//logf("%d %s\n\n%s", i, a, c);
			formattedRead(a, "%f %f %f", &dummy,
					&(this.readAvail[i]), &(this.writeAvail[i]));
			formattedRead(c, "%f %f %f", &dummy,
					&(this.readCosts[i]), &(this.writeCosts[i]));
			if(isNaN(this.readAvail[i])) {
				this.readAvail[i] = 0.0;
			}
			if(isNaN(this.writeAvail[i])) {
				this.writeAvail[i] = 0.0;
			}
			if(isNaN(this.readCosts[i])) {
				this.readCosts[i] = 0.0;
			}
			if(isNaN(this.writeCosts[i])) {
				this.writeCosts[i] = 0.0;
			}
			if(i < 100) {
				asp.popFront();
				csp.popFront();
			}
		}
		assert(approxEqual(dummy, 1.0));
	}

	Result dup() const {
		auto ret = getResult();

		foreach(idx, it; this.readAvail) {
			ret.readAvail[idx] = it;
		}
		foreach(idx, it; this.writeAvail) {
			ret.writeAvail[idx] = it;
		}
		foreach(idx, it; this.readCosts) {
			ret.readCosts[idx] = it;
		}
		foreach(idx, it; this.writeCosts) {
			ret.writeCosts[idx] = it;
		}

		return ret;
	}
}

Result calcAvailForTree(BitsetStoreType)(const int numNodes,
		ref BitsetStoreType read, ref BitsetStoreType write)
{
	auto ret = getResult();
	calcAvailForTreeImpl!BitsetStoreType(numNodes, read, ret.readAvail, 
		ret.readCosts
	);
	calcAvailForTreeImpl!BitsetStoreType(numNodes, write, ret.writeAvail, 
		ret.writeCosts
	);

	return ret;
}

struct ResultProtocol(P) {
	import std.stdio;

	P protocol;
	Mappings!(32,32) mappings;
	Graph!32 pnt;
	MappingParameter mappingParameter;

	Result lntResult;
	Result pntResult;

	this(P proto, const(MappingParameter) mp, Graph!32 pnt) {
		this.protocol = proto;
		this.pnt = pnt;
		this.mappingParameter = mp;

		this.lntResult = this.protocol.calcAC();

		this.mappings = Mappings!(32,32)(this.protocol.graph, this.pnt,
				this.mappingParameter.quorumTestFraction,
				this.mappingParameter.row
		);

		// As MCS is using a totally connected LNT we only have to look at
		// one mapping
		const bool isMCS = is(typeof(p) == MCS);

		static if(is(typeof(proto) == Crossings)) {
			this.pntResult = this.lntResult;
		} else {
			this.pntResult = this.mappings.calcAC(
					this.protocol.read,
					this.protocol.write,
					isMCS
				);
		}
	}
}

ResultProtocol!P resultProtocol(P)(P proto, const(MappingParameter) mp,
		Graph!32 pnt)
{
	return ResultProtocol!P(proto, mp, pnt);
}

auto resultProtocolUnique(P)(P proto, const(MappingParameter) mp,
		Graph!32 pnt)
{
	import std.typecons : Unique;
	return Unique!(ResultProtocol!P)(new ResultProtocol!P(proto, mp, pnt));
}

private void calcAvailForTreeImpl(BitsetStoreType)(const int numNodes,
		ref BitsetStoreType tree, ref double[101] avail,
	   	ref double[101] costs)
{
	import std.format : format;
	import std.algorithm.sorting : sort;

	import config : stepCount;
	import math : availability, binomial, isNaN, popcnt;

	bool[long] allreadyVisited;

	auto it = tree.begin();
	auto end = tree.end();

	size_t numQuorums = 0;

	bool[101] test;
	while(it != end) {
		const bsa = *it;
		auto subsets = getSubsets(bsa, tree);
		//logf("%d subsets.length %d", (*it).bitset.store,
		//	subsets.length
		//);

		assert((*it).bitset.store !in allreadyVisited);
		allreadyVisited[(*it).bitset.store] = true;

		numQuorums += 1;
		numQuorums += bsa.subsets.length;

		test[] = false;
		for(int idx = 0; idx < 101; ++idx) {
			double step = stepCount * idx;
			assert(!test[idx]);
			test[idx] = true;

			const availBsa = availability(numNodes, bsa.bitset, idx, stepCount);
			const minQuorumNodeCnt = popcnt(bsa.bitset.store);

			avail[idx] += availBsa;

			double bino = binomial(numNodes, minQuorumNodeCnt);
			costs[idx] += minQuorumNodeCnt * availBsa;

			foreach(jt; subsets) {
				auto availJt = availability(numNodes, jt, idx, stepCount);
				avail[idx] += availJt;
				costs[idx] += minQuorumNodeCnt * availJt;
			}
		}
		foreach(idx, jt; test) {
			if(!jt) {
				throw new Exception(format("%s", idx));
			}
		}
		++it;
	}

	for(int idx = 0; idx < 101; ++idx) {
		costs[idx] /= avail[idx];
	}

	for(int idx= 0; idx < 101; ++idx) {
		avail[idx] /= 1000;
	}
}

void closedQuorumListWriterImpl(BSS,Out)(const ref BSS store,
	   	Out writer) 
{
	import std.format : formattedWrite;

	formattedWrite(writer, "{\n\t\"list\" : [\n");
	bool outerFirst = true;
	foreach(ref it; store.array[]) {
		if(outerFirst) {
			formattedWrite(writer, 
				"\t\t{\"head\" : %d, \"supersets\" : [", it.bitset.store
			);
			outerFirst = false;
		} else {
			formattedWrite(writer, 
				"\t\t,{\"head\" : %d, \"supersets\" : [", it.bitset.store
			);
		}
		bool first = true;
		auto iss = getSubsets(it, store);
		foreach(ref jt; iss) {
			if(first) {
				formattedWrite(writer, "\n\t\t\t%d", jt.store);
				first = false;
			} else {
				formattedWrite(writer, "\n\t\t\t,%d", jt.store);
			}
		}
		if(first) {
			formattedWrite(writer, "]}\n");
		} else {
			formattedWrite(writer, "\n\t\t]}\n");
		}
	}

	formattedWrite(writer, "\t]\n}\n");
}

void closedQuorumListWriter(BSS)(
		const ref BSS store) 
{
	import std.stdio : stdout;
	closedQuorumListWriterImpl(store, stdout.lockingTextWriter());
}

void closedQuorumListWriter(BSS)(
		const ref BSS store, string filename)
{
	import std.string : lastIndexOf;
	import std.file : exists, isDir, mkdirRecurse;
	import std.stdio : File;

	auto ls = filename.lastIndexOf('/');
	assert(ls != -1);
	auto fn = filename[0 .. ls+1];
	if(!exists(fn) || !isDir(fn)) {
		mkdirRecurse(fn);
	}

	auto f = File(filename, "w");
	closedQuorumListWriterImpl(store, f.lockingTextWriter());
}

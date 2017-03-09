module protocols;

import std.container : Array;
import std.experimental.logger;

import bitsetrbtree;
import mapping;
import graph;

import protocols.crossing;

struct Result {
	double[101] readAvail;
	double[101] writeAvail;

	double[101] readCosts;
	double[101] writeCosts;

	static Result opCall() {
		Result ret;
		ret.readAvail[] = 0.0;
		ret.writeAvail[] = 0.0;
		ret.readCosts[] = 0.0;
		ret.writeCosts[] = 0.0;
		return ret;
	}

	Result dup() {
		auto ret = Result();

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

Result calcAvailForTree(BitsetType)(const int numNodes,
		ref BitsetStore!BitsetType read, ref BitsetStore!BitsetType write)
{
	auto ret = Result();
	calcAvailForTreeImpl!BitsetType(numNodes, read, ret.readAvail, ret.readCosts);
	calcAvailForTreeImpl!BitsetType(numNodes, write, ret.writeAvail, ret.writeCosts);

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

private void calcAvailForTreeImpl(BitsetType)(const int numNodes,
		ref BitsetStore!BitsetType tree, ref double[101] avail,
	   	ref double[101] costs)
{
	import std.format : format;
	import std.algorithm.sorting : sort;
	//import core.bitop : popcnt;

	import config : stepCount;
	import math : availability, binomial, isNaN, popcnt;

	auto it = tree.begin();
	auto end = tree.end();

	size_t numQuorums = 0;

	bool[101] test;
	while(it != end) {
		const bsa = *it;

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

			foreach(jt; bsa.subsets) {
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

	/*for(int idx= 0; idx < 101; ++idx) {
		costs[idx] /= 1000;
		avail[idx] /= 1000;

	}*/
}

void closedQuorumListWriter(BitsetType,Out)(const ref BitsetStore!BitsetType store,
	   	Out writer) 
{
	import std.format : formattedWrite;

	formattedWrite(writer, "{\n\tlist : [\n");
	bool outerFirst = true;
	foreach(ref it; store.array[]) {
		if(outerFirst) {
			formattedWrite(writer, 
				"\t\t{head : %d, supersets : [", it.bitset.store
			);
			outerFirst = false;
		} else {
			formattedWrite(writer, 
				"\t\t,{head : %d, supersets : [", it.bitset.store
			);
		}
		bool first = true;
		foreach(ref jt; it.subsets[]) {
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

void closedQuorumListWriter(BitsetType)(
		const ref BitsetStore!BitsetType store) 
{
	import std.stdio : stdout;
	closedQuorumListWriter!BitsetType(store, stdout.lockingTextWriter());
}

void closedQuorumListWriter(BitsetType)(
		const ref BitsetStore!BitsetType store, string filename)
{
	auto f = File(filename, "w");
	closedQuorumListWriter!BitsetType(store, f.lockingTextWriter());
}

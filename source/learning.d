module learning;

import std.stdio;
import std.container.array;
import std.format : format, formattedWrite;
import std.algorithm.sorting : nextPermutation;
import std.meta : AliasSeq;
import std.exception : enforce;
import std.experimental.logger;
import std.math : isNaN, pow, approxEqual;

import fixedsizearray;

import statsanalysis;
import permutation;
import bitsetmodule;

string shortName(string l) {
	import std.uni : isNumber;
	string ret;
	foreach(char c; l) {
		if(c == ' ') {
			ret ~= '_';
		} else if(c != 'a' && c != 'i' && c != 'o' && c != 'u' && c != 'e' 
				&& c != '!' && !isNumber(c) && c != ',')
		{
			ret ~= c;
		}
	}
	return ret;
}

abstract class IStat(int Size) {
	string name;
	abstract @property string XLabel() const;
	abstract double select(const(GraphStats!Size) g) const;
	abstract double select(const(GraphWithProperties!Size) g) const;
}

class CStat(alias Stat, int Size) : IStat!Size {
	this() {
		this.name = shortName(Stat!Size.XLabel);
	}
	override @property string XLabel() const {
		return Stat!Size.XLabel;
	}

	override double select(const(GraphStats!Size) g) const {
		return Stat!Size.select(g);
	}
	override double select(const(GraphWithProperties!Size) g) const {
		return Stat!Size.select(g);
	}
}

auto cstatsArray = [
	new CStat!(DiameterAverage,32), new CStat!(DiameterMedian,32),
	new CStat!(DiameterMax,32), new CStat!(DiameterMode,32),
	new CStat!(Connectivity,32), new CStat!(DegreeAverage,32), 
	new CStat!(DegreeMedian,32), new CStat!(DegreeMin,32), 
	new CStat!(DegreeMax,32), new CStat!(BetweenneesAverage,32), 
	new CStat!(BetweenneesMedian,32), new CStat!(BetweenneesMin,32), 
	new CStat!(BetweenneesMax,32)
];

class MMCStat(int Size) {
	FixedSizeArray!(IStat!Size) cstats;

	bool less(const(GraphStats!Size) a, 
			const(GraphStats!Size) b) const nothrow
	{
		import std.math : approxEqual;

		try {
			foreach(it; this.cstats) {
				if(approxEqual(it.select(a), it.select(b), 0.000_001)) {
					continue;
				} else if(it.select(a) < it.select(b)) {
					return true;
				} else {
					return false;
				}
			}
		} catch(Throwable t) {
			assert(false);
		}
		return false;
	}

	bool equal(const(GraphStats!Size) a, 
			const(GraphStats!Size) b) const 
	{
		import std.math : approxEqual;

		foreach(it; this.cstats) {
			if(!approxEqual(it.select(a), it.select(b), 0.000_001)) {
				return false;
			}
		}
		return true;
	}

	size_t equalCount(const(GraphStats!Size) a, 
			const(GraphStats!Size) b) const
	{
		size_t sum = 0;
		foreach(it; this.cstats) {
			if(approxEqual(it.select(a), it.select(b), 0.000_001)) {
				++sum;
			}
		}
		return sum;
	}

	void insertIStat(IStat!Size ne) {
		this.cstats.insertBack(ne);
	}

	void clear() {
		this.cstats.removeAll();
	}
}

unittest {
	IStat!32 n = new CStat!(Connectivity, 32)();
	n = new CStat!(DiameterAverage,32)();

	int count;
	for(int i = 0; i < cstatsArray.length; ++i) {
		auto permu = Permutations(cast(int)cstatsArray.length, i, cast(int)cstatsArray.length);
		auto mm = new MMCStat!32();
		foreach(perm; permu) {
			for(int j = 0; j < cstatsArray.length; ++j) {
				if(perm.test(j)) {
					mm.insertIStat(cstatsArray[j]);
					//write(cstatsArray[j].name, " ");
				}
			}
			mm.clear();
			//writeln();
			++count;
		}
	}
	writeln(count);
}

Array!(ProtocolStats!Size) split(int Size)(ref ProtocolStats!Size orig, size_t num) {
	import std.range : chunks;

	Array!(ProtocolStats!Size) ret;
	for(size_t i = 0; i < num; ++i) {
		ret.insertBack(ProtocolStats!Size());
	}

	for(size_t i = 0; i < orig.mcs.data.length; ++i) {
		for(size_t j = 0; j < num; ++j) {
			ret[j].mcs.data.insertBack(Data!Size(orig.mcs.data[i].key));
		}
	}

	for(size_t i = 0; i < orig.lattice.data.length; ++i) {
		for(size_t j = 0; j < num; ++j) {
			ret[j].lattice.data.insertBack(Data!Size(orig.lattice.data[i].key));
		}
	}

	for(size_t i = 0; i < orig.grid.data.length; ++i) {
		for(size_t j = 0; j < num; ++j) {
			ret[j].grid.data.insertBack(Data!Size(orig.grid.data[i].key));
		}
	}

	for(size_t i = 0; i < orig.mcs.data.length; ++i) {
		auto c = chunks(orig.mcs.data[i].values[],
				orig.mcs.data[i].values.length / num);
		for(size_t j = 0; j < num; ++j) {
			ret[j].mcs.data[i].values.insertBack(c[i]);
		}
	}

	for(size_t i = 0; i < orig.lattice.data.length; ++i) {
		auto c = chunks(orig.lattice.data[i].values[], 
				orig.lattice.data[i].values.length / num);
		for(size_t j = 0; j < num; ++j) {
			ret[j].lattice.data[i].values.insertBack(c[i]);
		}
	}

	for(size_t i = 0; i < orig.grid.data.length; ++i) {
		auto c = chunks(orig.grid.data[i].values[],
				orig.grid.data[i].values.length / num);
		for(size_t j = 0; j < num; ++j) {
			ret[j].grid.data[i].values.insertBack(c[i]);
		}
	}

	return ret;
}

ProtocolStats!(Size) join(int Size)(Array!(ProtocolStats!Size) parts, 
		const size_t doNotInclude)
{
	enforce(parts.length > 0);

	ProtocolStats!Size ret;
	for(size_t i = 0; i < parts[0].mcs.data.length; ++i) {
		ret.mcs.data.insertBack(Data!Size(parts[0].mcs.data[i].key));
	}

	for(size_t i = 0; i < parts[0].lattice.data.length; ++i) {
		ret.lattice.data.insertBack(Data!Size(parts[0].lattice.data[i].key));
	}

	for(size_t i = 0; i < parts[0].grid.data.length; ++i) {
		ret.grid.data.insertBack(Data!Size(parts[0].grid.data[i].key));
	}

	for(size_t i = 0; i < parts.length; ++i) {
		if(i == doNotInclude) {
			continue;
		}
		for(size_t j = 0; j < parts[i].mcs.data.length; ++j) {
			ret.mcs.data[j].values.insertBack(parts[i].mcs.data[j].values[]);
		}
	}

	for(size_t i = 0; i < parts.length; ++i) {
		if(i == doNotInclude) {
			continue;
		}
		for(size_t j = 0; j < parts[i].lattice.data.length; ++j) {
			ret.lattice.data[j].values.insertBack(parts[i].lattice.data[j].values[]);
		}
	}

	for(size_t i = 0; i < parts.length; ++i) {
		if(i == doNotInclude) {
			continue;
		}
		for(size_t j = 0; j < parts[i].grid.data.length; ++j) {
			ret.grid.data[j].values.insertBack(parts[i].grid.data[j].values[]);
		}
	}

	return ret;
}

Array!(GraphStats!Size) joinGraphStats(int Size)(
		ref const(Array!(GraphStats!Size)) old,
		const(MMCStat!Size) mm)
{
	Array!(GraphStats!Size) ret;
	foreach(ref it; old[]) {
		if(ret.empty) {
			ret.insertBack(GraphStats!Size(it));
		} else {
			if(mm.equal(ret.back, it)) {
				//logf("dup %.10f %.10f", Selector.select(ret.back), Selector.select(it));
			} else {
				ret.insertBack(GraphStats!Size(it));
			}
		}
	}

	return ret;
}

Data!Size joinData(int Size)(ref const(Data!Size) old,
	   	const(MMCStat!Size) mm)
{
	auto ret = Data!Size(old.key);
	ret.values = joinGraphStats(old.values, mm);
	return ret;
}

void joinData(int Size)(ref ProtocolStats!Size ps, const(MMCStat!Size) mm) {
	foreach(ref it; ps.mcs.data[]) {
		logf("mcs before length %s", it.values.length);
		it = joinData!(Size)(it, mm);
		logf("mcs after length %s", it.values.length);
	}
	foreach(ref it; ps.lattice.data[]) {
		logf("lattice before length %s", it.values.length);
		it = joinData!(Size)(it, mm);
		logf("lattice after length %s", it.values.length);
	}
	foreach(ref it; ps.grid.data[]) {
		logf("grid before length %s", it.values.length);
		it = joinData!(Size)(it, mm);
		logf("grid after length %s", it.values.length);
	}
}

void sort(int Size)(ref ProtocolStats!Size joined, MMCStat!Size mm) {
	import std.algorithm.sorting : sort;
	foreach(ref it; joined.mcs.data[]) {
		sort!((a,b) => mm.less(a,b))(it.values[]);
	}
	foreach(ref it; joined.lattice.data[]) {
		sort!((a,b) => mm.less(a,b))(it.values[]);
	}
	foreach(ref it; joined.grid.data[]) {
		sort!((a,b) => mm.less(a,b))(it.values[]);
	}
}

bool checkSorted(int Size)(ref ProtocolStats!Size joined, MMCStat!Size mm) {
	import std.algorithm.sorting : isSorted;
	bool ret = true;
	foreach(ref it; joined.mcs.data[]) {
		ret = ret && enforce(isSorted!((a,b) => mm.less(a,b))(it.values[]));
	}
	foreach(ref it; joined.lattice.data[]) {
		ret = ret && enforce(isSorted!((a,b) => mm.less(a,b))(it.values[]));
	}
	foreach(ref it; joined.grid.data[]) {
		ret = ret && enforce(isSorted!((a,b) => mm.less(a,b))(it.values[]));
	}

	return ret;
}

struct LearnRsltEntry(int Size) {
	double mse;
	MMCStat!32 bestApprox;
}

struct LearnRsltDim(int Size) {
	LNTDimensions dim;
	CmpRslt rslt;

	this(LNTDimensions dim) {
		this.dim = dim;
		this.rslt = CmpRslt();
	}
}

struct LearnRslt(int Size) {
	Array!(LearnRsltDim!Size) mcs;
	Array!(LearnRsltDim!Size) lattice;
	Array!(LearnRsltDim!Size) grid;

	this(const(ProtocolStats!Size)* ps) {
		foreach(ref it; ps.mcs.data[]) {
			this.mcs.insertBack(LearnRsltDim!Size(it.key));
		}
		foreach(ref it; ps.lattice.data[]) {
			this.lattice.insertBack(LearnRsltDim!Size(it.key));
		}
		foreach(ref it; ps.grid.data[]) {
			this.grid.insertBack(LearnRsltDim!Size(it.key));
		}
	}

	void print() {
		foreach(ref it; this.mcs[]) {
			logf("%s:%s %s", it.dim.width, it.dim.height, it.rslt);
		}
		foreach(ref it; this.lattice[]) {
			logf("%s:%s %s", it.dim.width, it.dim.height, it.rslt);
		}
		foreach(ref it; this.grid[]) {
			logf("%s:%s %s", it.dim.width, it.dim.height, it.rslt);
		}
	}
}

const(GraphStats!Size)* getPrediction(int Size)(ref const(GraphStatss!Size) ps,
		ref const(LNTDimensions) dim, ref const(GraphStats!Size) toFind, 
		const(MMCStat!Size) mm)
{
	foreach(ref data; ps.data[]) {
		if(data.key == dim) {
			size_t highestCnt;
			const(GraphStats!Size)* best;
			foreach(ref ss; data.values[]) {
				if(best is null) {
					highestCnt = mm.equalCount(ss, toFind);
					best = &ss;
				} else {
					size_t tmpCnt = mm.equalCount(ss, toFind);
					if(tmpCnt > highestCnt) {
						highestCnt = tmpCnt;
						best = &ss;
					}
				}
			}
			enforce(best !is null);
			return best;
		}
	}
	throw new Exception("Coundn't find shit");
}

struct CmpRslt {
	double[4][7][2] mse;

	static CmpRslt opCall() {
		CmpRslt ret;
		for(size_t i = 0; i < ret.mse.length; ++i) {
			for(size_t j = 0; j < ret.mse[i].length; ++j) {
				for(size_t k = 0; k < ret.mse[i][j].length; ++k) {
					ret.mse[i][j][k] = 0.0;
				}
			}
		}
		return ret;
	}

	void add(CmpRslt other) {
		for(size_t i = 0; i < mse.length; ++i) {
			for(size_t j = 0; j < mse[i].length; ++j) {
				for(size_t k = 0; k < mse[i][j].length; ++k) {
					this.mse[i][j][k] += other.mse[i][j][k];
				}
			}
		}
	}
}

double getWithNaN(double input) {
	return isNaN(input) ? 0.0 : input;
}

CmpRslt compare(int Size)(const(GraphStats!Size)* a,
	   	const(GraphStats!Size)* b) 
{
	enforce(a !is null);
	enforce(b !is null);

	auto ret = CmpRslt();
	for(size_t i = 0; i < a.results.length; ++i) {
		for(size_t j = 0; j < a.results[i].length; ++j) {
			double sum = 0.0;
			for(size_t k = 0; k < 101; ++k) {
				for(size_t h = 0; h < 4; ++h) {
					switch(h) {
						case 0:
							ret.mse[i][j][h] += pow(getWithNaN(a.results[i][j].readAvail[k]) -
								getWithNaN(b.results[i][j].readAvail[k]), 2);
							break;
						case 1:
							ret.mse[i][j][h] += pow(getWithNaN(a.results[i][j].writeAvail[k]) -
								getWithNaN(b.results[i][j].writeAvail[k]), 2);
							break;
						case 2:
							ret.mse[i][j][h] += pow(getWithNaN(a.results[i][j].readCosts[k]) -
								getWithNaN(b.results[i][j].readCosts[k]), 2);
							break;
						case 3:
							ret.mse[i][j][h] += pow(getWithNaN(a.results[i][j].writeCosts[k]) -
								getWithNaN(b.results[i][j].writeCosts[k]), 2);
							break;
						default:
							assert(false);
					}
				}
			}
		}
	}

	for(size_t i = 0; i < ret.mse.length; ++i) {
		for(size_t j = 0; j < ret.mse[i].length; ++j) {
			for(size_t k = 0; k < ret.mse[i][j].length; ++k) {
				ret.mse[i][j][k] /= 101.0;
			}
		}
	}
	return ret;
}

void testPrediction(int Size)(ref LearnRslt!Size result, ref const(ProtocolStats!Size) ps,
		ref const(ProtocolStats!Size) toTest, MMCStat!Size mm)
{
	foreach(size_t i, ref const(GraphStatss!Size) it; 
			[toTest.mcs, toTest.lattice, toTest.grid])
	{
		foreach(ref const(Data!Size) jt; it.data[]) {
			auto rslt = CmpRslt();
			foreach(ref const(GraphStats!Size) kt; jt.values[]) {
				const(GraphStats!Size)* pred = getPrediction!Size(it, jt.key,
						kt, mm
					);
				auto tmpRslt = compare(pred, &kt);
				rslt.add(tmpRslt);
			}
			Array!(LearnRsltDim!Size) store = 
				[result.mcs, result.lattice, result.grid][i];
			foreach(ref kt; store) {
				if(kt.dim == jt.key) {
					kt.rslt.add(rslt);
				}
			}
		}
	}
}

// how good can "mm" can be used to predict the costs or availability
// join 4/5 of rslts with mm and jm into Joined
// predict the avail and costs based on mm for all 1/5 graphs of rslts
// calc MSE against real value
void doLearning(int Size)(string jsonFileName) {
	enum numSplits = 5;
	string outdir = format("%s_Learning/", jsonFileName);
	Array!(GraphWithProperties!Size) graphs = loadGraphs!Size(jsonFileName);
	logf("%s", graphs.length);
	Array!LNTDimensions dims = genDims(graphs[0].graph.length);
	ProtocolStats!(Size) rslts = loadResultss(graphs, jsonFileName);
	rslts.validate();

	Array!(ProtocolStats!Size) splits = split(rslts, numSplits);
	foreach(ref it; splits) {
		it.validate();
	}


	auto permu = Permutations(cast(int)cstatsArray.length, 1, cast(int)cstatsArray.length);
	foreach(perm; permu) {
		auto mm = new MMCStat!32();
		auto learnRsltPerm = LearnRslt!(Size)(&rslts);
		for(size_t sp = 0; sp < numSplits; ++sp) {
			logf("begin");
			logf("%s %s", sp, perm.count());
			for(int j = 0; j < cstatsArray.length; ++j) {
				if(perm.test(j)) {
					mm.insertIStat(cstatsArray[j]);
				}
			}

			ProtocolStats!Size joined = join(splits, sp);
			joined.validate();
			sort!Size(joined, mm);
			assert(checkSorted(joined, mm));
			joined.validate();

			logf("rslt.mcs %s", joined.mcs.data.length);
			logf("rslt.lattice %s", joined.lattice.data.length);
			logf("rslt.grid %s", joined.grid.data.length);
			foreach(jt; joined.mcs.data[]) {
				logf("mcs %s", jt.values.length);
			}
			foreach(jt; joined.lattice.data[]) {
				logf("lattice %s", jt.values.length);
			}
			foreach(jt; joined.grid.data[]) {
				logf("grid %s", jt.values.length);
			}

			joinData(joined, mm);
			
			testPrediction(learnRsltPerm, joined, splits[sp], mm);

			mm.clear();
			logf("end\n");
		}
		learnRsltPerm.print();
	}
}

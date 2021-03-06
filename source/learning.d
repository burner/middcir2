module learning;

import std.stdio;
import std.container.array;
import std.format : format, formattedWrite;
import std.algorithm.sorting : sort, nextPermutation;
import std.algorithm.comparison : max;
import std.meta : AliasSeq;
import std.exception : enforce;
import std.experimental.logger;
import std.math : isNaN, pow, approxEqual, sqrt;
import std.conv : to;

import fixedsizearray;
import exceptionhandling;

import statsanalysis;
import permutation;
import bitsetmodule;
import protocols;

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
	//new CStat!(BetweenneesMedian,32), 
	new CStat!(BetweenneesMin,32), 
	new CStat!(BetweenneesMax,32), 
	new CStat!(BetweenneesAverage,32),
	//new CStat!(BetweenneesMode,32),

	new CStat!(DiameterAverage,32), 
	//new CStat!(DiameterMedian,32), 
	new CStat!(DiameterMax,32), 
	new CStat!(DiameterMin,32), 
	//new CStat!(DiameterMode,32),

	new CStat!(Connectivity,32), 

	new CStat!(DegreeAverage,32), 
	//new CStat!(DegreeMedian,32), 
	//new CStat!(DegreeMode,32), 
	new CStat!(DegreeMin,32), 
	new CStat!(DegreeMax,32), 
];

struct MaxMeasures {
	double maxBetweenness;
	double maxDiameter;
	double maxConnectivity;
	double maxDegree;
}

MaxMeasures getMaxMeasure(int Size)(ref const(Array!(GraphWithProperties!Size)) gs) {
	MaxMeasures mm;
	mm.maxBetweenness = 0.0;
	mm.maxDiameter = 0.0;
	mm.maxConnectivity = 0.0;
	mm.maxDegree = 0.0;

	foreach(it; gs[]) {
		mm.maxBetweenness = max(mm.maxBetweenness, it.betweenness.max);
		mm.maxDiameter = max(mm.maxDiameter, it.diameter.max);
		mm.maxConnectivity = max(mm.maxConnectivity, it.connectivity);
		mm.maxDegree = max(mm.maxDegree, it.degree.max);
	}

	mm.maxBetweenness *= 10;
	mm.maxDiameter *= 10;
	mm.maxConnectivity *= 10;
	mm.maxDegree *= 10;

	return mm;
}

void standardizeProperties(int Size)(ref Array!(GraphWithProperties!Size) gs) {
	import exceptionhandling;

	const mm = getMaxMeasure!(Size)(gs);

	foreach(ref it; gs[]) {
		it.diameter.min = it.diameter.min / mm.maxDiameter;
		it.diameter.average = it.diameter.average / mm.maxDiameter;
		it.diameter.median = it.diameter.median / mm.maxDiameter;
		it.diameter.mode = it.diameter.mode / mm.maxDiameter;
		it.diameter.max = it.diameter.max / mm.maxDiameter;

		it.degree.min = it.degree.min / mm.maxDegree;
		it.degree.average = it.degree.average / mm.maxDegree;
		it.degree.median = it.degree.median / mm.maxDegree;
		it.degree.mode = it.degree.mode / mm.maxDegree;
		it.degree.max = it.degree.max / mm.maxDegree;

		it.betweenness.min = it.betweenness.min / mm.maxConnectivity;
		it.betweenness.average = it.betweenness.average / mm.maxConnectivity;
		it.betweenness.median = it.betweenness.median / mm.maxConnectivity;
		it.betweenness.mode = it.betweenness.mode / mm.maxConnectivity;
		it.betweenness.max = it.betweenness.max / mm.maxConnectivity;

		it.connectivity = it.connectivity / mm.maxConnectivity;
	}

	foreach(ref const it; gs[]) {
		ensure(!isNaN(it.diameter.min));
		ensure(it.diameter.min >= 0.0);
		ensure(it.diameter.min <= 10.0);

		ensure(!isNaN(it.diameter.average));
		ensure(it.diameter.average >= 0.0);
		ensure(it.diameter.average <= 10.0);

		ensure(!isNaN(it.diameter.median));
		ensure(it.diameter.median >= 0.0);
		ensure(it.diameter.median <= 10.0);

		ensure(!isNaN(it.diameter.mode));
		ensure(it.diameter.mode >= 0.0);
		ensure(it.diameter.mode <= 10.0);

		ensure(!isNaN(it.diameter.max));
		ensure(it.diameter.max >= 0.0);
		ensure(it.diameter.max <= 10.0);

		ensure(!isNaN(it.degree.min));
		ensure(it.degree.min >= 0.0);
		ensure(it.degree.min <= 10.0);

		ensure(!isNaN(it.degree.average));
		ensure(it.degree.average >= 0.0);
		ensure(it.degree.average <= 10.0);

		ensure(!isNaN(it.degree.median));
		ensure(it.degree.median >= 0.0);
		ensure(it.degree.median <= 10.0);

		ensure(!isNaN(it.degree.mode));
		ensure(it.degree.mode >= 0.0);
		ensure(it.degree.mode <= 10.0);

		ensure(!isNaN(it.degree.max));
		ensure(it.degree.max >= 0.0);
		ensure(it.degree.max <= 10.0);

		ensure(!isNaN(it.betweenness.min));
		ensure(it.betweenness.min >= 0.0);
		ensure(it.betweenness.min <= 10.0);

		ensure(!isNaN(it.betweenness.average));
		ensure(it.betweenness.average >= 0.0);
		ensure(it.betweenness.average <= 10.0);

		ensure(!isNaN(it.betweenness.median));
		ensure(it.betweenness.median >= 0.0);
		ensure(it.betweenness.median <= 10.0);

		ensure(!isNaN(it.betweenness.mode));
		ensure(it.betweenness.mode >= 0.0);
		ensure(it.betweenness.mode <= 10.0);

		ensure(!isNaN(it.betweenness.max));
		ensure(it.betweenness.max >= 0.0);
		ensure(it.betweenness.max <= 10.0);

		ensure(!isNaN(it.connectivity));
		ensure(it.connectivity >= 0.0);
		ensure(it.connectivity <= 10.0);
	}
}

class MMCStat(int Size) {
	FixedSizeArray!(IStat!Size) cstats;
	string name;

	string getName() const {
		return this.name;
	}

	bool less(const(GraphStats!Size) a, 
			const(GraphStats!Size) b) const nothrow
	{
		import std.math : approxEqual;

		try {
			foreach(it; this.cstats) {
				if(approxEqual(it.select(a), it.select(b), 0.000_000_1)) {
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
			if(!approxEqual(it.select(a), it.select(b), 0.000_000_1)) {
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
			if(approxEqual(it.select(a), it.select(b), 0.000_000_1)) {
				++sum;
			}
		}
		return sum;
	}

	void insertIStat(IStat!Size ne) {
		this.cstats.insertBack(ne);
		this.name ~= ne.name;
	}

	void clear() {
		this.cstats.removeAll();
		this.name = "";
	}
}

unittest {
	IStat!32 n = new CStat!(Connectivity, 32)();
	n = new CStat!(DiameterAverage,32)();

	int count;
	for(int i = 0; i < cstatsArray.length; ++i) {
		auto permu = Permutations(cast(int)cstatsArray.length, i, 
				cast(int)cstatsArray.length
			);
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
	//return joinGraphStatsAvg!Size(old, mm);
	return joinGraphStatsMin!Size(old, mm);
}

Array!(GraphStats!Size) joinGraphStatsIgnoreSame(int Size)(
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

Array!(GraphStats!Size) joinGraphStatsAvg(int Size)(
		ref const(Array!(GraphStats!Size)) old,
		const(MMCStat!Size) mm)
{
	Array!(GraphStats!Size) ret;

	int addCount = 1;
	foreach(ref it; old[]) {
		if(ret.empty) {
			ret.insertBack(GraphStats!Size(it));
		} else {
			if(mm.equal(ret.back, it)) {
				ret.back.add(it);
				++addCount;
			} else {
				if(addCount > 1) {
					ret.back.div(addCount);
					addCount = 1;
				}
				ret.insertBack(GraphStats!Size(it));
			}
		}
	}
	if(addCount > 1) {
		ret.back.div(addCount);
		addCount = 1;
	}

	return ret;
}

Result[7][2] minResult(int Size)(ref Array!(GraphStats!Size) arr) {
	import std.algorithm.comparison : min;
	Result[7][2] ret;
	for(size_t i = 0; i < ret.length; ++i) {
		for(size_t j = 0; j < ret.length; ++j) {
			ret[i][j] = getResult(9999.9); // Every real value should be smaller
			foreach(it; arr[]) {
				for(size_t idx = 0; idx < 101; ++idx) {
					ret[i][j].readAvail[idx] =
						min(
							it.results[i][j].readAvail[idx],
						   	ret[i][j].readAvail[idx]
						);
					ret[i][j].writeAvail[idx] =
						min(
							it.results[i][j].writeAvail[idx],
						   	ret[i][j].writeAvail[idx]
						);
					ret[i][j].readCosts[idx] =
						min(
							it.results[i][j].readCosts[idx],
						   	ret[i][j].readCosts[idx]
						);
					ret[i][j].writeCosts[idx] =
						min(
							it.results[i][j].writeCosts[idx],
						   	ret[i][j].writeCosts[idx]
						);
				}
			}
		}
	}
	return ret;
}

Array!(GraphStats!Size) joinGraphStatsMin(int Size)(
		ref const(Array!(GraphStats!Size)) old,
		const(MMCStat!Size) mm)
{
	return joinGraphStatsMulti!(Size, minResult)(old, mm);
}

Array!(GraphStats!Size) joinGraphStatsMulti(int Size, alias Func)(
		ref const(Array!(GraphStats!Size)) old,
		const(MMCStat!Size) mm)
{
	import utils : removeAll;
	Array!(GraphStats!Size) ret;

	Array!(GraphStats!(Size)) tmp;
	int addCount = 1;
	foreach(ref it; old[]) {
		if(ret.empty) {
			ret.insertBack(GraphStats!Size(it));
		} else {
			if(mm.equal(ret.back, it)) {
				tmp.insertBack(GraphStats!(Size)(it));
				++addCount;
			} else {
				if(addCount > 1) {
					tmp.insertBack(ret.back);
					ret.back.results = Func!Size(tmp);
					tmp.removeAll();
					addCount = 1;
				}
				ret.insertBack(GraphStats!Size(it));
			}
		}
	}
	if(addCount > 1) {
		ret.back.results = Func!Size(tmp);
		addCount = 1;
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
		//logf("lattice before length %s", it.values.length);
		it = joinData!(Size)(it, mm);
		//logf("lattice after length %s", it.values.length);
	}
	foreach(ref it; ps.grid.data[]) {
		//logf("grid before length %s", it.values.length);
		it = joinData!(Size)(it, mm);
		//logf("grid after length %s", it.values.length);
	}
}

unittest {
	GraphWithProperties!(16)[5] graphs;
	graphs[0].connectivity = 0.3;
	graphs[1].connectivity = 0.4;
	graphs[2].connectivity = 0.4;
	graphs[3].connectivity = 0.4;
	graphs[4].connectivity = 0.7;

	GraphStats!(16)[5] graphStats;
	graphStats[0].graph = &graphs[0];
	graphStats[0].results[0][0].readAvail[] = 0.1;
	graphStats[1].graph = &graphs[1];
	graphStats[1].results[0][0].readAvail[] = 1.0;
	graphStats[2].graph = &graphs[2];
	graphStats[2].results[0][0].readAvail[] = 2.0;
	graphStats[3].graph = &graphs[3];
	graphStats[3].results[0][0].readAvail[] = 3.0;
	graphStats[4].graph = &graphs[4];
	graphStats[4].results[0][0].readAvail[] = 0.2;

	Array!(GraphStats!16) arr;
	foreach(it; graphStats) {
		arr.insertBack(it);
	}

	auto cs = new CStat!(Connectivity,16)();
	auto mm = new MMCStat!16();
	mm.insertIStat(cs);
	auto ret = joinGraphStatsAvg!16(arr, mm);

	assert(ret.length == 3);

	foreach(it; ret[0].results[0][0].readAvail[]) {
		assert(approxEqual(it, 0.1));
	}

	foreach(idx, it; ret[1].results[0][0].readAvail[]) {
		assert(approxEqual(it, 2.0), format("%s %s %s", idx, it, 2.0));
	}

	foreach(it; ret[2].results[0][0].readAvail[]) {
		assert(approxEqual(it, 0.2));
	}
}

unittest {
	GraphWithProperties!(16)[5] graphs;
	graphs[0].connectivity = 0.3;
	graphs[1].connectivity = 0.4;
	graphs[2].connectivity = 0.4;
	graphs[3].connectivity = 0.4;
	graphs[4].connectivity = 0.7;

	GraphStats!(16)[5] graphStats;
	graphStats[0].graph = &graphs[0];
	graphStats[0].results[0][0].readAvail[] = 0.1;
	graphStats[1].graph = &graphs[1];
	graphStats[1].results[0][0].readAvail[] = 1.0;
	graphStats[2].graph = &graphs[2];
	graphStats[2].results[0][0].readAvail[] = 2.0;
	graphStats[3].graph = &graphs[3];
	graphStats[3].results[0][0].readAvail[] = 3.0;
	graphStats[4].graph = &graphs[4];
	graphStats[4].results[0][0].readAvail[] = 0.2;

	Array!(GraphStats!16) arr;
	foreach(it; graphStats) {
		arr.insertBack(it);
	}

	auto cs = new CStat!(Connectivity,16)();
	auto mm = new MMCStat!16();
	mm.insertIStat(cs);
	auto ret = joinGraphStatsIgnoreSame!16(arr, mm);

	assert(ret.length == 3);

	foreach(it; ret[0].results[0][0].readAvail[]) {
		assert(approxEqual(it, 0.1));
	}

	foreach(idx, it; ret[1].results[0][0].readAvail[]) {
		assert(approxEqual(it, 1.0));
	}

	foreach(it; ret[2].results[0][0].readAvail[]) {
		assert(approxEqual(it, 0.2));
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

struct LearnRsltDim(int Size) {
	LNTDimensions dim;
	CmpRslt rslt;

	this(LNTDimensions dim) {
		this.dim = dim;
		this.rslt = CmpRslt();
	}

	void toLatex(LTW)(ref LTW ltw) const {
		formattedWrite(ltw, "\\subsubsection{Dimension %s:%s}\n",
			this.dim.width, this.dim.height);

		foreach(jdx, it; ["Avail", "Costs"]) {
			formattedWrite(ltw, "\\paragraph{%s Measures}\n",
				it);

			foreach(idx, row; readOverWriteLevel) {
				formattedWrite(ltw, "\\subparagraph{Read over Write %.2f}\n",
					row);
				formattedWrite(ltw, "\\begin{tabular}{l r}\n");
				formattedWrite(ltw, "Read Avail & %.10f \\\\ \n",
					this.rslt.mse[jdx][idx][0]
				);
				formattedWrite(ltw, "Write Avail & %.10f \\\\ \n",
					this.rslt.mse[jdx][idx][1]
				);
				formattedWrite(ltw, "Read Costs & %.10f \\\\ \n",
					this.rslt.mse[jdx][idx][2]
				);
				formattedWrite(ltw, "Write Costs & %.10f \\\\ \n",
					this.rslt.mse[jdx][idx][3]
				);
				formattedWrite(ltw, "\\end{tabular}\n");
			}
			formattedWrite(ltw, "\n");
		}
		formattedWrite(ltw, "\n");
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

	void toLatex(LTW)(ref LTW ltw) const {
		this.toLatex(ltw, "MCS", this.mcs);	
		this.toLatex(ltw, "Lattice", this.lattice);	
		this.toLatex(ltw, "Grid", this.grid);	
	}

	void toLatex(LTW)(ref LTW ltw, string name, 
			ref const(Array!(LearnRsltDim!Size)) arr) const
	{
		formattedWrite(ltw, "\\subsection{%s}\n", name);
		foreach(ref it; arr[]) {
			it.toLatex(ltw);
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

pragma(inline, true)
double getWithNaN(double input) {
	return isNaN(input) ? 0.0 : input;
}

pragma(inline, true)
void mse(ref double store, double a, double b) {
	enforce(!isNaN(store));
	enforce(!isNaN(a));
	enforce(!isNaN(b));
	//logf("%.9f %.9f", a, b);
	store += pow(getWithNaN(a) - getWithNaN(b), 2);
}

CmpRslt compare(int Size)(const(GraphStats!Size)* pred,
	   	const(GraphStats!Size)* actual) 
{
	enforce(pred !is null);
	enforce(actual !is null);

	auto ret = CmpRslt();
	for(size_t i = 0; i < pred.results.length; ++i) {
		for(size_t j = 0; j < pred.results[i].length; ++j) {
			for(size_t k = 0; k < 101; ++k) {
				inner: for(size_t h = 0; h < 4; ++h) {
					switch(h) {
						case 0:
							mse(ret.mse[i][j][h],
									pred.results[i][j].readAvail[k],
									actual.results[i][j].readAvail[k],
								);
							continue inner;
						case 1:
							mse(ret.mse[i][j][h],
									pred.results[i][j].writeAvail[k],
									actual.results[i][j].writeAvail[k],
								);
							continue inner;
						case 2:
							mse(ret.mse[i][j][h],
									pred.results[i][j].readCosts[k],
									actual.results[i][j].readCosts[k],
								);
							continue inner;
						case 3:
							mse(ret.mse[i][j][h],
									pred.results[i][j].writeCosts[k],
									actual.results[i][j].writeCosts[k],
								);
							continue inner;
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

void testPrediction(int Size)(ref LearnRslt!Size result, 
		ref const(ProtocolStats!Size) ps, ref const(ProtocolStats!Size) toTest,
	   	MMCStat!Size mm)
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

struct CompareEntries(int Size) {
	double value;
	MMCStat!Size mm;
}

struct CompareEntry(int Size) {
	LNTDimensions dim;
	CompareEntries!(Size)[4][7][2] entries;

	void toLatex(LTW)(ref LTW ltw) const {
		formattedWrite(ltw, "\\subsection{Dimension %s:%s}\n",
			this.dim.width, this.dim.height);

		foreach(jdx, it; ["Avail", "Costs"]) {
			formattedWrite(ltw, "\\subsubsection{%s Measures}\n",
				it);

			foreach(idx, row; readOverWriteLevel) {
				formattedWrite(ltw, "\\paragraph{Read over Write %.2f}\n",
					row);
				formattedWrite(ltw, "\\begin{tabular}{l r l}\n");
				formattedWrite(ltw, "Read Avail & %.10f & %s \\\\ \n",
					this.entries[jdx][idx][0].value, 
					this.entries[jdx][idx][0].mm.getName()
				);
				formattedWrite(ltw, "Write Avail & %.10f & %s \\\\ \n",
					this.entries[jdx][idx][1].value, 
					this.entries[jdx][idx][1].mm.getName()
				);
				formattedWrite(ltw, "Read Costs & %.10f & %s \\\\ \n",
					this.entries[jdx][idx][2].value, 
					this.entries[jdx][idx][2].mm.getName()
				);
				formattedWrite(ltw, "Write Costs & %.10f & %s \\\\ \n",
					this.entries[jdx][idx][3].value, 
					this.entries[jdx][idx][3].mm.getName()
				);
				formattedWrite(ltw, "\\end{tabular}\n");
			}
			formattedWrite(ltw, "\n");
		}
		formattedWrite(ltw, "\n");
	}
}

struct Compare(int Size) {
	Array!(CompareEntry!Size) mcs;
	Array!(CompareEntry!Size) grid;
	Array!(CompareEntry!Size) lattice;

	void print() const {
		print("MCS", this.mcs);
		print("Lattice", this.lattice);
		print("Grid", this.grid);
	}

	static void print(string name, ref const(Array!(CompareEntry!Size)) arr) {
		logf(name);
		foreach(ref it; arr[]) {
			writefln("\t%d:%d", it.dim.width, it.dim.height);
			for(size_t i = 0; i < it.entries.length; ++i) {
				for(size_t j = 0; j < it.entries[i].length; ++j) {
					for(size_t k = 0; k < it.entries[i][j].length; ++k) {
						writefln("\t\t%d %d %d %.9f %s",
							i, j, k, it.entries[i][j][k].value,
							it.entries[i][j][k].mm.getName());
					}
				}
			}
		}
	}

	void toLatex(LTW)(ref LTW ltw) const {
		this.toLatex(ltw, "MCS", this.mcs);	
		this.toLatex(ltw, "Lattice", this.lattice);	
		this.toLatex(ltw, "Grid", this.grid);	
	}

	void toLatex(LTW)(ref LTW ltw, string name, 
			ref const(Array!(CompareEntry!Size)) arr) const
	{
		formattedWrite(ltw, "\\section{%s}\n", name);
		foreach(ref it; arr[]) {
			it.toLatex(ltw);
		}
	}

	void compare(ref LearnRslt!Size rslt, MMCStat!Size mm) {
		this.compareImpl(rslt.mcs, this.mcs, mm);
		this.compareImpl(rslt.lattice, this.lattice, mm);
		this.compareImpl(rslt.grid, this.grid, mm);
	}

	void compareImpl(ref const(Array!(LearnRsltDim!Size)) rslt, 
			ref Array!(CompareEntry!Size) store, MMCStat!Size mm)
	{
		outer: foreach(ref it; rslt[]) {
			foreach(ref iit; store[]) {
				if(it.dim == iit.dim) {
					CompareEntries!(Size)[4][7][2] tmp = buildSums(it.rslt, mm);
					compareSwap(iit.entries, tmp);
					continue outer;
				}
			}
			CompareEntries!(Size)[4][7][2] tmp = buildSums(it.rslt, mm);
			store.insertBack(CompareEntry!Size(it.dim, tmp));
		}
	}

	void compareSwap(ref CompareEntries!(Size)[4][7][2] store, 
			ref CompareEntries!(Size)[4][7][2] tmp)
	{
		for(size_t i = 0; i < store.length; ++i) {
			for(size_t j = 0; j < store[i].length; ++j) {
				for(size_t k = 0; k < store[i][j].length; ++k) {
					if(tmp[i][j][k].value < store[i][j][k].value) {
						store[i][j][k].value = tmp[i][j][k].value;
						store[i][j][k].mm = tmp[i][j][k].mm;
					}
				}
			}
		}
	}

	static CompareEntries!(Size)[4][7][2] buildSums(ref const(CmpRslt) cr,
			MMCStat!Size mm) 
	{
		CompareEntries!(Size)[4][7][2] ret;
		for(size_t i = 0; i < ret.length; ++i) {
			for(size_t j = 0; j < ret[i].length; ++j) {
				for(size_t k = 0; k < ret[i][j].length; ++k) {
					ret[i][j][k].value = cr.mse[i][j][k];
					ret[i][j][k].mm = mm;
				}
			}
		}
		return ret;
	}
}

void prepareLatexDoc(LTW)(ref LTW ltw) {
	formattedWrite(ltw, "\\documentclass{scrbook}\n");
	formattedWrite(ltw, "\\usepackage{graphicx}\n");
	formattedWrite(ltw, "\\usepackage{standalone}\n");
	formattedWrite(ltw, "\\usepackage{float}\n");
	formattedWrite(ltw, "\\usepackage{multirow}\n");
	formattedWrite(ltw, "\\usepackage{hyperref}\n");
	formattedWrite(ltw, "\\usepackage{placeins}\n");
	formattedWrite(ltw, "\\usepackage[cm]{fullpage}\n");
	formattedWrite(ltw, "\\usepackage{subcaption}\n");
	formattedWrite(ltw, `\usepackage{tikz}
\usepackage{pgfplots}
\usetikzlibrary{decorations.markings, arrows, decorations.pathmorphing,
   backgrounds, positioning, fit, shapes.geometric}
	\tikzstyle{place} = [shape=circle,
    draw, align=center,minimum width=0.70cm,
    top color=white, bottom color=blue!20]
\setcounter{tocdepth}{5}
\begin{document}
`);
}

struct GraphStatsDistance(int Size) {
	GraphStats!(Size)* ptr;
	double distance;

	int opCmp(ref const GraphStatsDistance!(Size) s) const {
		if(this.distance < s.distance) {
			return -1;
		} else if(this.distance > s.distance) {
			return 1;
		} else if(approxEqual(this.distance, s.distance)) {
			return 0;
		}
		throw new Exception(format(
			"GraphStatsDistance opCmp failed this '%s' other '%s'",
			this.distance, s.distance
		));
	}
}

double calcDistance(int Size)(ref const(GraphStats!Size) a,
		ref const(GraphStats!Size) b, const(MMCStat!Size) mm)
{
	double ret = 0.0;
	foreach(ref it; mm.cstats[]) {
		ret += pow(it.select(b) - it.select(a), 2.0);
	}

	return sqrt(ret);
}

FixedSizeArray!(GraphStatsDistance!(Size),32) getKNext(int Size)(
		ref Array!(ProtocolStats!Size) pss,
		const(size_t) which,
		ref const(LNTDimensions) dim, ref const(GraphStats!Size) toFind, 
		const(MMCStat!Size) mm, const(size_t) k)
{
	FixedSizeArray!(GraphStatsDistance!(Size),32) ret;
	foreach(ref psIt; pss[]) {
		GraphStatss!(Size)* ps = 
			(which == 0 ? &psIt.mcs 
				: (which == 1 ? &psIt.lattice
					: (which == 2 ? &psIt.grid : null)
				)
			);
		ensure(ps !is null);
		ensure((*ps).data.length > 0);
		foreach(ref data; (*ps).data[]) {
			if(data.key == dim) {
				foreach(ref ss; data.values[]) {
					const dis = calcDistance!Size(toFind, ss, mm);
					ret.insertBack(GraphStatsDistance!(Size)(&ss, dis));
					sort(ret[]);
					if(ret.length > k) {
						ret.removeBack();
					}
				}
			} else {
				logf("%s %s", data.key, dim);
			}
		}
	}
	ensure(ret.length == k);
	return ret;
}

GraphStats!(Size) combineMin(int Size)
		(ref FixedSizeArray!(GraphStatsDistance!(Size)) arr)
{
	ensure(arr.length > 0);
	return *(arr.front.ptr);
}

GraphStats!(Size) combineMax(int Size)
		(ref FixedSizeArray!(GraphStatsDistance!(Size)) arr)
{
	ensure(arr.length > 0);
	return *(arr.back.ptr);
}

GraphStats!(Size) combineAvg(int Size)
		(ref FixedSizeArray!(GraphStatsDistance!(Size)) arr)
{
	ensure(arr.length > 0);
	GraphStats!(Size) accu = *(arr.front.ptr);
	if(arr.length > 1) {
		foreach(ref it; arr[1 .. arr.length]) {
			accu.add(*(it.ptr));
		}
	}
	accu.div(to!int(arr.length));
	return accu;
}

GraphStats!(Size) combine(int Size, alias Func)
		(ref FixedSizeArray!(GraphStatsDistance!(Size)) arr)
{
	return Func(arr);
}

ref Array!(LearnRsltDim!Size) getLearnRsltDim(int Size)(
		ref LearnRslt!(Size) rslt, const size_t i)
{
	switch(i) {
		case 0:
			return rslt.mcs;
		case 1:
			return rslt.lattice;
		case 2:
			return rslt.grid;
		default:
			assert(false);
	}
	assert(false);
}


void knn(int Size, alias Func)(
		Array!(ProtocolStats!Size) splits, const(size_t) fold,
	   	ref LearnRslt!(Size) rslt, const(size_t) k, const(MMCStat!Size) mm) 
{
	foreach(size_t i, ref const(GraphStatss!Size) it; 
			[splits[fold].mcs, splits[fold].lattice, splits[fold].grid])
	{
		foreach(ref const(Data!Size) jt; it.data[]) {
			//auto rsltTmp = CmpRslt();
			foreach(ref const(GraphStats!Size) kt; jt.values[]) {
				FixedSizeArray!(GraphStatsDistance!(Size),32) preds = 
					getKNext!Size(splits, i, jt.key, kt, mm, fold);
				logf("preds length %s", preds.length);
				GraphStats!(Size) tmp = combine!(Size,Func)(preds);
				auto tmpRslt = compare(&tmp, &kt);

				foreach(ref lt; getLearnRsltDim!(Size)(rslt, i)[]) {
					if(lt.dim == jt.key) {
						lt.rslt.add(tmpRslt);
					}
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
	standardizeProperties!(Size)(graphs);
	logf("%s", graphs.length);
	Array!LNTDimensions dims = genDims(graphs[0].graph.length);
	ProtocolStats!(Size) rslts = loadResultss(graphs, jsonFileName);
	rslts.validate();

	Array!(ProtocolStats!Size) splits = split(rslts, numSplits);
	foreach(ref it; splits) {
		it.validate();
	}

	auto f = File(jsonFileName ~ "ai.tex", "w");
	auto ltw = f.lockingTextWriter();
	prepareLatexDoc(ltw);

	Compare!Size results;

	auto permu = Permutations(cast(int)cstatsArray.length, 1, cast(int)cstatsArray.length);
	//auto permu = Permutations(cast(int)cstatsArray.length, 3, 4);
	formattedWrite(ltw, "\\chapter{Permutations}\n");
	foreach(perm; permu) {
		logf("begin");
		auto mm = new MMCStat!32();
		for(int j = 0; j < cstatsArray.length; ++j) {
			if(perm.test(j)) {
				mm.insertIStat(cstatsArray[j]);
			}
		}

		formattedWrite(ltw, "\\section{%s}\n", mm.getName());
		auto learnRsltPerm = LearnRslt!(Size)(&rslts);

		for(size_t sp = 0; sp < numSplits; ++sp) {
			knn!(Size,combineAvg)(splits, sp, learnRsltPerm, numSplits, mm);
			//logf("%s %s", sp, perm.count());

			//ProtocolStats!Size joined = join(splits, sp);
			//joined.validate();
			//sort!Size(joined, mm);
			//assert(checkSorted(joined, mm));
			//joined.validate();

			//logf("rslt.mcs %s", joined.mcs.data.length);
			//logf("rslt.lattice %s", joined.lattice.data.length);
			//logf("rslt.grid %s", joined.grid.data.length);
			//foreach(jt; joined.mcs.data[]) {
			//	logf("mcs %s", jt.values.length);
			//}
			//foreach(jt; joined.lattice.data[]) {
			//	logf("lattice %s", jt.values.length);
			//}
			//foreach(jt; joined.grid.data[]) {
			//	logf("grid %s", jt.values.length);
			//}

			//joinData(joined, mm);
			//
			//testPrediction(learnRsltPerm, joined, splits[sp], mm);
			//learnRsltPerm.print();
		}

		logf("%s", mm.getName());
		learnRsltPerm.print();
		learnRsltPerm.toLatex(ltw);
		results.compare(learnRsltPerm, mm);
		//results.print();
		logf("end\n");
	}
	formattedWrite(ltw, "\\chapter{Result}\n");
	results.toLatex(ltw);
	formattedWrite(ltw, "\\end{document}\n");
}

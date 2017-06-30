module learning2;

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
	int measure;
	this(string name, int measure) {
		this.name = name;
		this.measure = measure;
	}
	abstract @property string XLabel() const;
	abstract double select(const(GraphStats!Size) g) const;
	abstract double select(const(GraphWithProperties!Size) g) const;
}

class CStat(alias Stat, int Size) : IStat!Size {
	this(int measure) {
		super(shortName(Stat!Size.XLabel), measure);
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
	//new CStat!(BetweenneesMedian,32)(0), 
	new CStat!(BetweenneesMin,32)(0), 
	new CStat!(BetweenneesMax,32)(0), 
	new CStat!(BetweenneesAverage,32)(0),
	//new CStat!(BetweenneesMode,32)(0),

	//new CStat!(DiameterAverage,32)(1), 
	new CStat!(DiameterMedian,32)(1), 
	new CStat!(DiameterMax,32)(1), 
	new CStat!(DiameterMin,32)(1), 
	//new CStat!(DiameterMode,32)(1),

	new CStat!(Connectivity,32)(2), 

	//new CStat!(DegreeAverage,32)(3), 
	new CStat!(DegreeMedian,32)(3), 
	new CStat!(DegreeMode,32)(3), 
	new CStat!(DegreeMin,32)(3), 
	//new CStat!(DegreeMax,32)(3), 
];

struct MaxMeasures {
	double maxBetweenness;
	double maxDiameter;
	double maxConnectivity;
	double maxDegree;
}

MaxMeasures getMaxMeasure(int Size)(
		ref const(Array!(GraphWithProperties!Size)) gs) 
{
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


OptimalMappings!(Size) loadResults(int Size)(
		ref Array!(GraphWithProperties!Size) graphs,
	   	string filename, string protocol, const long numNodes)
{
	import std.format : format;
	import std.file : exists;
	typeof(return) ret;
	Array!LNTDimensions dims;
	if(protocol == "MCS") {
		dims.insertBack(LNTDimensions(0, 0));
	} else {
   		dims = genDims(numNodes);
	}
	foreach(ref dim; dims[]) {
		ret.data.insertBack(OptMapData!(Size)(dim, Array!(GraphStats!Size)()));
		foreach(ref g; graphs[]) {
			auto fn = format("%s_Results/%05d", filename, g.graph.id);
			if(!exists(fn)) {
				continue;
			}
			auto tmp = GraphStats!(Size)(&g, filename, protocol, dim);
			if(tmp.wasLoaded()) {
				ret.data.back.values.insertBack(tmp);
			} else {
				logf("%s %s", fn, dim);
			}
		}
	}
	return ret;
}

struct OptMapData(int Size) {
	LNTDimensions key;
	Array!(GraphStats!Size) values;

	this(LNTDimensions key, Array!(GraphStats!Size) values) {
		this.key = key;
		this.values = values;
	}

	this(LNTDimensions key) {
		this.key = key;
	}

	void validate() const {
		foreach(ref it; this.values[]) {
			it.validate();
		}
	}

	void scale() {
		foreach(ref it; this.values[]) {
			it.scale();
		}
	}
}

struct OptimalMappings(int Size) {
	Array!(OptMapData!(Size)) data;

	void validate() const {
		foreach(ref it; this.data[]) {
			it.validate();
		}
	}

	void scale() {
		foreach(ref it; this.data[]) {
			it.scale();
		}
	}
}

struct OptCmpRslt {
	double[4][7][2] data;

	static OptCmpRslt opCall() {
		OptCmpRslt ret;
		for(size_t i = 0; i < ret.data.length; ++i) {
			for(size_t j = 0; j < ret.data[i].length; ++j) {
				for(size_t k = 0; k < ret.data[i][j].length; ++k) {
					ret.data[i][j][k] = 0.0;
				}
			}
		}
		return ret;
	}

	void add(OptCmpRslt other) {
		for(size_t i = 0; i < data.length; ++i) {
			for(size_t j = 0; j < data[i].length; ++j) {
				for(size_t k = 0; k < data[i][j].length; ++k) {
					this.data[i][j][k] += other.data[i][j][k];
				}
			}
		}
	}
}

Array!(OptimalMappings!(Size)) split(int Size)(ref OptimalMappings!(Size) old, 
		const size_t numSplits)
{
	import std.range : chunks;

	Array!(OptimalMappings!(Size)) ret;
	for(size_t i = 0; i < numSplits; ++i) {
		ret.insertBack(OptimalMappings!Size());
	}

	for(size_t i = 0; i < old.data.length; ++i) {
		for(size_t j = 0; j < numSplits; ++j) {
			ret[j].data.insertBack(OptMapData!Size(old.data[i].key));
		}
	}

	for(size_t i = 0; i < old.data.length; ++i) {
		auto c = chunks(old.data[i].values[], 
				old.data[i].values.length / numSplits
			);
		for(size_t j = 0; j < numSplits; ++j) {
			ret[j].data[i].values.insertBack(c[i]);
		}
	}

	ensure(ret.length == numSplits);
	//foreach(ref it; ret[]) {
	//	it.validate();
	//}

	return ret;
}

struct OptLearnRsltDim(int Size) {
	LNTDimensions dim;
	OptCmpRslt rslt;

	this(LNTDimensions dim) {
		this.dim = dim;
		this.rslt = OptCmpRslt();
	}

	void toLatex(LTW)(ref LTW ltw) const {
		formattedWrite(ltw, "\\subsubsection{Dimension %s:%s}\n",
			this.dim.width, this.dim.height);

		foreach(jdx, it; ["Avail", "Costs"]) {
			formattedWrite(ltw, "\\paragraph{%s Measures}\n",
				it);

			size_t idx = 0;
			foreach(row; readOverWriteLevel) {
				formattedWrite(ltw, "\\subparagraph{Read over Write %.2f}\n",
					row);
				formattedWrite(ltw, "\\begin{tabular}{l r}\n");
				formattedWrite(ltw, "Read Avail & %.10f \\\\ \n",
					this.rslt.data[jdx][idx][0]
				);
				formattedWrite(ltw, "Write Avail & %.10f \\\\ \n",
					this.rslt.data[jdx][idx][1]
				);
				formattedWrite(ltw, "Read Costs & %.10f \\\\ \n",
					this.rslt.data[jdx][idx][2]
				);
				formattedWrite(ltw, "Write Costs & %.10f \\\\ \n",
					this.rslt.data[jdx][idx][3]
				);
				formattedWrite(ltw, "\\end{tabular}\n");
				++idx;
			}
			ensure(idx == 7);
			formattedWrite(ltw, "\n");
		}
		formattedWrite(ltw, "\n");
	}
}

struct OptLearnRslt(int Size) {
	Array!(OptLearnRsltDim!Size) data;

	this(const(OptimalMappings!Size)* ps) {
		foreach(ref it; ps.data[]) {
			this.data.insertBack(OptLearnRsltDim!Size(it.key));
		}
	}

	void print() {
		foreach(ref it; this.data[]) {
			logf("%s:%s %s", it.dim.width, it.dim.height, it.rslt);
		}
	}

	ref OptLearnRsltDim!Size get(const LNTDimensions dim) {
		foreach(ref it; this.data[]) {
			if(it.dim == dim) {
				return it;
			}
		}
		ensure(false, format("Couldn't find OptLearnRsltDim with dim '%s:%s'",
				dim.width, dim.height)
			);
		assert(false);
	}

	void toLatex(LTW)(ref LTW ltw) const {
		foreach(ref it; this.data[]) {
			it.toLatex(ltw);
		}
	}
}

struct OptCompareEntry(int Size) {
	LNTDimensions dim;
	OptCompareEntries!(Size)[4][7][2] entries;

	void toLatex(LTW)(ref LTW ltw) const {
		formattedWrite(ltw, "\\subsection{Dimension %s:%s}\n",
			this.dim.width, this.dim.height);

		foreach(jdx, it; ["Avail", "Costs"]) {
			formattedWrite(ltw, "\\subsubsection{%s Measures}\n",
				it);

			size_t idx = 0;
			foreach(row; readOverWriteLevel) {
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
				++idx;
			}
			ensure(idx == 7);
			formattedWrite(ltw, "\n");
		}
		formattedWrite(ltw, "\n");
	}
}

struct OptCompareEntries(int Size) {
	double value;
	MMCStat!Size mm;
}

struct OptCompare(int Size) {
	Array!(OptCompareEntry!Size) data;

	void compare(ref OptLearnRslt!Size rslt, MMCStat!Size mm) {
		this.compareImpl(rslt.data, mm);
	}

	void compareImpl(ref const(Array!(OptLearnRsltDim!Size)) rslt, 
			MMCStat!Size mm) 
	{
		outer: foreach(ref it; rslt[]) {
			foreach(ref iit; this.data[]) {
				if(it.dim == iit.dim) {
					OptCompareEntries!(Size)[4][7][2] tmp = buildSums(it.rslt, mm);
					compareSwap(iit.entries, tmp);
					continue outer;
				}
			}
			OptCompareEntries!(Size)[4][7][2] tmp = buildSums(it.rslt, mm);
			this.data.insertBack(OptCompareEntry!Size(it.dim, tmp));
		}
	}

	void compareSwap(ref OptCompareEntries!(Size)[4][7][2] store, 
			ref OptCompareEntries!(Size)[4][7][2] tmp)
	{
		const iLen = store.length;
		ensure(iLen == 2);
		for(size_t i = 0; i < iLen; ++i) {
			const jLen = store[i].length;
			ensure(jLen == 7);
			for(size_t j = 0; j < jLen; ++j) {
				const kLen = store[i][j].length;
				ensure(kLen == 4);
				for(size_t k = 0; k < kLen; ++k) {
					if(tmp[i][j][k].value < store[i][j][k].value) {
						store[i][j][k].value = tmp[i][j][k].value;
						store[i][j][k].mm = tmp[i][j][k].mm;
					}
				}
			}
		}
	}

	static OptCompareEntries!(Size)[4][7][2] buildSums(ref const(OptCmpRslt) cr,
			MMCStat!Size mm) 
	{
		OptCompareEntries!(Size)[4][7][2] ret;
		const iLen = ret.length;
		ensure(iLen == 2);
		for(size_t i = 0; i < iLen; ++i) {
			const jLen = ret[i].length;
			ensure(jLen == 7);
			for(size_t j = 0; j < jLen; ++j) {
				const kLen = ret[i][j].length;
				ensure(kLen == 4);
				for(size_t k = 0; k < kLen; ++k) {
					ret[i][j][k].value = cr.data[i][j][k];
					ret[i][j][k].mm = mm;
				}
			}
		}
		return ret;
	}

	void toLatex(LTW)(ref LTW ltw) const
	{
		foreach(ref it; this.data[]) {
			it.toLatex(ltw);
		}
	}
}

GraphStats!(Size) combineMedian(int Size)
		(ref FixedSizeArray!(GraphStatsDistance!(Size)) arr)
{
	ensure(arr.length > 0);
	if(arr.length % 2 == 1) {
		return arr[arr.length / 2].ptr;
	} else {
		if(arr.length > 1) {
			GraphStats!(Size) a = arr[arr.length / 2].ptr;
			GraphStats!(Size) b = arr[(arr.length / 2) + 1].ptr;
			const size_t iLen = a.results.length;
			ensure(iLen == 2);
			for(size_t i = 0; i < iLen; ++i) {
				const size_t jLen = a.results[i].length;
				ensure(jLen == 7);
				for(size_t j = 0; j < jLen; ++j) {
					a.results[i][j].readAvail[] += b.results[i][j].readAvail[];
					a.results[i][j].writeAvail[] += b.results[i][j].writeAvail[];
					a.results[i][j].readCosts[] += b.results[i][j].readCosts[];
					a.results[i][j].writeCosts[] += b.results[i][j].writeCosts[];
				}
			}
			return a;
		} else {
			return arr[arr.length / 2].ptr;
		}
	}
}


GraphStats!(Size) combineMin(int Size)
		(ref FixedSizeArray!(GraphStatsDistance!(Size)) arr)
{
	ensure(arr.length > 0);
	return arr.front.ptr;
}

GraphStats!(Size) combineMax(int Size)
		(ref FixedSizeArray!(GraphStatsDistance!(Size)) arr)
{
	ensure(arr.length > 0);
	return arr.back.ptr;
}

GraphStats!(Size) combineAvg(int Size)
		(ref FixedSizeArray!(GraphStatsDistance!(Size)) arr)
{
	ensure(arr.length > 0);
	GraphStats!(Size) accu = arr.front.ptr;
	if(arr.length > 1) {
		foreach(ref it; arr[1 .. arr.length]) {
			accu.add(it.ptr);
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

OptCmpRslt compare(int Size)(ref const(GraphStats!Size) pred,
	   	ref const(GraphStats!Size) actual) 
{
	pragma(inline, true)
	double getWithNaN(double input) {
		return isNaN(input) ? 0.0 : input;
	}
	
	pragma(inline, true)
	void mse(ref double store, double a, double b) {
		ensure(!isNaN(store));
		ensure(!isNaN(a));
		ensure(!isNaN(b));
		//logf("%.9f %.9f", a, b);
		//store += pow(getWithNaN(a) - getWithNaN(b), 2);
		const an = getWithNaN(a);
		const bn = getWithNaN(b);

		if(an > bn) {
			store = an - bn;
		} else {
			store = bn - an;
		}
	}

	auto ret = OptCmpRslt();
	const iLen = pred.results.length;
	ensure(iLen == 2, format("iLen %d", iLen));
	for(size_t i = 0; i < iLen; ++i) {
		const jLen = pred.results[i].length;
		ensure(jLen == 7, format("jLen %d", jLen));
		for(size_t j = 0; j < jLen; ++j) {
			for(size_t k = 0; k < 101; ++k) {
				//logf("%d %d", i, j);
				mse(ret.data[i][j][0],
						pred.results[i][j].readAvail[k],
						actual.results[i][j].readAvail[k],
					);
				mse(ret.data[i][j][1],
						pred.results[i][j].writeAvail[k],
						actual.results[i][j].writeAvail[k],
					);
				mse(ret.data[i][j][2],
						pred.results[i][j].readCosts[k],
						actual.results[i][j].readCosts[k],
					);
				mse(ret.data[i][j][3],
						pred.results[i][j].writeCosts[k],
						actual.results[i][j].writeCosts[k],
					);
			}
		}
	}

	const iLen2 = ret.data.length;
	ensure(iLen2 == 2);
	for(size_t i = 0; i < iLen2; ++i) {
		const jLen2 = ret.data[i].length;
		ensure(jLen2 == 7);
		for(size_t j = 0; j < jLen2; ++j) {
			const kLen2 = ret.data[i][j].length;
			ensure(kLen2 == 4);
			for(size_t k = 0; k < kLen2; ++k) {
				ret.data[i][j][k] /= 101.0;
			}
		}
	}
	return ret;
}

struct GraphStatsDistance(int Size) {
	GraphStats!(Size) ptr;
	double distance;

	this(GraphStats!(Size) ptr, double distance) {
		this.ptr = ptr;
		this.distance = distance;
	}

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

void ensureDistanceOrder(int Size)(
		ref const(FixedSizeArray!(GraphStatsDistance!(Size),32)) distances)
{
	for(size_t i = 1; i < distances.length; ++i) {
		ensure(distances[i].distance >= distances[i - 1].distance);
	}
}

FixedSizeArray!(GraphStatsDistance!(Size),32) getKNext(int Size)(
		ref Array!(OptimalMappings!Size) om, const(size_t) ignore,
		ref const(LNTDimensions) dim, ref const(GraphStats!Size) center, 
		const(MMCStat!Size) mm, const(size_t) k)
{
	FixedSizeArray!(GraphStatsDistance!(Size),32) ret;
	size_t idx;
	foreach(ref it; om[]) {
		if(idx++ == ignore) {
			continue;
		}
		foreach(ref OptMapData!Size jt; it.data[]) {
			if(jt.key != dim) {
				continue;
			}
			foreach(ref GraphStats!Size kt; jt.values[]) {
				double distance = calcDistance!(Size)(center, kt, mm);
				ret.insertBack(GraphStatsDistance!(Size)(kt, distance));
				sort(ret[]);
				ensureDistanceOrder(ret);
				if(ret.length > k) {
					ret.removeBack();
				}
			}
		}
	}
	ensure(ret.length <= k);
	return ret;
}

void knn(int Size, alias Func)(
		Array!(OptimalMappings!Size) splits, const(size_t) select,
	   	ref OptLearnRslt!(Size) rslt, const(MMCStat!Size) mm, const(size_t) k) 
{
	foreach(ref const(OptMapData!(Size)) it; splits[select].data[]) {
		foreach(ref const(GraphStats!(Size)) gs; it.values[]) {
			FixedSizeArray!(GraphStatsDistance!(Size),32) preds = 
				getKNext!Size(splits, select, it.key, gs, mm, k);
			//logf("preds length %s", preds.length);
			GraphStats!(Size) tmp = combine!(Size,Func)(preds);
			auto tmpRslt = compare(tmp, gs);

			rslt.get(it.key).rslt.add(tmpRslt);
		}
	}
}

void prepareLatexDoc(LTW)(ref LTW ltw) {
	formattedWrite(ltw, "\\documentclass[crop=false,class=scrbook]{standalone}\n");
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

bool areMeasuresUnique(int Size)(const(MMCStat!Size) mm) {
	for(size_t i = 0; i < mm.cstats.length; ++i) {
		for(size_t j = i+1; j < mm.cstats.length; ++j) {
			if(mm.cstats[i].measure == mm.cstats[j].measure) {
				return false;
			}
		}
	}
	return true;
}

void doLearning2(int Size)(string jsonFileName) {
	doLearning2!(Size)(jsonFileName, "MCS");
	doLearning2!(Size)(jsonFileName, "Lattice");
	doLearning2!(Size)(jsonFileName, "Grid");

	auto f = File(jsonFileName ~ "ai2.tex", "w");
	auto ltw = f.lockingTextWriter();
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
	formattedWrite(ltw, "\\input{%s_%sai2}\n", jsonFileName, "MCS");
	formattedWrite(ltw, "\\input{%s_%sai2}\n", jsonFileName, "Lattice");
	formattedWrite(ltw, "\\input{%s_%sai2}\n", jsonFileName, "Grid");
	formattedWrite(ltw, "\\end{document}\n");
}

// how good can "mm" can be used to predict the costs or availability
// join 4/5 of rslts with mm and jm into Joined
// predict the avail and costs based on mm for all 1/5 graphs of rslts
// calc MSE against real value
void doLearning2(int Size)(string jsonFileName, string protocol) {
	enum numSplits = 5;
	string outdir = format("%s_Learning2/", jsonFileName);
	Array!(GraphWithProperties!Size) graphs = loadGraphs!Size(jsonFileName);
	ensure(graphs.length > 0);
	const size_t numNodes = graphs[0].graph.length;
	standardizeProperties!(Size)(graphs);
	logf("%s graphs with %s nodes", graphs.length, numNodes);
	OptimalMappings!Size rslts = loadResults(graphs, jsonFileName, protocol, 
			graphs[0].graph.length
		);
	rslts.validate();
	rslts.scale();

	Array!(OptimalMappings!Size) splits = split(rslts, numSplits);
	//foreach(ref it; splits) { // ERROR doesn't work after scale()
	//	it.validate();
	//}

	auto f = File(jsonFileName ~ "_" ~ protocol ~ "ai2.tex", "w");
	auto ltw = f.lockingTextWriter();
	prepareLatexDoc(ltw);

	OptCompare!Size results;

	auto permu = Permutations(cast(int)cstatsArray.length, 1, cast(int)cstatsArray.length);
	formattedWrite(ltw, "\\part{%s}\n", protocol);
	formattedWrite(ltw, "\\chapter{Permutations}\n");
	foreach(perm; permu) {
		logf("begin");
		auto mm = new MMCStat!32();
		for(int j = 0; j < cstatsArray.length; ++j) {
			if(perm.test(j)) {
				mm.insertIStat(cstatsArray[j]);
			}
		}

		if(!areMeasuresUnique(mm)) {
			logf("ignore %s", mm.getName());
			continue;
		}

		formattedWrite(ltw, "\\section{%s}\n", mm.getName());
		auto learnRsltPerm = OptLearnRslt!(Size)(&rslts);

		for(size_t sp = 0; sp < numSplits; ++sp) {
			knn!(Size,combineMedian)(splits, sp, learnRsltPerm, mm, 7);
		}

		logf("%s", mm.getName());
		learnRsltPerm.toLatex(ltw);
		results.compare(learnRsltPerm, mm);
		logf("end");
	}
	formattedWrite(ltw, "\\chapter{Result}\n");
	results.toLatex(ltw);
	formattedWrite(ltw, "\\end{document}\n");
}

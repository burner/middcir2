module learning;

import std.stdio;
import std.container.array;
import std.format : format, formattedWrite;
import std.algorithm.sorting : nextPermutation;
import std.meta : AliasSeq;
import std.exception : enforce;
import std.experimental.logger;

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

// how good can "mm" can be used to predict the costs or availability
// join 4/5 of rslts with mm and jm into Joined
// predict the avail and costs based on mm for all 1/5 graphs of rslts
// calc MSE against real value
void doLearning(int Size)(string jsonFileName) {
	import std.algorithm.sorting : sort;
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

	for(size_t sp = 0; sp < numSplits; ++sp) {
		ProtocolStats!Size joined = join(splits, sp);
		joined.validate();
		auto permu = Permutations(cast(int)cstatsArray.length, 1, cast(int)cstatsArray.length);
		//auto permu = Permutations(i);
		auto mm = new MMCStat!32();
		foreach(perm; permu) {
			for(int j = 0; j < cstatsArray.length; ++j) {
				if(perm.test(j)) {
					mm.insertIStat(cstatsArray[j]);
				}
			}

			foreach(ref it; joined.mcs.data[]) {
				sort!((a,b) => mm.less(a,b))(it.values[]);
			}
			foreach(ref it; joined.lattice.data[]) {
				sort!((a,b) => mm.less(a,b))(it.values[]);
			}
			foreach(ref it; joined.grid.data[]) {
				sort!((a,b) => mm.less(a,b))(it.values[]);
			}

			writefln("%s %s", sp, perm.count());
			mm.clear();
		}
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
	}
}

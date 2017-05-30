module learning;

import std.stdio;
import std.container.array;
import std.format : format, formattedWrite;
import std.algorithm.sorting : nextPermutation;
import std.meta : AliasSeq;

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
			const(GraphStats!Size) b) const 
	{
		import std.math : approxEqual;

		foreach(it; this.cstats) {
			if(approxEqual(it.select(a), it.select(b), 0.000_001)) {
				continue;
			} else if(it.select(a) < it.select(b)) {
				return true;
			} else {
				return false;
			}
		}
		return false;
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
					write(cstatsArray[j].name, " ");
				}
			}
			mm.clear();
			writeln();
			++count;
		}
	}
	writeln(count);
}

// how good can "mm" can be used to predict the costs or availability
// join 4/5 of rslts with mm and jm into Joined
// predict the avail and costs based on mm for all 1/5 graphs of rslts
// calc MSE against real value
void doLearning(int Size)(string jsonFileName) {
	string outdir = format("%s_Learning/", jsonFileName);
	Array!(GraphWithProperties!Size) graphs = loadGraphs!Size(jsonFileName);
	Array!LNTDimensions dims = genDims(graphs[0].graph.length);
	ProtocolStats!(Size) rslts = loadResultss(graphs, jsonFileName);
}

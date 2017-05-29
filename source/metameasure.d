module metameasure;

import std.stdio;
import std.container.array;
import std.format : format, formattedWrite;
import std.algorithm.sorting : nextPermutation;
import std.meta : AliasSeq;

//import fixedsizearray;

import statsanalysis;
import bitsetmodule;

bool recurSortMM(int Size, S...)(const(GraphStats!Size) a, 
		const(GraphStats!Size) b) if(S.length > 1)
{
	import std.math : approxEqual;
	if(approxEqual(S[0].select(a), S[0].select(b))) {
		return recurSortMM!(Size, S[1 .. $])(a, b);
	} else if(S[0].select(a) < S[0].select(b)) {
		return true;
	} else if(S[0].select(a) > S[0].select(b)) {
		return false;
	}
	assert(false);
}

bool recurSortMM(int Size, S)(const(GraphStats!Size) a, 
		const(GraphStats!Size) b)
{
	import std.functional : binaryFun;
	return binaryFun!(S.sortPredicate)(a, b);
}

auto recurSelectMM(int Size, S...)(const(GraphStats!Size) g) {
	static if(S.length == 1) {
		return S[0].select(g);
	} else {
		return (10 * S[0].select(g))
			+ recurSelectMM!(Size, S[1 .. $])(g);
	}
}

auto recurSelectMM(int Size, S...)(const(GraphWithProperties!Size) g) {
	static if(S.length == 1) {
		return S[0].select(g);
	} else {
		return (10 * S[0].select(g))
			+ recurSelectMM!(Size, S[1 .. $])(g);
	}
}

struct MetaMeasure(string name, int Size, T...) {
	static immutable string XLabel = name;
	static bool sortPredicate(const(GraphStats!Size) a, 
			const(GraphStats!Size) b) 
	{
		return recurSortMM!(Size, T)(a, b);
	}

	static auto select(const(GraphStats!Size) g) {
		return recurSelectMM!(Size,T)(g);
	}

	static auto select(const(GraphWithProperties!Size) g) {
		return recurSelectMM!(Size,T)(g);
	}
}

unittest {
	alias MM = MetaMeasure!("MM", 32, BetweenneesAverage!32, Connectivity!32);
	MM mm;
	static assert(mm.XLabel == "MM");
}

enum JoinMode {
	Min,
	Average,
	Median,
	Mode,
	Max
}

immutable joinModes = [JoinMode.Average, JoinMode.Median, JoinMode.Mode];

template makeNameArray(T...) {
	string[] buildArray() {
		auto ret = new string[1];
		static if(T.length == 1) {
			ret[0] = T[0].stringof;
		} else {
			ret[0] = T[0].stringof;
			ret ~= makeNameArray!(T[1 .. $]).buildArray();
		}
		return ret;
	}	
}

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

string[2][] makeNofMArrays(string[] input) {
	import permutation;
	import std.array : appender;

	string[2][] ret;

	auto perm = Permutations(cast(int)input.length, 1, 4);

	foreach(it; perm) {
		int[] which;
		for(int i = 0; i < it.StoreType.sizeof * 8; ++i) {
			if(it.test(i)) {
				which ~= i;
			}
		}
		do {
			//writeln(which[]);
			string tmp;
			size_t idx;
			foreach(jt; which[]) {
				if(idx > 0) {
					tmp ~= ", ";
				}
				tmp ~= input[jt];
				++idx;
			}
			ret ~= [tmp, shortName(tmp)];
		} while(nextPermutation(which));
	}

	return ret;
}

unittest {
	enum names = makeNameArray!(Connectivity!32, DiameterAverage!32,
			DegreeMin!32).buildArray();
	//writeln(names);
	auto allCombi = makeNofMArrays(names);
	//writefln("%(%s\n%)", allCombi);
}

string genMMs(T...)() {
	auto arr = makeNameArray!(T).buildArray();
	string[2][] allCombis = makeNofMArrays(arr);
	string ret = "alias MMs = AliasSeq!(";
	foreach(idx, it; allCombis) {
		ret ~= format("MetaMeasure!(\"%s\", 32, %s),\n", it[1], it[0]);
	}
	ret ~= ");";	
	return ret;
}

/*unittest {
	enum mm = genMMs!(Connectivity!32, DiameterAverage!32,
			DegreeMin!32);

	pragma(msg, mm);
}*/

/*immutable MMsString = genMMs!(
		DiameterAverage!32, DiameterMedian!32, DiameterMax!32,
		DiameterMode!32,
		Connectivity!32,
		DegreeAverage!32, DegreeMedian!32, DegreeMin!32, DegreeMax!32,
		BetweenneesAverage!32, BetweenneesMedian!32, BetweenneesMin!32, BetweenneesMax!32
	);*/

//pragma(msg, MMsString);

// how good can "mm" can be used to predict the costs or availability
// join 4/5 of rslts with mm and jm into Joined
// predict the avail and costs based on mm for all 1/5 graphs of rslts
// calc MSE against real value
void doLearning(int Size)(string jsonFilename) {
	string outdir = format("%s_Learning/", jsonFileName);
	Array!(GraphWithProperties!Size) graphs = loadGraphs!Size(jsonFileName);
	Array!LNTDimensions dims = genDims(graphs[0].graph.length);
	ProtocolStats!(Size) rslts = loadResultss(graphs, jsonFileName);

	//pragma(msg, MMsString);
	//foreach(it; MMs!32) {

	//}
	/*MCSJoin[joinModes.length][readOverWriteLevel.length][2] mcsAll;
	foreach(ac; [AvailOrCosts.Avail, AvailOrCosts.Cost]) {
		foreach(row; readOverWriteLevel) {
			foreach(jm; joinModes) {
				MCSJoin mcsJoin;
				foreach(mm; MMs) {
					auto mcs = MCS(result, mm);
					foreach(big, small; split(4, 5, rslts, row)) {
						auto joined = join(big, jm);
						mcs += calcMCS(joined, small);
					}
				}
			}
		}
	}*/
	mcsAllToLatex(mcsAll);
}

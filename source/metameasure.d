module metameasure;

import statsanalysis;

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

module learning;

import std.stdio;
import std.container.array;
import std.format : format, formattedWrite;
import std.algorithm.sorting : nextPermutation;
import std.meta : AliasSeq;

import fixedsizearray;

import statsanalysis;
import bitsetmodule;

interface IStat(int Size) {
	@property string XLabel() const;
	double select(const(GraphStats!Size) g);
	double select(const(GraphWithProperties!Size) g);
}

class CStat(int Size, Stat) {
	@property string XLabel() const {
		return Stat!Size.XLabel;
	}

	double select(const(GraphStats!Size) g) {
		return Stat!Size.select(g);
	}
	double select(const(GraphWithProperties!Size) g) {
		return Stat!Size.select(g);
	}	
}

unittest {
	auto n = new CStat!(16,Connectivity!16)();
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

module protocols.grid;

import std.conv : to;
import std.format : format;
import std.stdio;
import std.experimental.logger;

import protocols;
import config;

struct Grid {
	import bitsetrbtree;

	BitsetStore!uint read;
	BitsetStore!uint write;

	size_t width;
	size_t height;
	uint rowMask;

	this(size_t width, size_t height) {
		this.width = width;
		this.height = height;
		this.rowMask = (1 << this.width) - 1;
		this.read.array.reserve(32);
		this.write.array.reserve(32);
	}

	/*
	3 | 15 14 13 12
	2 | 11 10  9  8
	1 |  7  6  5  4
	0 |  3  2  1  0
	---------------
	     3  2  1  0

	One of each column is set if the bitwise or of all row is all one. So you
	have a columnCover.
	A complete column is set if the bitwise and of all row has at least one
	one. If you find a one you have completeColumn.
	*/
	void testGrid(ref ubyte columnCover, ref ubyte completeColumn,
		   	const uint permutation)
	{
		columnCover = 0;
		completeColumn = ubyte.max;

		uint rowPermutation = permutation;
		for(size_t i = 0; i < this.height; ++i) {
			uint row = (rowPermutation & this.rowMask);
			columnCover |= row;
			completeColumn &= row;
			rowPermutation = rowPermutation >> this.width;
		}
	}

	Result calcAC() {
		import utils : removeAll, testQuorumIntersection, testAllSubsetsSmaller;
		
		ubyte columnCover;
		ubyte completeColumn;

		const uint upto = to!uint(1 << (this.width * this.height));
		for(uint perm = 0; perm < upto; ++perm) {
			testGrid(columnCover, completeColumn, perm);		

			if(columnCover == this.rowMask) {
				this.read.insert(perm);
			}

			if(columnCover == this.rowMask && completeColumn > 0) {
				this.write.insert(perm);
			}
		}

		version(unittest) {
			testQuorumIntersection(this.read, this.write);
			testAllSubsetsSmaller(this.read, this.write);
		}

		return calcAvailForTree(to!int(this.width * this.height), this.read, this.write);
	}

	string name() const pure {
		return format("Grid %sx%s", this.width, this.height);
	}
}

unittest {
	auto g = Grid(4, 4);

	ubyte columnCover;
	ubyte completeColumn;

	g.testGrid(columnCover, completeColumn, 0b1100_1000_1010_1001);
	assert(columnCover == 0b1111, format("%b", columnCover));
	assert(completeColumn == 0b1000, format("%b", completeColumn));

	g.testGrid(columnCover, completeColumn, 0b1100_1000_1010_0001);
	assert(columnCover == 0b1111, format("%b", columnCover));
	assert(completeColumn == 0b0000, format("%b", completeColumn));

	g.testGrid(columnCover, completeColumn, 0b1100_1000_1010_0000);
	assert(columnCover == 0b1110, format("%b", columnCover));
	assert(completeColumn == 0b0000, format("%b", completeColumn));

	g.testGrid(columnCover, completeColumn, 0b1000_1000_1000_1000);
	assert(columnCover == 0b1000, format("%b", columnCover));
	assert(completeColumn == 0b1000, format("%b", completeColumn));
}

struct GridFormula {
	import math;
	import std.math : pow;

	size_t width;
	size_t height;

	this(size_t width, size_t height) {
		this.width = width;
		this.height = height;
	}

	Result calcAC() {
		auto ret = Result();

		for(size_t i = 0; i < 101; ++i) {
			const double p = stepCount * i;
			
			ret.readAvail[i] = 
				pow(1.0 - pow(1.0 - p, this.width), this.height);

			ret.writeAvail[i] = 
				pow(1.0 - pow(1.0 - p, this.width), this.height) -
				pow(1.0 - pow(p, this.width) - pow(1.0 - p, this.width), this.height);

			ret.readCosts[i] = this.width;
			ret.writeCosts[i] = this.width + this.height - 1;
		}

		return ret;
	}

	string name() const pure {
		return format("Grid Formula %sx%s", this.width, this.height);
	}
}

unittest {
	import utils;

	auto grid = Grid(3,3);
	auto gridRslt = grid.calcAC();
	testQuorumIntersection(grid.read, grid.write);

	testSemetry(gridRslt);

	auto it = grid.read.begin();
	auto end = grid.read.end();
	while(it != end) {
		assert((*it).bitset.count() == 3, 
			format("%s %(%s %)", (*it).bitset, (*it).subsets)
		);
		++it;
	}

	auto gridF = GridFormula(3,3);
	auto gridFRslt = gridF.calcAC();

	compare(gridFRslt.readAvail, gridRslt.readAvail, &equal);
	compare(gridFRslt.writeAvail, gridRslt.writeAvail, &equal);
	compare(gridFRslt.readCosts, gridRslt.readCosts, &equal);
	compare(gridFRslt.writeCosts, gridRslt.writeCosts, &equal);
}

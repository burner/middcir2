module graphisomorph2;

import graph;

bool areGraphsIso2(int Size)(const(Graph!Size) a, const(Graph!Size) b) {
	import fixedsizearray;
	import std.algorithm : nextPermutation;

	if(a.length != b.length) {
		return false;
	}
	bool[Size+1][Size+1] aArr;
	for(int i = 0; i < a.length; ++i) {
		for(int j = 0; j < a.length; ++j) {
			if(a.testEdge(i, j)) {
				aArr[i][j] = true;
			}
		}
	}

	int[] perm;
	for(int i = 0; i < a.length; ++i) {
		perm ~= i;
	}

	do {
		bool[Size+1][Size+1] bArr;
		for(int i = 0; i < b.length; ++i) {
			for(int j = 0; j < b.length; ++j) {
				if(b.testEdge(i, j)) {
					bArr[perm[i]][perm[j]] = true;
				}
			}
		}
		for(int i = 0; i < a.length; ++i) {
			for(int j = 0; j < a.length; ++j) {
				if(aArr[i][j] != bArr[i][j]) {
					goto next;
				}
			}
		}
		return true;
		next:
	} while(nextPermutation(perm[]));

	return false;
}


unittest {
	auto six = makeSix!16();
	assert(areGraphsIso2(six, six));	

	auto nine = makeNine!16();
	assert(!areGraphsIso2(six, nine));	
	assert(areGraphsIso2(nine, nine));	
}

unittest {
	auto a = Graph!16(6);
	a.setEdge(0,5);
	a.setEdge(0,4);
	a.setEdge(1,4);
	a.setEdge(2,3);

	// 0 1 5 3 4 2
	// 0 1 2 3 4 5
	auto b = Graph!16(6);
	b.setEdge(0,2);
	b.setEdge(0,4);
	b.setEdge(1,4);
	b.setEdge(5,3);

	assert(areGraphsIso2(a, b));
}

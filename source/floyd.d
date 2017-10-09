module floydmodule;

import std.experimental.logger;

import graph;
import bitsetmodule;
import fixedsizearray;

auto floyd(G,int Size = 16)(const ref G graph) {
	FloydImpl!Size rslt;
	rslt.init(graph);

	return rslt;
}

auto floyd2(G,int Size = 16)(const ref G graph) {
	FloydImpl2!Size rslt;
	rslt.init(graph);

	return rslt;
}

alias Floyd = FloydImpl!16;
alias Floyd2 = FloydImpl2!16;

align(8)
struct FloydImpl(int Size) {
	import std.container.array;

	align(8) {
	enum INF = ubyte.max;

	//alias ArrayType = Array!(ubyte);
	alias ArrayType = FixedSizeArray!(ubyte,Size);

	alias ArrayArrayType = Array!(ArrayType);
	//alias ArrayArrayType = FixedSizeArray!(FixedSizeArray!(ubyte,32),32);

	ArrayArrayType distance;
	ArrayArrayType first;
	//Array!(Array!(ubyte)) distance;
	//Array!(Array!(ubyte)) first;
	}

	void init(G)(const ref G graph) {
		this.reserveArrays(graph.numNodes);
		this.execute(graph);
	}

	void execute(G)(const ref G graph) {
		this.execute(graph, Bitset!ulong(ulong.max));
	}

	void execute(G,B = ulong)(const ref G graph, const Bitset!B mask) {
		this.initArrays(graph, mask);
		this.floyd();
	}

	string toString() const {
		import std.array : appender;
		auto app = appender!string();
		this.toString(app);

		return app.data();
	}

	//void toString(scope void delegate(const(char)[]) sink) const {
	void toString(Sink)(ref Sink sink) const {
		import std.format : formattedWrite;

		formattedWrite(sink, "Distance:\n");
		int idx = 0;
		foreach(ref row; this.distance[]) {
			formattedWrite(sink, "%2d: ", idx++);
			foreach(column; row[]) {
				formattedWrite(sink, "%3d ", column);
			}
			formattedWrite(sink, "\n");
		}

		idx = 0;
		formattedWrite(sink, "\nFirst:\n");
		foreach(ref row; this.first[]) {
			formattedWrite(sink, "%2d: ", idx++);
			foreach(column; row[]) {
				formattedWrite(sink, "%3d ", column);
			}
			formattedWrite(sink, "\n");
		}
	}

	void initArrays(G, B)(const ref G graph, const Bitset!B mask) {
		for(int i = 0; i < graph.length; ++i) {
			for(int j = 0; j < graph.length; ++j) {
				if(i == j && mask.test(i)) {
					this.distance[i][j] = 0;
					this.first[i][j] = cast(ubyte)j;
				} else if(graph.testEdge(i, j) 
						&& mask.test(i) 
						&& mask.test(j)) 
				{
					this.distance[i][j] = 1;
					this.first[i][j] = cast(ubyte)j;
				} else {
					this.distance[i][j] = INF;
					this.first[i][j] = INF;
				}
			}
		}
	}

	void reserveArrays(const int numNodes) {
		//this.distance.reserve(numNodes);
		for(int i = 0; i < numNodes; ++i) {
			this.distance.insertBack(ArrayType());
			//this.distance.back.reserve(numNodes);
			for(int j = 0; j < numNodes; ++j) {
				this.distance[i].insertBack(INF);
			}
		}

		//this.first.reserve(numNodes);
		for(int i = 0; i < numNodes; ++i) {
			this.first.insertBack(ArrayType());
			//this.first.back.reserve(numNodes);
			for(int j = 0; j < numNodes; ++j) {
				this.first[i].insertBack(INF);
			}
		}
	}

	void floyd() {
		const nn = distance.length;
		for(int k = 0; k < nn; ++k){
			for(int i = 0; i < nn; ++i){
				for(int j = 0; j < nn; ++j){
					//If the path using two edges is less than the path using one edge...
					auto tmp = (this.distance[i][k] + this.distance[k][j]);
					if(this.distance[i][j] > tmp) {
						//Set the cost of the edge to be the lesser cost.
						this.distance[i][j] = cast(ubyte)(tmp);
						//Have the nextNode array go to the other node
						//before going to the final node. This ensures proper path reconstruction.
						this.first[i][j] = this.first[i][k];
					}
				}  	  
			}
		}
	}

	bool path(T)(const uint from, const uint to, ref T rslt) const {
		rslt.insertBack(cast(TypeFromSize!Size)from);
		ubyte next = this.first[from][to];
		while(next != INF && next != to) {
			rslt.insertBack(cast(TypeFromSize!Size)next);
			next = this.first[next][to];
		}

		rslt.insertBack(cast(TypeFromSize!Size)to);
		return next == to;
	}

	bool pathExists(const uint from, const uint to) const {
		return this.distance[from][to] != INF;
	}
}

unittest {
	import std.format : format;
	int len = 8;
	auto g = Graph!16(len);
	g.setEdge(4,5);
	g.setEdge(5,6);

	auto fr = floyd(g);
	assert(fr.distance[4][6] == 2);
	assert(fr.pathExists(4,6));
	assert(fr.first[4][6] == 5, fr.toString());
}

unittest {
	import std.random : uniform;
	int len = 9;

	auto g = Graph!32(len);
	const upTo = (len * len) / 6;
	for(int i = 0; i < upTo; ++i) {
		const f = uniform(0, len);
		const t = uniform(0, len);
		//logf("%2d %2d", f, t);
		g.setEdge(f,t);
	}

	auto fr = floyd(g);
}

unittest {
	import std.conv : to;
	import std.format : format, formattedWrite;
	import std.array : appender;
	//import containers.dynamicarray;
	import std.container : Array;
	import utils;

	auto edges = [
		[0,1],
		[1,2],
		[2,3],
		[2,7],
		[1,4],
	];

	auto length = 8;

	auto g = Graph!16(length);
	foreach(ref it; edges) {
		g.setEdge(it[0], it[1]);
	}

	auto f = floyd(g);
	auto app = appender!string();
	formattedWrite(app, "%s", f);

	Array!uint rslt;
	for(int i = 0; i < length; ++i) {
		inner: for(int j = 0; j < length; ++j) {
			rslt.removeAll();
			foreach(ref it; edges) {
				foreach(ref jt; edges) {
					if((i == it[0] || i == it[1]) 
							&& (j == jt[0] || j == jt[1])) 
					{
						bool pathFound = f.path(i, j, rslt);
						assert(f.pathExists(i,j));
						assert(pathFound, f.toString() ~ " " ~ to!string(rslt[]));
						assert(rslt.front == i && rslt.back == j);
						continue inner;
					}
				}
			}
			bool pathFound = f.path(i, j, rslt);
			if(i == j) {
				assert(pathFound);
				assert(rslt.length == 2);
				assert(rslt.front == i);
				assert(rslt.back == j);
			} else {
				assert(!pathFound, format("from(%s) to(%s) %s %s", i, j, 
					f.toString(), to!string(rslt[])));
			}
		}
	}
}

unittest {
	import std.container.array : Array;
	import utils;
	auto edges = [
		[0,1],
		[1,2],
		[2,3],
		[2,7],
		[1,4],
	];

	auto length = 8;

	auto g = Graph!16(length);
	foreach(ref it; edges) {
		g.setEdge(it[0], it[1]);
	}

	Floyd f = floyd(g);
	f.execute(g, bitset!ubyte(cast(ubyte)0));

	Array!uint rslt;
	const upTo = 1 << length;
	for(uint m = 0; m < upTo; ++m) {
		auto bs = bitset(m);
		f.execute(g, bs);
		for(int i = 0; i < length; ++i) {
			for(int j = 0; j < length; ++j) {
				rslt.removeAll();
				auto pathExists = f.path(i,j, rslt);
				if(m == 0) {
					assert(!pathExists);
				}
			}
		}
	}
}

align(8)
struct FloydImpl2(int Size) {
	alias BSType = TypeFromSize!Size;

	align(8) {
	ubyte[Size][Size] first;
	ubyte[Size][Size] distance;
	size_t numNodes;
	enum INF = ubyte.max/2 - 1;
	}

	void init(G)(const ref G graph) {
		this.numNodes = graph.length;
		this.reserveArrays(graph.numNodes);
		this.execute(graph, Bitset!ulong(ulong.max));
	}

	void execute(G,B = ulong)(const ref G graph, const Bitset!B mask) {
		this.numNodes = graph.length;
		this.initArrays(graph, mask);
		this.floyd();
	}

	void initArrays(G, B)(ref const(G) graph, const(Bitset!B) mask) {
		const(int) len = cast(int)graph.length;
		for(int i = 0; i < len; ++i) {
			for(int j = 0; j < len; ++j) {
				if(i == j && mask.test(i)) {
					this.distance[i][j] = 0;
					this.first[i][j] = cast(ubyte)j;
				} else if(graph.testEdge(i, j) 
						&& mask.test(i) 
						&& mask.test(j)) 
				{
					this.distance[i][j] = 1;
					this.first[i][j] = cast(ubyte)j;
				} else {
					this.distance[i][j] = INF;
					this.first[i][j] = INF;
				}
			}
		}
	}

	void reserveArrays(const int numNodes) {
		for(int i = 0; i < numNodes; ++i) {
			for(int j = 0; j < numNodes; ++j) {
				this.distance[i][j] = INF;	
				this.first[i][j] = INF;	
			}
		}
	}

	void floyd() {
		const nn = this.numNodes;
		for(size_t k = 0; k < nn; ++k){
			for(size_t i = 0; i < nn; ++i){
				if(this.distance[i][k] == INF) {
					continue;
				}
				for(size_t j = 0; j < nn; ++j){
					if(this.distance[k][j] == INF) {
						continue;
					}
					//If the path using two edges is less than the path using one edge...
					ubyte tmp = cast(ubyte)(this.distance[i][k] + this.distance[k][j]);
					if(this.distance[i][j] > tmp) {
						//Set the cost of the edge to be the lesser cost.
						this.distance[i][j] = cast(ubyte)(tmp);
						//Have the nextNode array go to the other node
						//before going to the final node. This ensures proper path reconstruction.
						this.first[i][j] = this.first[i][k];
					}
				}  	  
			}
		}
	}

	bool path(T)(const uint from, const uint to, ref T rslt) const {
		rslt.insertBack(cast(TypeFromSize!Size)from);
		ubyte next = this.first[from][to];
		while(next != INF && next != to) {
			rslt.insertBack(cast(TypeFromSize!Size)next);
			next = this.first[next][to];
		}

		rslt.insertBack(cast(TypeFromSize!Size)to);
		return next == to;
	}

	bool pathExists(const uint from, const uint to) const {
		return this.distance[from][to] != INF;
	}

	string toString() const {
		import std.array : appender;
		auto app = appender!string();
		this.toString(app);

		return app.data();
	}

	//void toString(scope void delegate(const(char)[]) sink) const {
	void toString(Sink)(ref Sink sink) const {
		import std.format : formattedWrite;

		formattedWrite(sink, "Distance:\n");
		int idx = 0;
		foreach(ref row; this.distance) {
			formattedWrite(sink, "%2d: ", idx++);
			foreach(column; row) {
				formattedWrite(sink, "%3d ", column);
			}
			formattedWrite(sink, "\n");
		}

		idx = 0;
		formattedWrite(sink, "\nFirst:\n");
		foreach(ref row; this.first) {
			formattedWrite(sink, "%2d: ", idx++);
			foreach(column; row) {
				formattedWrite(sink, "%3d ", column);
			}
			formattedWrite(sink, "\n");
		}
	}
}

unittest {
	import std.format : format;
	int len = 8;
	auto g = Graph!16(len);
	g.setEdge(4,5);
	g.setEdge(5,6);

	auto fr = floyd2(g);
	assert(fr.distance[4][6] == 2, fr.toString());
	assert(fr.pathExists(4,6), fr.toString());
	assert(fr.first[4][6] == 5, fr.toString());
}

unittest {
	import std.random : uniform;
	int len = 9;

	auto g = Graph!32(len);
	const upTo = (len * len) / 6;
	for(int i = 0; i < upTo; ++i) {
		const f = uniform(0, len);
		const t = uniform(0, len);
		//logf("%2d %2d", f, t);
		g.setEdge(f,t);
	}

	auto fr = floyd2(g);
}

unittest {
	import std.conv : to;
	import std.format : format, formattedWrite;
	import std.array : appender;
	//import containers.dynamicarray;
	import std.container : Array;
	import utils;

	auto edges = [
		[0,1],
		[1,2],
		[2,3],
		[2,7],
		[1,4],
	];

	auto length = 8;

	auto g = Graph!16(length);
	foreach(ref it; edges) {
		g.setEdge(it[0], it[1]);
	}

	auto f = floyd2(g);
	auto app = appender!string();
	formattedWrite(app, "%s", f);

	Array!uint rslt;
	for(int i = 0; i < length; ++i) {
		inner: for(int j = 0; j < length; ++j) {
			rslt.removeAll();
			foreach(ref it; edges) {
				foreach(ref jt; edges) {
					if((i == it[0] || i == it[1]) 
							&& (j == jt[0] || j == jt[1])) 
					{
						bool pathFound = f.path(i, j, rslt);
						assert(f.pathExists(i,j));
						assert(pathFound, f.toString() ~ " " ~ to!string(rslt[]));
						assert(rslt.front == i && rslt.back == j);
						continue inner;
					}
				}
			}
			bool pathFound = f.path(i, j, rslt);
			if(i == j) {
				assert(pathFound);
				assert(rslt.length == 2);
				assert(rslt.front == i);
				assert(rslt.back == j);
			} else {
				assert(!pathFound, format("from(%s) to(%s) %s %s", i, j, 
					f.toString(), to!string(rslt[])));
			}
		}
	}
}

unittest {
	import std.container.array : Array;
	import utils;
	auto edges = [
		[0,1],
		[1,2],
		[2,3],
		[2,7],
		[1,4],
	];

	auto length = 8;

	auto g = Graph!16(length);
	foreach(ref it; edges) {
		g.setEdge(it[0], it[1]);
	}

	Floyd2 f = floyd2(g);
	f.execute(g, bitset!ubyte(cast(ubyte)0));

	Array!uint rslt;
	const upTo = 1 << length;
	for(uint m = 0; m < upTo; ++m) {
		auto bs = bitset(m);
		f.execute(g, bs);
		for(int i = 0; i < length; ++i) {
			for(int j = 0; j < length; ++j) {
				rslt.removeAll();
				auto pathExists = f.path(i,j, rslt);
				if(m == 0) {
					assert(!pathExists);
				}
			}
		}
	}
}

unittest {
	import std.container.array : Array;
	import std.algorithm.comparison : equal;
	auto g = genTestGraph!16();
	Floyd f1 = floyd(g);
	Floyd2 f2 = floyd2(g);

	for(uint i = 0; i < g.length; ++i) {
		for(uint j = 0; j < g.length; ++j) {
			Array!uint rslt1;
			Array!uint rslt2;
			assert(f1.path(i,j, rslt1) == f2.path(i,j, rslt2));
			assert(equal(rslt1[], rslt2[]));
		}
	}
}

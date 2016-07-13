module floyd;

import std.experimental.logger;

import graph;

struct Floyd {
	import std.container.array;

	enum INF = ubyte.max;

	Array!(Array!(ubyte)) distance;
	Array!(Array!(ubyte)) first;

	static Floyd opCall(G)(const ref G graph) {
		Floyd rslt;
		rslt.reserveArrays(graph.numNodes);
		rslt.initArrays(graph);
		rslt.floyd();
	
		return rslt;
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

	void initArrays(G)(const ref G graph) {
		for(int i = 0; i < graph.length; ++i) {
			for(int j = 0; j < graph.length; ++j) {
				if(i == j) {
					this.distance[i][j] = 0;
				} else if(graph.testEdge(i,j)) {
					this.distance[i][j] = 1;
				}
			}
		}
	}

	void reserveArrays(const int numNodes) {
		this.distance.reserve(numNodes);
		for(int i = 0; i < numNodes; ++i) {
			this.distance.insertBack(Array!ubyte());
			this.distance.back.reserve(numNodes);
			for(int j = 0; j < numNodes; ++j) {
				this.distance[i].insertBack(INF);
			}
		}

		this.first.reserve(numNodes);
		for(int i = 0; i < numNodes; ++i) {
			this.first.insertBack(Array!ubyte());
			this.first.back.reserve(numNodes);
			for(int j = 0; j < numNodes; ++j) {
				this.first[i].insertBack(INF);
			}
		}
	}

	void floyd() {
		const nn = distance.length;

		size_t k, i, j;
		ubyte ik, kj, tmp;
		for(k = 0; k < nn; ++k) {
			for(i = 0; i < nn; ++i) {
				ik = this.distance[i][k];
				if(ik == INF) {
					continue;
				}
				for(j = 0; j <= i; ++j) {
					if(i == j) {
						continue;
					}
					kj = this.distance[k][j];
					if(kj == INF) {
						continue;
					}
					tmp = cast(ubyte)(this.distance[i][k] + kj);
					if(tmp < this.distance[i][j]) {
						this.distance[j][i] = this.distance[i][j] = tmp;
						this.first[i][j] = this.first[j][i] = cast(ubyte)k;
					}
				}
			}
		}
	}
}

unittest {
	import std.format : format;
	int len = 8;
	auto g = Graph!16(len);
	g.setEdge(4,5);
	g.setEdge(5,6);

	auto fr = Floyd(g);
	assert(fr.distance[4][6] == 2);
	assert(fr.first[4][6] == 5, fr.toString());
	log(fr);
}

unittest {
	import std.random : uniform;
	int len = 9;

	auto g = Graph!32(len);
	const upTo = (len * len) / 6;
	for(int i = 0; i < upTo; ++i) {
		const f = uniform(0, len);
		const t = uniform(0, len);
		logf("%2d %2d", f, t);
		g.setEdge(f,t);
	}

	auto fr = Floyd(g);
	log(fr);
}

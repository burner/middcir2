module mappingsort;

enum Feature {
	DiaMin,
	DiaMax,
	DiaAvg,
	DiaMode,
	DiaMedian,

	Dgr,

	BC
}

struct VertexStat {
	double[Feature.length] features;
	int id;
}

int[] sortForMappingByFeature(G)(auto ref G from, auto ref G to) {
}

VertexStat[] sortVerticesByFeature(G)(auto ref G g) {
	VertexStat[] ret;
	auto f = floyd(g);
	f.execute();
	for(int i = 0; i < g.length; ++i) {
		int[][] paths;
		for(int j = 0; j < g.length; ++j) {
			auto app = appender!(int[])();
			if(f.path(i, j, app)) {
				paths ~= app.data;
			}
		}
	}
	return ret;
}

unittest {
	auto g = genTestGraph!(16)();
	VertexStat[] vs = sortVerticesByFeature(g);
}

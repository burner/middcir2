module config;

import std.experimental.logger;

import args;

immutable double stepCount = 0.01;

enum StatsType {
	all,
	MCS,
	Lattice,
	Grid
}

struct Config {
	@Arg() bool runMultiThreaded = false;
	@Arg() int permutationCountStart = -1;
	@Arg() int permutationCountStop = -1;
	@Arg() bool continueLattice = false;
	@Arg() int start = 0;
	@Arg() int upto = 0;
	@Arg() StatsType statstype = StatsType.all;
	@Arg("The json file to get the graphs from for learning2") 
		string learning2filename;
	@Arg("The k in k nearest neighbours") size_t learning2k = 7;

	int permutationStart() const {
		//logf("%s", this.permutationCountStart);
		if(this.permutationCountStart == -1) {
			return 1;
		} else {
			return this.permutationCountStart;
		}
	}

	int permutationStop() const {
		return this.permutationCountStop;
	}

	int permutationStop(int given) const {
		//logf("%s", this.permutationCountStop);
		if(this.permutationCountStop == -1) {
			return given;
		} else {
			return this.permutationCountStop < given ?
				this.permutationCountStop : given;
		}
	}
}

void parseConfig(string[] args) {
	//int permuStart = -1;
	//int permuStop = -1;
	//bool continueLattice = false;
	bool helpWanted = parseArgs(getWriteableConfig(), args);
	if(helpWanted) {
		printArgsHelp(getWriteableConfig(), "The middcir2 program");
	}
}

private Config __theConfig;

ref const(Config) getConfig() {
	return __theConfig;
}

ref Config getWriteableConfig() {
	return __theConfig;
}

version(D_LP64)
	immutable PlatformAlign = 8;
else 
	immutable PlatformAlign = 4;

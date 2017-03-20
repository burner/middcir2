module config;

import std.experimental.logger;

immutable double stepCount = 0.01;

struct Config {
	bool runMultiThreaded = false;
	int permutationCountStart = -1;
	int permutationCountStop = -1;

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
	int permuStart = -1;
	int permuStop = -1;
	import std.getopt;
	auto rslt = getopt(args, 
		"permutationStart|t", &permuStart,
		"permutationStop|p", &permuStop);

	getWriteableConfig().permutationCountStart = permuStart;
	getWriteableConfig().permutationCountStop = permuStop;
	//logf("%s %s", getConfig().permutationCountStart,
	//		getConfig().permutationCountStop);
}

private Config __theConfig;

ref const(Config) getConfig() {
	return __theConfig;
}

ref Config getWriteableConfig() {
	return __theConfig;
}

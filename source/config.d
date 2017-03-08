module config;

immutable double stepCount = 0.01;

struct Config {
	bool runMultiThreaded = false;
	int permutationCountStart = -1;
	int permutationCountStop = -1;

	int permutationStart() const {
		if(this.permutationCountStart == -1) {
			return 1;
		} else {
			return this.permutationCountStart;
		}
	}

	int permutationStop(int given) const {
		if(this.permutationCountStop == -1) {
			return given;
		} else {
			return this.permutationCountStop < given ?
				this.permutationCountStop : given;
		}
	}
}

void parseConfig(string[] args) {
	import std.getopt;
	auto rslt = getopt(args, 
		"permutationStart|t", &getWriteableConfig().permutationCountStart,
		"permutationStop|p", &getWriteableConfig().permutationCountStop);
}

private Config __theConfig;

ref const(Config) getConfig() {
	return __theConfig;
}

ref Config getWriteableConfig() {
	return __theConfig;
}

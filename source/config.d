module config;

immutable double stepCount = 0.01;

struct Config {
	bool runMultiThreaded = true;
}

private Config __theConfig;

ref const(Config) getConfig() {
	return __theConfig;
}

ref Config getWriteableConfig() {
	return __theConfig;
}

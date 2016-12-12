module config;

immutable double stepCount = 0.01;

struct Config {
	bool runMultiThreaded = false;
}

private Config __theConfig;

ref const(Config) getConfig() {
	return __theConfig;
}

ref Config getWriteableConfig() {
	return __theConfig;
}

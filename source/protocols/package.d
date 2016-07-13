module protocols;

struct Result {
	double[101] readAvail;
	double[101] writeAvail;

	double[101] readCosts;
	double[101] writeCosts;

	static Result opCall() {
		Result ret;
		ret.readAvail[] = 0.0;
		ret.writeAvail[] = 0.0;
		ret.readCosts[] = 0.0;
		ret.writeCosts[] = 0.0;
		return ret;
	}
}

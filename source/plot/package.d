module plot;

struct ResultPlot {
	import protocols : Result;

	string name;
	Result result;

	this(string name, Result result) {
		this.name = name;
		this.result = result;
	}
}

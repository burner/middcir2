module plot.resultplot;

import plot;
import graph;
import protocols;

void resultNTPlot(RPs...)(string path, RPs resultProtocols) {
	import std.file : mkdirRecurse, chdir, getcwd;
	import std.stdio : File;
	import std.process : execute;
	import std.exception : enforce;
	string oldcwd = getcwd();
	scope(exit) {
		chdir(oldcwd);
	}

	mkdirRecurse(path);
	chdir(path);
}

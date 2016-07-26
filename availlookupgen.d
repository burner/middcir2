double availability(S)(const int numAvail, const S numNodes, double p) pure {
	import std.math : pow;
	return pow(p, cast(double)numAvail) * pow((1.0 - p), cast(double)(numNodes - numAvail));
}

import std.algorithm;
import std.conv;
import std.range;
import std.stdio;
import std.format;

void main() {
	writeln("module availabilitylookuptable;\n");
	writeln("//[total_nodes][nodes_available][0 <= p < 101]");
	writeln("enum availlookuptable = [");
	for(int totaln = 0; totaln < 24; ++totaln) {
		writef("[");
		for(int navail = 0; navail <= totaln; ++navail) {
			writef("[");
			for(int p = 0; p < 101; ++p) {
				writef("%.8f, ",availability(navail, totaln, p * 0.01));
			}
			writefln("],");
		}
		writefln("],");
	}
	writefln("];");
	writeln(
`
pragma(inline, true)
double fastAvailabilty(const size_t totalNodes, const size_t availNodes,
   		const size_t p) @nogc pure @safe nothrow
{
	return availlookuptalbe[totalNodes][availNodes][p];	
}
`);
}

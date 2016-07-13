import std.stdio;

import protocols.mcs;

void main() {
	auto mcs = MCS(26);
	auto rslt = mcs.calcP();
	foreach(idx, it; rslt) {
		writefln("%3d %.15f", idx, it);
	}
}

module properbilitytests;

import std.math;
import std.stdio;
import std.format;
import math;
import utils;

double gridColumnCoverLong(const double p, const long nodesPerColumn, 
		const long numberColumn) 
{
	double tmp = 0.0;

	for(long l = 1; l <= nodesPerColumn; ++l) {
		tmp += binomial(nodesPerColumn, l) 
			* pow(p, l) 
			* pow((1.0 - p), nodesPerColumn - l);
	}

	return pow(tmp, numberColumn);
}

double gridColumnCoverShort(const double p, const long nodesPerColumn, 
		const long numberColumn) 
{
	return pow(1.0 - pow(1.0 - p, nodesPerColumn), numberColumn);
}

unittest {
	for(long nodesPerColumn = 1; nodesPerColumn < 15; ++nodesPerColumn) {
		for(long numColumn = 1; numColumn < 15; ++numColumn) {
			for(double p = 0.0; p < 1.01; p += 0.01) {
				double lf = gridColumnCoverLong(p, nodesPerColumn, numColumn);
				double sf = gridColumnCoverShort(p, nodesPerColumn, numColumn);
				assert(approxEqual(lf, sf), format(
					"nPc(%2d) nC(%2d) p(%4.3f) lf(%9.7f) sf(%9.7f)",
					nodesPerColumn, numColumn, p, lf, sf
				));
			}
		}
	}
}

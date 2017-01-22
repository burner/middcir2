module math;

import std.math;
import std.stdio;

import gfm.math.vector;

import bitsetmodule;
import fixedsizearray;

ulong factorial(const ulong fac) {
	assert(fac < 23);
	ulong ret = 1;
	for(ulong i = 1; i <= fac; ++i) {
		ret *= i;
	}
	return ret;
}

unittest {
	import std.format;
	assert(factorial(0) == 1);
	assert(factorial(1) == 1);
	assert(factorial(2) == 2);
	assert(factorial(3) == 6);
	assert(factorial(4) == 24);
}

double availability(T,S)(const S numNodes, const ref Bitset!T bitSet, 
		const size_t p, const double stepWidth = 0.01) pure {
	import core.bitop : popcnt;
	const bitsSet = popcnt(bitSet.store);
	return availability(numNodes, bitsSet, p, stepWidth);
}

double availability(S)(const S numNodes, const size_t numAvail, const size_t p,
		const double stepWidth = 0.01) pure 
{
	import availabilitylookuptable;
	const double realP = cast(double)(p) * stepWidth;
	//return pow(realP, cast(double)numAvail) * pow((1.0 - realP), cast(double)(numNodes - numAvail));
	return fastAvailabilty(numNodes, numAvail, p);
}

double oldAvailability(S)(const S numNodes, const size_t numAvail, const size_t p,
		const double stepWidth = 0.01) pure 
{
	import availabilitylookuptable;
	const double realP = cast(double)(p) * stepWidth;
	return pow(realP, cast(double)numAvail) * pow((1.0 - realP), cast(double)(numNodes - numAvail));
}

unittest {
	import std.format : format;
	import availabilitylookuptable;
	double step = 0.01;
	for(int i = 0; i < 24; ++i) {
		for(int j = 0; j <= i; ++j) {
			for(size_t p = 0; p < 101; ++p) {
				auto oldAvail = oldAvailability(i, j, p);
				auto newAvail = availability(i, j, p);
				assert(approxEqual(oldAvail, newAvail, 0.0000001),
					format("%10.8f %10.8f %3d %3d %3d",
						oldAvail, newAvail, i, j, p)
				);
			}
		}
	}
}

long binomialFunc(long n, long k) pure {
	long c = 1; 
	if(k > n-k) {
		k = n-k;	/* take advantage of symmetry */
	}
	for(long i = 1; i <= k; i++, n--) {
		if(c/i > long.max/n) throw new Exception("binomial overflow");	/* return 0 on overflow */
		c = c/i * n + c%i * n / i;	/* split c*n/i into (c/i*i + c%i)*n/i */
	}
	return c;
}

long binomial(long n, long k) pure nothrow @nogc {
	static immutable binotable = [
	[ 1 ],
	[ 1, 1 ],
	[ 1, 2, 1 ],
	[ 1, 3, 3, 1 ],
	[ 1, 4, 6, 4, 1 ],
	[ 1, 5, 10, 10, 5, 1 ],
	[ 1, 6, 15, 20, 15, 6, 1 ],
	[ 1, 7, 21, 35, 35, 21, 7, 1 ],
	[ 1, 8, 28, 56, 70, 56, 28, 8, 1 ],
	[ 1, 9, 36, 84, 126, 126, 84, 36, 9, 1 ],
	[ 1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1 ],
	[ 1, 11, 55, 165, 330, 462, 462, 330, 165, 55, 11, 1 ],
	[ 1, 12, 66, 220, 495, 792, 924, 792, 495, 220, 66, 12, 1 ],
	[ 1, 13, 78, 286, 715, 1287, 1716, 1716, 1287, 715, 286, 78, 13, 1 ],
	[ 1, 14, 91, 364, 1001, 2002, 3003, 3432, 3003, 2002, 1001, 364, 91, 14, 1 ],
	[ 1, 15, 105, 455, 1365, 3003, 5005, 6435, 6435, 5005, 3003, 1365, 455, 105, 
		15, 1 ],
	[ 1, 16, 120, 560, 1820, 4368, 8008, 11440, 12870, 11440, 8008, 4368, 1820, 
		560, 120, 16, 1 ],
	[ 1, 17, 136, 680, 2380, 6188, 12376, 19448, 24310, 24310, 19448, 12376, 
		6188, 2380, 680, 136, 17, 1 ],
	[ 1, 18, 153, 816, 3060, 8568, 18564, 31824, 43758, 48620, 43758, 31824, 
		18564, 8568, 3060, 816, 153, 18, 1 ],
	[ 1, 19, 171, 969, 3876, 11628, 27132, 50388, 75582, 92378, 92378, 75582, 
		50388, 27132, 11628, 3876, 969, 171, 19, 1 ],
	[ 1, 20, 190, 1140, 4845, 15504, 38760, 77520, 125970, 167960, 184756, 
		167960, 125970, 77520, 38760, 15504, 4845, 1140, 190, 20, 1 ],
	[ 1, 21, 210, 1330, 5985, 20349, 54264, 116280, 203490, 293930, 352716, 
		352716, 293930, 203490, 116280, 54264, 20349, 5985, 1330, 210, 21, 1 ],
	[ 1, 22, 231, 1540, 7315, 26334, 74613, 170544, 319770, 497420, 646646, 
		705432, 646646, 497420, 319770, 170544, 74613, 26334, 7315, 1540, 231, 
		22, 1 ],
	[ 1, 23, 253, 1771, 8855, 33649, 100947, 245157, 490314, 817190, 1144066, 
		1352078, 1352078, 1144066, 817190, 490314, 245157, 100947, 33649, 8855, 
		1771, 253, 23, 1 ],
	[ 1, 24, 276, 2024, 10626, 42504, 134596, 346104, 735471, 1307504, 1961256, 
		2496144, 2704156, 2496144, 1961256, 1307504, 735471, 346104, 134596, 
		42504, 10626, 2024, 276, 24, 1 ],
	[ 1, 25, 300, 2300, 12650, 53130, 177100, 480700, 1081575, 2042975, 3268760, 
		4457400, 5200300, 5200300, 4457400, 3268760, 2042975, 1081575, 480700, 
		177100, 53130, 12650, 2300, 300, 25, 1 ],
	[ 1, 26, 325, 2600, 14950, 65780, 230230, 657800, 1562275, 3124550, 5311735, 
		7726160, 9657700, 10400600, 9657700, 7726160, 5311735, 3124550, 1562275, 
		657800, 230230, 65780, 14950, 2600, 325, 26, 1 ],
	[ 1, 27, 351, 2925, 17550, 80730, 296010, 888030, 2220075, 4686825, 8436285, 
		13037895, 17383860, 20058300, 20058300, 17383860, 13037895, 8436285, 4686825, 
		2220075, 888030, 296010, 80730, 17550, 2925, 351, 27, 1 ],
	[ 1, 28, 378, 3276, 20475, 98280, 376740, 1184040, 3108105, 6906900, 13123110, 
		21474180, 30421755, 37442160, 40116600, 37442160, 30421755, 21474180, 
		13123110, 6906900, 3108105, 1184040, 376740, 98280, 20475, 3276, 378, 28, 1 ],
	[ 1, 29, 406, 3654, 23751, 118755, 475020, 1560780, 4292145, 10015005, 20030010, 
		34597290, 51895935, 67863915, 77558760, 77558760, 67863915, 51895935, 
		34597290, 20030010, 10015005, 4292145, 1560780, 475020, 118755, 23751, 3654, 
		406, 29, 1 ],
	[ 1, 30, 435, 4060, 27405, 142506, 593775, 2035800, 5852925, 14307150, 30045015, 
		54627300, 86493225, 119759850, 145422675, 155117520, 145422675, 119759850, 
		86493225, 54627300, 30045015, 14307150, 5852925, 2035800, 593775, 142506, 
		27405, 4060, 435, 30, 1 ],
	[ 1, 31, 465, 4495, 31465, 169911, 736281, 2629575, 7888725, 20160075, 44352165, 
		84672315, 141120525, 206253075, 265182525, 300540195, 300540195, 265182525, 
		206253075, 141120525, 84672315, 44352165, 20160075, 7888725, 2629575, 736281, 
		169911, 31465, 4495, 465, 31, 1 ],
	];
	return binotable[n][k];
}

unittest {
	auto rslt = [
		[1],
 		[ 1, 1 ],
 		[ 1, 2, 1, ],
 		[ 1, 3, 3, 1 ],
 		[ 1, 4, 6, 4, 1 ],
 		[ 1, 5, 10, 10, 5, 1 ],
 		[ 1, 6, 15, 20, 15, 6, 1 ],
 		[ 1, 7, 21, 35, 35, 21, 7, 1 ],
 		[ 1, 8, 28, 56, 70, 56, 28, 8, 1 ]
	];

	for(int n = 0; n < rslt.length; ++n) {
		for(int k = 0; k <= n; ++k) {
			assert(binomialFunc(n, k) == rslt[n][k]);
		}
	}

	for(int n = 0; n < 32; ++n) {
		for(int k = 0; k <= n; ++k) {
			assert(binomialFunc(n, k) == binomial(n, k));
		}
	}
}

vec3d dirOfEdge(vec3d begin, vec3d end) {
	return end - begin;
}

double angleFunc(const vec3d a, const vec3d o) {
	static double SafeAcos(double x) {
		if (x < -1.0) x = -1.0 ;
		else if (x > 1.0) x = 1.0 ;
		return acos(x) ;
	}

	double divident = a.x * o.x + a.y * o.y;
	assert(!isNaN(divident));
	double divisor = sqrt(pow(a.x, 2) + pow(a.y, 2)) * 
		sqrt(pow(o.x, 2) + pow(o.y, 2));
	assert(!isNaN(divisor));
	assert(!isNaN(divident / divisor));
	assert(!isNaN(SafeAcos(divident / divisor)));
	double tmp = SafeAcos(divident / divisor) * (180 / PI);

	if(a.x*o.y - a.y*o.x < 0) {
		tmp = -tmp;
	}
	assert(!isNaN(tmp));
	return tmp;
}

unittest {
	auto zero = vec3d( 0.0, 0.0, 0.0);
	auto left = vec3d(-1.0, 0.0, 0.0);
	auto right = vec3d(1.0, 0.0, 0.0);
	auto top = vec3d(0.0, 1.0, 0.0);
	auto bottom = vec3d(0.0, -1.0, 0.0);

	double a = angleFunc(dirOfEdge(left, zero), dirOfEdge(zero, right));
	assert(approxEqual(a, 0.0));

	a = angleFunc(dirOfEdge(left, zero), dirOfEdge(zero, top));
	assert(approxEqual(a, 90.0));

	a = angleFunc(dirOfEdge(left, zero), dirOfEdge(zero, bottom));
	assert(approxEqual(a, -90.0));

	a = angleFunc(dirOfEdge(left, zero), dirOfEdge(zero, left));
	assert(approxEqual(abs(a), 180.0));
}

void deziToFac(long deci, ref FixedSizeArray!(ubyte,16) fac) {
	import std.algorithm.mutation : reverse;
	import std.conv : to;
	for(long i = 1; deci != 0; ++i) {
		fac.insertBack(to!ubyte(deci % i));
		deci /= i;
	}

	if(fac.empty) {
		fac.insertBack(cast(ubyte)0);
	}

	reverse(fac[]);
}

long facToDezi(ref const(FixedSizeArray!(ubyte,16)) fac) {
	long ret = 0L;

	long inS = fac.length-1u;

	size_t idx = 0u;
	for(; inS > 0; --inS, ++idx) {
		ret += factorial(inS) * fac[idx];
	}	

	return ret;
}

unittest {
	import exceptionhandling;

	FixedSizeArray!(ubyte,16) rslt;
	deziToFac(2982, rslt);

	//assertEqual(rslt[], [4,0,4,1,0,0,0]);
}

unittest {
	import exceptionhandling;

	for(long i = 0; i < 1024; ++i) {
		FixedSizeArray!(ubyte,16) rslt;
		deziToFac(i, rslt);
		long dezi = facToDezi(rslt);
		assertEqual(dezi, i);
	}
}

int[] nthPermutation(int[] original, long perm) {
	import std.array;
	import std.algorithm.mutation : remove;
	import std.stdio : writefln;

	original = original.dup;

	FixedSizeArray!(ubyte,16) fac;
	deziToFac(perm, fac);

	while(fac.length < original.length) {
		fac.insertBack(cast(ubyte)0);
	}

	auto app = appender!(int[])();
	for(size_t i = 0; i < fac.length; ++i) {
		app.put(original[fac[i]]);
		original = remove(original, fac[i]);	
	}

	return app.data;
}

unittest {
	import exceptionhandling;

	auto o = [0,1,2,3,4,5,6];

	auto c = nthPermutation(o, 2982);
	assertEqual(c, [4,0,6,2,1,3,5]);
}

module utils;

import protocols;

void compare(CMP)(const ref double[101] a, const ref double[101] b, CMP cmp) {
	for(size_t i = 0; i < 101; ++i) {
		assert(cmp(a[i], a[i]));
	}
}

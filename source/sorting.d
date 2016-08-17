module sorting;

void sort(T,C)(ref T a, C cmp, ulong leftb = 0,
		 ulong rightb = 0) {
	debug assert(rightb <= a.length-1, "right index out of bound");
	debug assert(leftb <= rightb, "left index to big");

	//swap function
	void swap(S)(ref S m, ref S n) {
		auto tmp = m;
		m = n;
		n = tmp;
	}

	//partition function
	long partition(ulong left, ulong right) {
		ulong idx = (left+right+1)/2;
		auto pivot = a[idx];
		swap(a[idx], a[right]);
		for(ulong i = idx = left; i < right; i++) {
			if(cmp(a[i], pivot)) {
				swap(a[idx++], a[i]);
			}
		}
		swap(a[idx], a[right]);
		return idx;
	}

	//the actual quicksort begins here
	long[128] stack;
	long stackTop = 0;
	stack[stackTop++] = leftb;
	if(rightb != 0) {
		stack[stackTop++] = rightb;
	} else {
		stack[stackTop++] = a.length-1;
	}
	while(stackTop > 0) {
		long right = stack[--stackTop];
		long left = stack[--stackTop];
		while(right > left) {
			long i = partition(left, right);
			if(i-1 > left) {
				stack[stackTop++] = left;
				stack[stackTop++] = i-1;
			}
			left = i+1;
		}
	}
}

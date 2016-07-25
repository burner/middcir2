module utils;

import protocols;

import containers.dynamicarray;

void removeAll(T)(ref DynamicArray!T arr) {
	while(!arr.empty()) {
		arr.remove(arr.length - 1);
	}
}

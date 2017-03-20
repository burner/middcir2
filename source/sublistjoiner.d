module sublistjoiner;

import std.experimental.logger;

alias SubListJoiner = SubListJoinerImpl!16;

struct SubListJoinerImpl(int Size) {
	import std.json;
	import bitsetmodule;
	import bitsetrbtree;
	import std.algorithm : max;
	import std.array : back;
	import protocols;

	alias BSType = TypeFromSize!Size;

	string folderName;

	BitsetStore!BSType read;
	BitsetStore!BSType write;

	this(string folderName) {
		this.folderName = folderName;
	}

	auto getFilesSortedImpl(string reg) {
		import std.array : array;
		import std.file : dirEntries, SpanMode;
		import std.algorithm : sort;
		return sort(array(dirEntries(this.folderName, reg, SpanMode.shallow)));
	}

	auto getFilesSortedRead() {
		return getFilesSortedImpl("read_*");
	}

	auto getFilesSortedWrite() {
		return getFilesSortedImpl("write_*");
	}

	Result calcAC() {
		import std.conv : to;
		logf("read");
		auto mrn = fill(getFilesSortedRead(), this.read);
		logf("write");
		auto mwn = fill(getFilesSortedWrite(), this.write);
		
		logf("calcAvailForTree");
		return calcAvailForTree!(typeof(this.read))(to!int(max(mrn, mwn)), 
			this.read, this.write
		);
	}

	static long fill(Files)(Files files, ref BitsetStore!BSType dest) {
		import std.file : readText;
		long maxNodes;

		foreach(f; files) {
			logf("file %s", f);
			auto j = parseJSON(readText(f));
			//logf("%s", j);
			foreach(it; j["list"].array) {
				Bitset!BSType head = Bitset!BSType(cast(BSType)it["head"].integer());
				maxNodes = max(head.store, maxNodes);
				auto ptr = dest.search(head);
				if(ptr.isNull()) {
					dest.insert(head);
					ptr = dest.search(head);
					assert(!ptr.isNull());
					foreach(jt; it["supersets"].array) {
						(*ptr).subsets ~= Bitset!BSType(cast(BSType)jt.integer());
						maxNodes = max((*ptr).subsets.back.store, maxNodes);
					}
				} else {
					(*ptr).subsets ~= head;
					foreach(jt; it["supersets"].array) {
						(*ptr).subsets ~= Bitset!BSType(cast(BSType)jt.integer());
						maxNodes = max((*ptr).subsets.back.store, maxNodes);
					}
				}
			}
		}
		return maxNodes;
	}
}

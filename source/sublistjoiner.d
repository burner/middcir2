module sublistjoiner;

alias SubListJoiner = SubListJoinerImpl!16

struct SubListJoinerImpl(int Size) {
	alias BSType = TypeFromSize!Size;

	string folderName;

	BitsetStore!BSType read;
	BitsetStore!BSType write;

	this(string folderName) {
		this.folderName = folderName;
	}

	auto getFilesSorted() {

	}
}

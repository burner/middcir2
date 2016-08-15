module fixedsizearray;

import std.array : back;
import std.experimental.logger;

import exceptionhandling;

struct FixedSizeArraySlice(T, size_t Size) {
	FixedSizeArray!(T,Size)* fsa;
	short low;
	short high;

	this(FixedSizeArray!(T,Size)* fsa, short low, short high) {
		this.fsa = fsa;
		this.low = low;
		this.high = high;
	}

	@property bool empty() pure @safe nothrow @nogc {
		return this.low == this.high;
	}

	@property size_t length() pure @safe nothrow @nogc {
		return this.high - this.low;
	}

	@property ref T front() {
		return (*this.fsa)[this.low];
	}

	@property ref T back() {
		return (*this.fsa)[this.high - 1];
	}

	ref T opIndex(const size_t idx) {
		return (*this.fsa)[this.low + idx];
	}

	void popFront() pure @safe nothrow @nogc {
		++this.low;
	}

	void popBack() pure @safe nothrow @nogc {
		--this.high;
	}
}

struct FixedSizeArray(T,size_t Size = 32) {
	import std.traits;
	size_t len;
	byte[T.sizeof * Size] store;

	~this() {
		this.removeAll();
	}

	void insertBack(S)(auto ref S t) @trusted {
		import std.conv : emplace;
		static assert(isImplicitlyConvertible!(S,T));
		assert(this.len + 1 < Size);

		emplace(cast(T*)(&this.store[this.len * T.sizeof]), t);
		++this.len;
	}

	void emplaceBack(Args...)(auto ref Args args) {
		import std.conv : emplace;
		assert(this.len + 1 < Size);

		emplace(cast(T*)(&this.store[this.len * T.sizeof]), args);
		++this.len;
	}

	void removeBack() {
		assert(this.len > 0);

		static if(hasElaborateDestructor!T) {
			this.back().__dtor();
		}

		--this.len;
	}

	void removeAll() {
		while(!this.empty) {
			this.removeBack();
		}
	}

	@property ref T back() @trusted {
		assert(this.len > 0);
		return *(cast(T*)(&this.store[(this.len - 1) * T.sizeof]));
	}

	@property ref T front() @trusted {
		assert(this.len > 0);
		return *(cast(T*)(this.store.ptr));
	}

	ref T opIndex(const size_t idx) @trusted {
		assert(idx <= this.len);
		return *(cast(T*)(&this.store[idx * T.sizeof]));
	}

	@property size_t length() const pure @nogc nothrow {
		return this.len;
	}

	@property size_t empty() const pure @nogc nothrow {
		return this.len == 0UL;
	}

	auto opSlice() pure @nogc @safe nothrow {
		return FixedSizeArraySlice!(T,Size)(&this, cast(short)0, 
				cast(short)this.len
		);
	}
	
	auto opSlice(const size_t low, const size_t high) pure @nogc @safe nothrow {
		return FixedSizeArraySlice!(T,Size)(&this, cast(short)low, 
				cast(short)high
		);
	}
}

pure nothrow unittest {
	FixedSizeArray!(int,16) fsa;
	foreach(it; [0,1,2,4,32,64,1024,2048,65000]) {
		fsa.insertBack(it);
		assert(fsa.front() == it);
		assert(fsa.back() == it);
		assert(fsa[0] == it);
		assert(fsa.length == 1);
		assert(!fsa.empty);

		auto s = fsa[];
		assert(s.length == 1);
		assert(!s.empty);
		cast(void)assertEqual(s.front, it);
		cast(void)assertEqual(s.back, it);

		auto sc = s;
		auto sc2 = s;

		s.popFront();
		sc.popBack();
		assert(s.length == 0);
		assert(s.empty);
		assert(sc.length == 0);
		assert(sc.empty);

		sc2.front = 1337;
		cast(void)assertEqual(fsa.front, 1337);
		cast(void)assertEqual(fsa.back, 1337);

		fsa.removeBack();
		assert(fsa.length == 0);
		assert(fsa.empty);
	}
}

unittest {
	FixedSizeArray!(int,16) fsa;
	foreach(it; [[0], [0,1,2,3,4], [2,3,6,5,6,2123,9,36,6123,624565345]]) {
		foreach(jdx, jt; it) {
			fsa.insertBack(jt);
			cast(void)assertEqual(fsa.length, jdx + 1);
			foreach(kdx, kt; it[0 .. jdx]) {
				assertEqual(fsa[kdx], kt);
			}

			auto forward = fsa[];
			auto forward2 = forward;
			cast(void)assertEqual(forward.length, jdx + 1);
			for(size_t i = 0; i < forward.length; ++i) {
				cast(void)assertEqual(forward[i], it[i]);
				cast(void)assertEqual(forward2.front, it[i]);
				forward2.popFront();
			}
			assert(forward2.empty);

			auto backward = fsa[];
			auto backward2 = backward;
			cast(void)assertEqual(backward.length, jdx + 1);
			for(size_t i = 0; i < backward.length; ++i) {
				cast(void)assertEqual(backward[backward.length - i - 1],
						it[jdx - i]
				);

				cast(void)assertEqual(backward2.back, 
						it[0 .. jdx + 1 - i].back
				);
				backward2.popBack();
			}
			assert(backward2.empty);
			auto forward3 = fsa[];
			auto forward4 = fsa[0 .. jdx + 1];

			while(!forward3.empty && !forward4.empty) {
				cast(void)assertEqual(forward3.front, forward4.front);
				cast(void)assertEqual(forward3.back, forward4.back);
				forward3.popFront();
				forward4.popFront();
			}
			assert(forward3.empty);
			assert(forward4.empty);
		}
		fsa.removeAll();
	}
}

unittest {
	int cnt;

	struct Foo {
		int* cnt;
		this(int* cnt) { this.cnt = cnt; }
		~this() { if(cnt) { ++(*cnt); } }
	}

	{
		FixedSizeArray!(Foo) fsa;
		fsa.insertBack(Foo(&cnt));
		fsa.insertBack(Foo(&cnt));
		fsa.insertBack(Foo(&cnt));
		fsa.insertBack(Foo(&cnt));
	}

	cast(void)assertEqual(cnt, 8);

	int cnt2;
	{
		FixedSizeArray!(Foo) fsa;
		fsa.emplaceBack(&cnt2);
		fsa.emplaceBack(&cnt2);
		fsa.emplaceBack(&cnt2);
		fsa.emplaceBack(&cnt2);
	}

	cast(void)assertEqual(cnt2, 4);
}

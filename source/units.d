module units;

import std.traits : Unqual;
import core.exception : AssertError;

import exceptionhandling;

struct Quantity(T, string name, T min = T.min, T max = T.max) {
	import std.format : format, formatValue, FormatSpec;
	T value;

	this(T value) {
		this.value = value;
		this.checkBounds();
	}

	void checkBounds() const {
		ensure(this.value >= min, 
				"Value", this.value, "smaller than min allowed value", min);

		ensure(this.value <= max, 
				"Value", this.value, "greater than max allowed value", max);
	}

	typeof(this) opUnary(string op)() const if(op == "+" || op == "-") {
		Unqual!(typeof(this)) ret = this;	
		static if(op == "+") {
			ret.value = +ret.value;
		} else {
			ret.value = -ret.value;
		}
		ret.checkBounds();
		return ret;
	}

	typeof(this) opUnary(string op)() if(op == "++" || op == "--") {
		static if(op == "++") {
			this.value++;
		} else {
			this.value--;
		}
		this.checkBounds();
		return this;
	}

	typeof(this) opBinary(string op)(typeof(this) other) const {
		enum binOp = format(
				"return typeof(this)(this.value %s other.value);", 
				op
			);

		mixin(binOp);
	}

	typeof(this) opOpAssign(string op)(typeof(this) other) {
		enum binOp = format(
				"this.value = this.value %s other.value;", 
				op
			);

		mixin(binOp);
		this.checkBounds();
		return this;
	}

	bool opEquals(S)(auto ref const S other) const
			if(is(Unqual!(typeof(this)) == Unqual!(S))) 
	{
		return this.value == other.value;
	}

	bool opEquals(S)(auto ref const S other) const
			if(is(T == Unqual!(S))) 
	{
		return this.value == other;
	}

	void toString(scope void delegate(const(char)[]) sink, 
			FormatSpec!char fmt) const 
	{

		formatValue(sink, this.value, fmt);
	}
}

unittest {
	alias ROW = Quantity!(double, "ReadOverWrite", 0.0, 1.0);

	ROW a = ROW(0.5);
	assertThrown!Exception(-a);
}

unittest {
	import std.format : format;

	alias BoundInt = Quantity!(int, "BoundInt", -10, 10);

	int i = 5;
	auto a = BoundInt(i);

	assertEqual(a, i);
	++a;
	assertEqual(a, i+1);
	--a;
	assertEqual(a, i);

	auto b = -a;
	assertEqual(b, -i);
	auto c = +a;
	assertEqual(c, i);

	assertEqual(a, c);

	a = BoundInt(2);
	c = BoundInt(3);

	BoundInt d = a + c;
	assertEqual(d, 5);

	static assert(!__traits(compiles, a = 5));
	static assert( __traits(compiles, a = c));

	a += d;
	assertEqual(a, 7);

	string s = format("%s", a);
	assertEqual(s, "7");
}

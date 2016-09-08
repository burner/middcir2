module units;

import std.traits : Unqual;
import core.exception : AssertError;

import exceptionhandling;

struct Quantity(T, string name, T min = T.min, T max = T.max) {
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
}

unittest {
	alias ROW = Quantity!(double, "ReadOverWrite", 0.0, 1.0);

	ROW a = ROW(0.5);
	assertThrown!AssertError(-a);
}

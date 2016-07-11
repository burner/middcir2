module rbtree;

import std.stdio;

struct Iterator(T) {
	private Node!(T) current;

	void opUnary(string s)() if(s == "++") { increment(); }
	void opUnary(string s)() if(s == "--") { decrement(); }
	ref T opUnary(string s)() if(s == "*") { return getData(); }

	this(Node!(T) current) {
		this.current = current;
	}

	Iterator!(T) dup() {
		return Iterator!(T)(this.current);
	}

	//void opUnary(string s)() if(s == "++") {
	void increment() {
		Node!(T) y;
		if(null !is (y = this.current.link[true])) {
			while(y.link[false] !is null) {
				y = y.link[false];
			}
			this.current = y;
		} else {
			y = this.current.parent;
			while(y !is null && this.current is y.link[true]) {
				this.current = y;
				y = y.parent;
			}
			this.current = y;
		}
	}	

	ref T getData() {
		return this.current.getData();
	}

	//void opUnary(string s)() if(s == "--") {
	void decrement() {
		Node!(T) y;
		if(null !is (y = this.current.link[false])) {
			while(y.link[true] !is null) {
				y = y.link[true];
			}
			this.current = y;
		} else {
			y = this.current.parent;
			while(y !is null && this.current is y.link[false]) {
				this.current = y;
				y = y.parent;
			}
			this.current = y;
		}
	}

	bool isValid() const {
		return this.current !is null;
	}
}

class Node(T) {
	T data;
	bool red;

	Node!(T)[2] link;
	Node!(T) parent;

	this() {
		this.parent = null;
        this.link[0] = null;
        this.link[1] = null;
	}

	this(T data) {
		this.data = data;
		this.red = true;
	}

	ref T getData() {
		return this.data;
	}

	bool validate(bool root, const Node!(T) par = null) const {
		import std.stdio : writeln;
		if(!root) {
			if(this.parent is null) {
				writeln(__FILE__,__LINE__,": parent is null");
				return false;
			}
			if(this.parent !is par) {
				writeln(__FILE__,__LINE__,": parent is wrong ");
					//, parent.data, 
					//" ",par.data);
				return false;
			}
		}
		bool left = true;
		bool right = true;
		if(this.link[0] !is null) {
			assert(this.link[0].parent is this);
			left = this.link[0].validate(false, this);
		}
		if(this.link[1] !is null) {
			assert(this.link[1].parent is this);
			right = this.link[1].validate(false, this);
		}
		return left && right;
	}

	void print() const {
		//println(this.data);
		if(this.link[0] !is null) {
			this.link[0].print();
		}
		if(this.link[1] !is null) {
			this.link[1].print();
		}
	}
}

bool defaultLess(T)(ref T l, ref T r) {
	return l < r;
}

bool defaultEqual(T)(ref T l, ref T r) {
	return l == r;
}

struct RBTree(T,alias less = defaultLess, alias equal = defaultEqual) {
	size_t size;
	Node!(T) root;

	@property size_t length() const {
		return this.size;
	}

	Iterator!(T) begin() {
		Node!(T) be = this.root;
		if(be is null) {
			return Iterator!(T)(null);
		}

		int count = 0;
		while(be.link[0] !is null) {
			be = be.link[0];
			count++;
		}
		auto it =  Iterator!(T)(be);
		//println(__LINE__," ",count, " ", be is null, " ", it is null, " ", it.isValid(), " ", *it);
		return it;	
	}

	Iterator!(T) end() {
		Node!(T) end = this.root;
		if(end is null) {
			return Iterator!(T)(null);
		}

		while(end.link[1] !is null) {
			end = end.link[1];
		}

		return Iterator!(T)(end);
	}

	T[] values() {
		import std.conv : to;
		if(this.size == 0) {
			return null;
		}
		T[] ret = new T[this.size];
		size_t ptr = 0;
		Iterator!(T) it = this.begin();
		//println(__LINE__," ", it.isValid());
		while(it.isValid()) {
			//println(ptr, " ", *it);
			ret[ptr++] = *it;
			it++;
		}

		assert(ptr == ret.length, to!(string)(ptr) ~ " " ~
			to!(string)(ret.length));
		return ret;
	}

	Iterator!(T) searchIt(T data) {
		return Iterator!(T)(cast(Node!(T))search(data));
	}

	void clear() {
	    this.root = null;
	    this.size = 0;
	}
	 
	bool isEmpty() const {
	    return this.root is null;
	}
	private static isRed(const Node!(T) n) {
		return n !is null && n.red;
	}

	private static singleRotate(Node!(T) node, bool dir) {
		Node!(T) save = node.link[!dir];
		node.link[!dir] = save.link[dir];
		if(node.link[!dir] !is null) {
			node.link[!dir].parent = node;
		}
		save.link[dir] = node;
		if(save.link[dir] !is null) {
			save.link[dir].parent = save;
		}
		node.red = true;
		save.red = false;
		return save;
	}

	private static doubleRotate(Node!(T) node, bool dir) {
		node.link[!dir] = singleRotate(node.link[!dir], !dir);
		if(node.link[!dir] !is null) {
			node.link[!dir].parent = node;	
		}
		return singleRotate(node, dir);
	}

	private static int validate(Node!(T) node, Node!(T) parent) {
		if(node is null) {
			return 1;
		} else {
			if(node.parent !is parent) {
				writeln("parent violation ", node.parent is null, " ",
					parent is null);
			}
			if(node.link[0] !is null)
				if(node.link[0].parent !is node) {
					writeln("parent violation link wrong");

				}
			if(node.link[1] !is null)
				if(node.link[1].parent !is node) {
					writeln("parent violation link wrong");

				}

			Node!(T) ln = node.link[0];
			Node!(T) rn = node.link[1];

			if(isRed(node)) {
				if(isRed(ln) || isRed(rn)) {
					writeln("Red violation");
					return 0;
				}
			}
			int lh = validate(ln, node);
			int rh = validate(rn, node);
			
			//if((ln !is null && ln.data >= node.data)
			if((ln !is null 
					&& (less(node.data, ln.data) || equal(node.data, ln.data))
				)
					//|| (rn !is null && rn.data <= node.data)) 
					|| (rn !is null 
						&& (!less(rn.data, node.data) || equal(rn.data, node.data))))
			{
				writeln("Binary tree violation");
				return 0;
			}

			if(lh != 0 && rh != 0 && lh != rh) {
				writeln("Black violation ", lh, " ", rh);
				return 0;
			}

			if(lh != 0 && rh != 0)
				return isRed(node) ? lh : lh +1;
			else
				return 0;
		}
	}

	bool validate() {
		return validate(this.root, null) != 0;	
	}

	Node!(T) search(T data) {
		return search(this.root, data);
	}

	private Node!(T) search(Node!(T) node ,T data) {
		if(node is null) {
			return null;
		} else if(equal(node.data, data)) {
			return node;
		} else {
			bool dir = less(node.data, data);
			return this.search(node.link[dir], data);
		}
	}

	bool remove(ref Iterator!(T) it, bool dir = true) {
		if(it.isValid()) {
			T value = *it;
			if(dir)
				it++;
			else
				it--;
			return this.remove(value);
		} else {
			return false;
		}
	}

	bool remove(T data) {
		bool done = false;
		bool succes = false;
		this.root = removeR(this.root, data, done, succes);
		if(this.root !is null) {
			this.root.red = false;
			this.root.parent = null;
		}
		if(succes)
			this.size--;
		return succes;
	}

	private static Node!(T) removeR(Node!(T) node, T data, ref bool done, 
			ref bool succes) {
		if(node is null)
			done = true;
		else {
			bool dir;
			if(equal(node.data, data)) {
				succes = true;
				if(node.link[0] is null || node.link[1] is null) {
					Node!(T) save = node.link[node.link[0] is null];	

					if(isRed(node)) {
						done = true;
					} else if(isRed(save)) {
						save.red = false;
						done = true;
					}
					return save;
				} else {
					Node!(T) heir = node.link[0];
					while(heir.link[1] !is null)
						heir = heir.link[1];

					node.data = heir.data;
					data = heir.data;
				}
			}
			dir = less(node.data, data);
			node.link[dir] = removeR(node.link[dir], data, done, succes);
			if(node.link[dir] !is null) {
				node.link[dir].parent = node;
			}

			if(!done)
				node = removeBalance(node, dir, done);
		}
		return node;
	}

	private static Node!(T) removeBalance(Node!(T) node, bool dir, ref bool done) {
		Node!(T) p = node;
		Node!(T) s = node.link[!dir];
		if(isRed(s)) {
			node = singleRotate(node, dir);
			s = p.link[!dir];
		}
		
		if(s !is null) {
			if(!isRed(s.link[0]) && !isRed(s.link[1])) {
				if(isRed(p))
					done = true;
				p.red = false;
				s.red = true;
			} else {
				bool save = p.red;
				bool newRoot = (node is p);
				
				if(isRed(s.link[!dir]))
					p = singleRotate(p, dir);
				else
					p = doubleRotate(p, dir);

				p.red = save;
				p.link[0].red = false;
				p.link[1].red = false;

				if(newRoot) {
					node = p;
				} else {
					node.link[dir] = p;
					if(node.link[dir] !is null) {
						node.link[dir].parent = node;
					}
				}

				done = true;
			}
		}
		return node;
	}
	
	bool insert(T data) {
		if(this.root is null) {
			this.root = new Node!(T)(data);
			if(this.root is null) 
				return false;
			this.size++;
		} else {
			scope Node!(T) head = new Node!(T)();
			Node!(T) g, t;
			Node!(T) p, q;
			bool dir = false, last;

			t = head;
			g = p = null;
			q = t.link[1] = this.root;

			while(true) {
				if(q is null) {
					p.link[dir] = q = new Node!(T)(data);
					if(q is null)
						return false;
					else {
						q.parent = p;
						this.size++;
					}
				} else if(isRed(q.link[0]) && isRed(q.link[1])) {
					q.red = true;
					q.link[0].red = false;
					q.link[1].red = false;
					if(q.link[0] !is null) {
						q.link[0].parent = q;
					}
					if(q.link[1] !is null) {
						q.link[1].parent = q;
					}
				}
				if(isRed(q) && isRed(p)) {
					bool dir2 = t.link[1] is g;
					if(q is p.link[last]) {
						t.link[dir2] = singleRotate(g,!last);
						if(t.link[dir2] !is null) {
							t.link[dir2].parent = t;
						}
					} else {
						t.link[dir2] = doubleRotate(g,!last);
						if(t.link[dir2] !is null) {
							t.link[dir2].parent = t;
						}
					}
				}

				if(equal(q.data, data)) {
					break;
				}

				last = dir;
				dir = less(q.data, data);

				if(g !is null)
					t = g;
				g = p;
				p = q;
				q = q.link[dir];
			}
			this.root = head.link[1];
			if(this.root !is null) {
				this.root.parent = null;
			}
		}
		this.root.red = false;				
		return true;
	}
}

bool compare(T)(RBTree!(T) t, T[T] s) {
	foreach(it; s.values) {
		if(t.search(it) is null) {
			writeln(__LINE__, " size wrong");
			return false;
		}
	}
	return true;
}

unittest {
	import std.conv : to;
	int[][] lot = [[2811, 1089, 3909, 3593, 1980, 2863, 676, 258, 2499, 3147,
	3321, 3532, 3009, 1526, 2474, 1609, 518, 1451, 796, 2147, 56, 414, 3740,
	2476, 3297, 487, 1397, 973, 2287, 2516, 543, 3784, 916, 2642, 312, 1130,
	756, 210, 170, 3510, 987], [0,1,2,3,4,5,6,7,8,9,10],
	[10,9,8,7,6,5,4,3,2,1,0],[10,9,8,7,6,5,4,3,2,1,0,11],
	[0,1,2,3,4,5,6,7,8,9,10,-1],[11,1,2,3,4,5,6,7,8,0]];
	
	foreach(lots; lot) {
		RBTree!(int) a;
		assert(a.validate());
		int[int] at;
		foreach(idx, it; lots) {
			assert(a.insert(it), to!(string)(it));
			assert(a.length() == idx+1);
			foreach(jt; lots[0..idx+1]) {
				assert(a.search(jt));
			}
			at[it] = it;
			assert(a.validate());
			assert(compare!(int)(a, at));
			foreach(jt; a.values()) {
				assert(a.search(jt));
			}

			Iterator!(int) ait = a.begin();
			size_t cnt = 0;
			while(ait.isValid()) {
				assert(a.search(*ait));
				ait++;
				cnt++;
			}
			assert(cnt == a.length(), to!(string)(cnt) ~
				" " ~ to!(string)(a.length()));

			ait = a.end();
			cnt = 0;
			while(ait.isValid()) {
				assert(a.search(*ait));
				ait--;
				cnt++;
			}
			assert(cnt == a.length(), to!(string)(cnt) ~
				" " ~ to!(string)(a.length()));

			assert(a.validate());
		}
		//writeln(__LINE__);
		foreach(idx, it; lots) {
			assert(a.remove(it));
			assert(a.length() + idx + 1 == lots.length);
			at.remove(it);
			assert(a.validate());
			assert(compare!(int)(a, at));
			foreach(jt; lots[0..idx+1]) {
				assert(!a.search(jt));
			}
			foreach(jt; lots[idx+1..$]) {
				assert(a.search(jt));
			}
			int[] values = a.values();
			//writeln(__LINE__," ", values);
			foreach(jt; values) {
				assert(a.search(jt));
			}
			Iterator!(int) ait = a.begin();
			size_t cnt = 0;
			while(ait.isValid()) {
				assert(a.search(*ait));
				ait++;
				cnt++;
			}
			assert(cnt == a.length(), to!(string)(cnt) ~
				" " ~ to!(string)(a.length()));

			ait = a.end();
			cnt = 0;
			while(ait.isValid()) {
				assert(a.search(*ait));
				ait--;
				cnt++;
			}
			assert(cnt == a.length(), to!(string)(cnt) ~
				" " ~ to!(string)(a.length()));

			assert(a.validate());
		}
		assert(a.validate());
		//writeln(__LINE__);
	}

	for(int i = 0; i < lot[0].length; i++) {
		RBTree!(int) itT;
		assert(itT.validate());
		foreach(it; lot[0]) {
			itT.insert(it);
			assert(itT.validate());
		}
		assert(itT.validate());
		assert(itT.length == lot[0].length);
		Iterator!(int) be = itT.begin();
		while(be.isValid()) {
			assert(itT.remove(be, true));
			assert(itT.validate());
		}
		assert(itT.validate());
		assert(itT.length() == 0);
	}

	for(int i = 0; i < lot[0].length; i++) {
		RBTree!(int) itT;
		assert(itT.validate());
		foreach(it; lot[0]) {
			itT.insert(it);
			assert(itT.validate());
		}
		assert(itT.length() == lot[0].length);
		Iterator!(int) be = itT.end();
		assert(itT.validate());
		while(be.isValid()) {
			assert(itT.remove(be, false));
			assert(itT.validate());
		}
		assert(itT.length() == 0);
		assert(itT.validate());
	}
}

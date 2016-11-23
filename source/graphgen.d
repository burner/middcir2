module graphgen;

import std.random;
import std.container.array : Array;
import std.experimental.logger;

import graph;

struct GraphGenConfig {
	int numNodes;
	int minEdges;
	int maxEdges;
}

Array!int getPosition(R)(ref R random, int upTo) {
	import std.range : iota;

	Array!int ret;
	ret.insertBack(iota(0,upTo));
	return ret;
}

Graph!Size genGraph(int Size,R)(ref R random, const ref GraphGenConfig config) {
	import gfm.math.vector;
	auto ret = Graph!Size(config.numNodes);

	int placedNodes = 0;
	int row = 0;
	Array!int curPlaces = getPosition(random, config.numNodes);
	randomShuffle(curPlaces[], random);
	while(placedNodes < config.numNodes) {
		const upTo = config.numNodes - placedNodes;
		int toPick;
		if(upTo == 1) {
			toPick = 1;
		} else {
			toPick = uniform(0, upTo, random);
		}
		const s = curPlaces[0 .. toPick];

		for(int i = 0; i < s.length && placedNodes < config.numNodes; ++i) {
			ret.setNodePos(placedNodes++, vec3d(s[i], row, 0.0));
		}
		randomShuffle(curPlaces[], random);

		++row;
	}

	for(int i = 0; i < ret.length; ++i) {
		const nodesToConnectTo = uniform(config.minEdges, config.maxEdges, random);
		for(int j = 0; j < nodesToConnectTo; ++j) {
			const toConnectTo = uniform(0, cast(int)ret.length, random);
			ret.setEdge(i, toConnectTo);
		}
	}

	return ret;
}

auto graphGenerator(int Size, Rnd)(int upTo, long maxTries, const(GraphGenConfig) ggc,
	   	ref Rnd rnd)
{
	return GraphGen!(Size,Rnd)(upTo, maxTries, ggc, rnd);
}

struct GraphGen(int Size, Rnd) {
	import floydmodule;
	int cnt;
	const int upTo;
	long maxTries;
	Rnd* rnd;
	const(GraphGenConfig) ggc;
	Floyd floyd;
	Graph!Size cur;

	this(int upTo, long maxTries, const(GraphGenConfig) ggc, ref Rnd rnd) {
		this.upTo = upTo;
		this.maxTries = maxTries;
		this.ggc = ggc;
		this.rnd = &rnd;
		auto tmp = Graph!Size(Size);
		this.floyd.reserveArrays(Size);
		this.popFront();
	}

	bool empty() const @property @safe pure nothrow {
		return this.cnt >= this.upTo || this.maxTries <= 0;
	}

	private void gen(ref Array!(Graph!Size) existingGraphs) {
		outer: while(true) {
			if(this.empty) {
				break;
			}
			--this.maxTries;

			Graph!Size tmp = genGraph!Size(*this.rnd, this.ggc);
			this.floyd.execute(tmp);
			for(int i = 0; i < this.ggc.numNodes; ++i) {
				for(int j = i + 1; j < this.ggc.numNodes; ++j) {
					if(!this.floyd.pathExists(i, j)) {
						continue outer;
					}
				}
			}
			foreach(ref it; existingGraphs) {
				if(it.isHomomorph(tmp)) {
					continue outer;
				}
			}
			this.cur = tmp;
			this.cnt++;
			break outer;
		}
	}

	@property Graph!Size front() {
		return this.cur;
	}

	void popFront() {
		Array!(Graph!Size) empty;
		this.gen(empty);
	}

	void popFront(ref Array!(Graph!Size) existingGraphs) {
		this.gen(existingGraphs);
	}
}

unittest {
	import std.stdio : File;
	import std.file : mkdirRecurse, chdir, getcwd;
	import std.stdio : File;
	import std.process : execute;
	import std.format : format;
	import std.exception : enforce;
	string oldcwd = getcwd();
	scope(exit) {
		chdir(oldcwd);
	}

	string path = "GraphTests/ManyGraphs2/";
	mkdirRecurse(path);
	chdir(path);

string topString =
`
\documentclass[a4]{article}
\usepackage[english]{babel}
\usepackage{graphicx}
\usepackage{standalone}
\usepackage{subcaption}
\usepackage{placeins}
\usepackage{morefloats }
\usepackage{float}
\usepackage[cm]{fullpage}
\usepackage{tikz}
\usepackage{pgfplots}
\usetikzlibrary{decorations.markings, arrows, decorations.pathmorphing,
   backgrounds, positioning, fit, shapes.geometric}
\IfFileExists{../config.tex}%
	{\input{../config}}%
	{
	\tikzstyle{place} = [shape=circle,
    draw, align=center,minimum width=0.70cm,
    top color=white, bottom color=blue!20]
	}

\begin{document}
\extrafloats{1000}
`;
	auto f = File("main.tex", "w");
	f.write(topString);
	f.writeln("\\section{New Section Because Latex Can not handle many floats}");

	auto r = Random(1234414 << 2);
	GraphGenConfig config;
	config.numNodes = 30;
	config.minEdges = 1;
	config.maxEdges = 3;
	/*for(int i = 0; i < 50; ++i) {
		auto g = genGraph!32(r, config);*/

	int i = 0;
	foreach(it; graphGenerator!32(50, 50, config, r)) {
		auto g = it;
		string fn = format("graph%s.tex", i);
		auto tf = File(fn, "w");
		g.toTikz(tf.lockingTextWriter());
		f.writefln("\\begin{figure}");
		f.writefln("\\includestandalone[width=0.9\\linewidth]{graph%s}\\", i);
		f.writefln("\\caption{Random Graph number %s}", i);
		f.writefln("\\end{figure}");
		if(i && i % 5 == 0) {
			f.writefln("\\clearpage");
			f.writeln("\\section{New Section Because Latex Can not handle many floats}");
		}
		++i;
	}

	f.writeln("\\end{document}");
}

Array!(Graph!Size) loadGraphsFromJSON(int Size)(const string filename) {
	import std.file : readText;
	import stdx.data.json;

	Array!(Graph!Size) ret;

	auto json = toJSONValue(readText(filename));

	foreach(ref it; json["graphs"].get!(JSONValue[])) {
		ret.insertBack(Graph!Size(it));
	}

	return ret;
}

void graphsToJSON(G)(const string filename, ref G g) {
	import std.stdio : File;
	auto f = File(filename, "w");
	f.write("{\n \"graphs\" : [\n");
	bool first = true;
	foreach(ref it; g[]) {
		if(first) {
			it.toJSON(f.lockingTextWriter());
		} else {
			f.write(",\n");
			it.toJSON(f.lockingTextWriter());
		}
		first = false;
	}
	f.write("\n ]\n}\n");
}

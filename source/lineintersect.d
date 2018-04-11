module lineintersect;

import std.math : approxEqual, abs;
import std.algorithm.comparison : min, max;

import gfm.math.vector;

bool lessEqual(double a, double b) pure {
	return a < b || approxEqual(a,b);
}

bool greaterEqual(double a, double b) pure {
	return a > b || approxEqual(a,b);
}

bool doLineSegmentsOverlap(vec3d a1, vec3d a2, vec3d b1, vec3d b2) {
	return 
		   doLineSegmentsOverlapTest(a1, a2, b1, b2)
		|| doLineSegmentsOverlapTest(a2, a1, b1, b2)
		|| doLineSegmentsOverlapTest(a1, a2, b2, b1)
		|| doLineSegmentsOverlapTest(a2, a1, b2, b1)
		|| doLineSegmentsOverlapTest(b1, b2, a1, a2)
		|| doLineSegmentsOverlapTest(b1, b2, a2, a1)
		|| doLineSegmentsOverlapTest(b2, b1, a1, a2)
		|| doLineSegmentsOverlapTest(b2, b1, a2, a1);
}

bool doLineSegmentsOverlapTest(vec3d a1, vec3d a2, vec3d b1, vec3d b2) {
	if(approxEqual(a1.x, b1.x) && approxEqual(a1.y, b1.y)) {
		return isPointOnLine(a1, a2, b2);
	}
	return false;
}

bool isBetween(double a, double b, double c) pure {
    // return if c is between a and b
    double larger = (a >= b) ? a : b;
    double smaller = (a != larger) ? a : b;

    return c <= larger && c >= smaller;
}

//bool pointOnLine(Vec2<double> p, Vec2<double> l1, Vec2<double> l2) {
bool isPointOnLine(vec3d a1, vec3d a2, vec3d p) {
    if(approxEqual(a2.x - a1.x, 0.0)) return isBetween(a1.y, a2.y, p.y); // vertical line
    if(approxEqual(a2.y - a1.y, 0.0)) return isBetween(a1.x, a2.x, p.x); // horizontal line

    double Ax = (p.x - a1.x) / (a2.x - a1.x);
    double Ay = (p.y - a1.y) / (a2.y - a1.y);

    // We want Ax == Ay, so check if the difference is very small (floating
    // point comparison is fun!)

    return abs(Ax - Ay) < 0.000001 && greaterEqual(Ax, 0.0) && lessEqual(Ax, 1.0);
}

//bool isPointOnLine(vec3d a1, vec3d a2, vec3d b1) {
//	 return ((a2.x - a1.x) * (b1.y - a1.y) == (b1.x - a1.x) * (a2.y - a1.y) && 
//                abs(approxEqual(a1.x, b1.x) + approxEqual(a2.x, b1.x)) <= 1 &&
//                abs(approxEqual(a1.y, b1.y) + approxEqual(a2.y, b1.y)) <= 1);
//}

// plugged from https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect/

// Given three colinear points p, q, r, the function checks if
// point q lies on line segment 'pr'
bool onSegment(vec3d p, vec3d q, vec3d r) pure {
    //if (q.x <= max(p.x, r.x) && q.x >= min(p.x, r.x) &&
    //    q.y <= max(p.y, r.y) && q.y >= min(p.y, r.y))
    if (lessEqual(q.x, max(p.x, r.x)) && greaterEqual(q.x, min(p.x, r.x)) &&
        lessEqual(q.y, max(p.y, r.y)) && greaterEqual(q.y, min(p.y, r.y)))
	{
       return true;
	}
 
    return false;
}
 
// To find orientation of ordered triplet (p, q, r).
// The function returns following values
// 0 --> p, q and r are colinear
// 1 --> Clockwise
// 2 --> Counterclockwise
int orientation(vec3d p, vec3d q, vec3d r) pure {
    // See https://www.geeksforgeeks.org/orientation-3-ordered-points/
    // for details of below formula.
    double val = (q.y - p.y) * (r.x - q.x) -
              (q.x - p.x) * (r.y - q.y);
 
    if(approxEqual(val, 0.0)) {
		return 0;  // colinear
	}
 
    return (val > 0)? 1 : 2; // clock or counterclock wise
}

bool vec3dEqual(vec3d a, vec3d b) pure {
	return approxEqual(a.x, b.x) && approxEqual(a.y, b.y);
}

bool doLinesIntersect(vec3d a1, vec3d a2, vec3d b1, vec3d b2) pure {
	double CrossProduct(vec3d p1, vec3d p2, vec3d p3) pure {
	    return (p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y);
	}
	//return 
	//  CrossProduct(line1.InitialPoint, line1.TerminalPoint, line2.InitialPoint) !=
	//	CrossProduct(line1.InitialPoint, line1.TerminalPoint, line2.TerminalPoint) ||
	//	CrossProduct(line2.InitialPoint, line2.TerminalPoint, line1.InitialPoint) !=
	//	CrossProduct(line2.InitialPoint, line2.TerminalPoint, line1.TerminalPoint);
	return !approxEqual(CrossProduct(a1, a2, b1), CrossProduct(a1, a2, b2))
		|| !approxEqual(CrossProduct(b1, b2, a1), CrossProduct(b1, b2, a2));
 }
 
// The main function that returns true if line segment 'a1a2'
// and 'b1b2' intersect.
bool doIntersect(vec3d a1, vec3d a2, vec3d b1, vec3d b2) {
	import std.experimental.logger;
    // Find the four orientations needed for general and
    // special cases
    int o1 = orientation(a1, a2, b1);
    int o2 = orientation(a1, a2, b2);
    int o3 = orientation(b1, b2, a1);
    int o4 = orientation(b1, b2, a2);
 
    // General case
    if (o1 != o2 && o3 != o4) {
    //if(!vec3dEqual(o1, o2) && !vec3dEqual(o3, o4)) {
        return true;
	}
 
    // Special Cases
    // a1, a2 and b1 are colinear and b1 lies on segment a1a2
    if (o1 == 0 && onSegment(a1, b1, a2)) return true;
 
    // a1, a2 and b2 are colinear and b2 lies on segment a1a2
    if (o2 == 0 && onSegment(a1, b2, a2)) return true;
 
    // b1, b2 and a1 are colinear and a1 lies on segment b1b2
    if (o3 == 0 && onSegment(b1, a1, b2)) return true;
 
     // b1, b2 and a2 are colinear and a2 lies on segment b1b2
    if (o4 == 0 && onSegment(b1, a2, b2)) return true;

	if(doLineSegmentsOverlap(a1, a2, b1, b2)) {
		return true;
	}

	//if(doLinesIntersect(a1, a2, b1, b2)) {
	//	logf("here");
	//	return true;
	//} else {
	//	logf("HERE");
	//}
 
    return false; // Doesn't fall in any of the above cases
}

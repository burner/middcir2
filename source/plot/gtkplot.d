module plot.gtkplot;

/*import ggplotd.ggplotd;
import ggplotd.geom;
import ggplotd.aes;
import ggplotd.gtk;


        "ggplotd": ">=0.4.5"
	"subConfigurations": {
        "ggplotd": "ggplotd-gtk"
    }

import plot;

void gtkPlot(ResultPlot[] results ...) {
	import core.thread;
	import std.array : array;
    import std.math : sqrt;
    import std.algorithm : map;
    import std.range : repeat, iota;
    import std.random : uniform;
	const width = 1024;
    const height = 1024;

    // Start gtk window.
    auto gtkwin = new GTKWindow();

    // gtkwin.run runs the GTK mainloop, so normally blocks, but we can
    // run it in its own thread to get around this

    auto tid = new Thread(() { gtkwin.run("plotcli", width, height); }).start(); 
	auto gg = GGPlotD();

	auto xs = iota(0,101,1).array;
	foreach(result; results) {
    	auto aesRead = Aes!(typeof(xs), "x", typeof(result.result.readAvail[]), "y")
			(xs, result.result.readAvail[]);

    	auto aesWrite = Aes!(typeof(xs), "x", typeof(result.result.writeAvail[]), "y")
			(xs, result.result.writeAvail[]);
    	gg.put(geomLine(aesRead));
    	gg.put(geomLine(aesWrite));
	}

    gtkwin.clearWindow();
    gtkwin.draw(gg, width, height);

    // Wait for gtk thread to finish (Window closed)
    tid.join();
}*/

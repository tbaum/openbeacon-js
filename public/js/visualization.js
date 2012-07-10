var color = d3.scale.category20b();

function hash(s) {
    if (!s) return 0;
    for (var ret = 0, i = 0, len = s.length; i < len; i++) {
        ret = (31 * ret + s.charCodeAt(i)) << 0;
    }
    return ret;
}

var ignore = { source:1, target:1, type:1, selected:1, index:1, x:1, y:1, weight:1, px:1, py:1, id:1}
function propertyHash(ob) {
    var ret = 0;
    for (var prop in ob) {
        if (ignore.hasOwnProperty(prop)) continue;
        if (ob.hasOwnProperty(prop)) {
            ret += hash(prop);
        }
    }
    return ret;
}

function toString(ob) {
    var ret = "";
    for (var prop in ob) {
        if (ignore.hasOwnProperty(prop)) continue;
        if (ob.hasOwnProperty(prop)) {
            ret += prop + ": " + ob[prop] + " ";
        }
    }
    return ret + "id: " + ob.id;
}

function title(ob) {
    if (ob.name) return ob.name;
    if (ob.title) return ob.title;
    for (var prop in ob) {
        if (ignore.hasOwnProperty(prop)) continue;
        if (ob.hasOwnProperty(prop)) {
            return ob[prop];
        }
    }
    return ob.id;
}




function visualize(id, w, h, data) {
    var vis = d3.select("#graph" ).append("svg").attr("width", w).attr("height", h);

    var force;

    if (self.force) {
        force =self.force;

        force           .nodes(data.nodes)
            .links(data.links)
             ;
    }                      else {
    force = self.force = d3.layout.force()
        .nodes(data.nodes)
        .links(data.links)
        .gravity(.2)
        .distance(80)
        .charge(-1000)
        .size([w, h]).start();

    // end-of-line arrow
    vis.append("svg:defs").selectAll("marker")
        .data(["end-marker"])// link types if needed
        .enter().append("svg:marker")
        .attr("id", String)
        .attr("viewBox", "0 -5 10 10")
        .attr("refX", 25)
        .attr("refY", -1.5)
        .attr("markerWidth", 4)
        .attr("markerHeight", 4)
        .attr("class", "marker")
        .attr("orient", "auto")
        .append("svg:path")
        .attr("d", "M0,-5L10,0L0,5");
    }


    var link = vis.selectAll("line.link")
        .data(data.links)
        .enter().append("svg:line")
        .attr("class", "link")
        .style("stroke", "red")
        .style("stroke-width", function (d) {
            return d["selected"] ? 2 : null;
        })
        .attr("x1", function (d) {
            return d.source.x;
        })
        .attr("y1", function (d) {
            return d.source.y;
        })
        .attr("x2", function (d) {
            return d.target.x;
        })
        .attr("y2", function (d) {
            return d.target.y;
        });

    var node = vis.selectAll("g.node").data(data.nodes) ;

    node.enter().append("circle")
        .attr("class", "node")
        .attr("r", 5)
        .style("fill",  "blue")
        .style("stroke-width", 2)
        .call(force.drag);

    /* node.append("title")
   #     .text(function (d) {
   #         return toString(d) + d.selected;
        });
      */

    node.style("stroke", function (d) {
        return  d["selected"] ? "red" : null;
    }) ;


    var text = vis.append("svg:g").selectAll("g")
        .data(force.nodes())
        .enter().append("svg:g");

    text.append("svg:text")
        .attr("x", 8)
        .attr("y", "-.31em")
        .attr("class", "text")
        .text(function (d) {
            return title(d);
        });


    force.on("tick", function () {
        link.attr("x1", function (d) {
            return d.source.x;
        })
            .attr("y1", function (d) {
                return d.source.y;
            })
            .attr("x2", function (d) {
                return d.target.x;
            })
            .attr("y2", function (d) {
                return d.target.y;
            });

        text.attr("transform", function (d) {
            return "translate(" + d.x + "," + d.y + ")";
        });

        node.attr("transform", function (d) {
            return "translate(" + d.x + "," + d.y + ")";
        });



    });

    //for (var i = 0; i < 100; ++i) force.tick();
    // force.stop();
    // store(force.nodes());
}

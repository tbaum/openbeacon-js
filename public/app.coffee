lastMsg = {}

socket = io.connect()
socket.on 'message', (msg)->
    $('#log').empty()
    lastMsg = msg
    for k,v of msg
        $('#log').append($('<li>').text(k).append($(' <code>').text(JSON.stringify(v))))

nodeCache = {}

#nodes = []
#3links = []
reverseIdMap = {}
lastId = 0

#findNode = (beaconId) ->
#    for node in nodes
#        return node if node.name == beaconId
#
#    return undefined

go = (data)->
    width = 960
    height = 500
    color = d3.scale.category20()

    force = d3.layout.force().charge(-120).linkDistance(30).size([ width, height ])

    svg = d3.select("#graph").append("svg").attr("width", width).attr("height", height)


    force.nodes(data.nodes).links(data.links).start()

    links = svg.selectAll("line.link").data(data.links)
    link = links.enter().append("line").attr("class", "link").style("stroke-width", 1).style("stroke", "black")

    #circles = svg.selectAll("circle.node").data(data.nodes)
    #node = circles.enter().append("circle").attr("class", "node").attr("r", 5).call(force.drag)


    node = svg.selectAll("g.node").data(data.nodes).enter().append("circle").attr("class", "node").attr("r", 5).style("fill", "black"
    ).style("stroke-width",
    (d) ->
        (if d["selected"] then 2 else 0)
    ).style("stroke",
    (d) ->
        sel = d["selected"]
        (if sel then "red" else null)
    ).call(force.drag)

    node.append("title").text (d) ->
        "d"

    text = svg.append("svg:g").selectAll("g").data(data.nodes).enter().append("svg:g").append("svg:text").attr("x", 8).attr("y", "-.31em").attr("class", "text").text (d) ->
        "d"

#    text.append("svg:text").attr("x", 8).attr("y", "-.31em").attr("class", "text shadow").text (d) ->
#        "d"

    # text

    # text = svg.selectAll("text.node").data(data.nodes)
    #node = circles.enter().append("text").attr("class", "node1").attr("r", 10) #.call(force.drag)

    #node.append("title").text (d) ->
    #    d.name

    #    text = links.append("svg:g").selectAll("g").data(force.nodes()).enter().append("svg:g");

    #text.append("svg:text").attr("x", 8).attr("y", "-.31em").attr("class", "text shadow").text( (d) ->
    #    console.log d
    #    "d"
    #)


    # text.append("svg:text").attr("x", 8).attr("y", "-.31em").attr("class", "text").text(function (d) { return title(d); });


    #circles.style("fill", (d)->
    #    if d.button then "red" else "black"
    #)


    force.on "tick", ->
        link.attr("x1",
        (d) -> d.source.x).attr("y1",
        (d) -> d.source.y).attr("x2",
        (d) -> d.target.x).attr "y2", (d) -> d.target.y
        node.attr("cx",
        (d) -> d.x).attr "cy", (d) -> d.y


n1 = {name: "Myriel", button: true}
n2 = {name: "Blub"}
n3 = {name: "Blub"}

data = {nodes: [ n1, n2, n3 ], links: [
    {source: n1, target: n2},
    {source: n1, target: n3}
]}

# go(data)


world = nodes : {}

nodes = []
links = []

drawGraph = ()->
    data = nodes: nodes, links: links

    console.log lastMsg

    nodes.length = 0
    links.length = 0

    for beaconId,beaconData of lastMsg
        # button = if then true else false

        world[beaconId]?= id: lastId, name: beaconId, selected: beaconData.button #, x: 0, y: 0
        nodes.push world[beaconId]
        # nodeCache[lastId]?= id: lastId, name: beaconId, selected: beaconData.button, x: 0, y: 0

        #data.nodes.push nodeCache[lastId]
        #reverseIdMap[beaconId] = lastId
        #lastId += 1
    #      else
    #          node.butten= beconData.button

    for beaconId,beaconData of lastMsg
        for beaconSeenId,seenValue of beaconData.seen
            links.push source: world[beaconId], target: world[beaconSeenId], type: seenValue.strength

    graph = $("#graph")
    return  if graph.is(":hidden")
    graph.empty()
    # console.log JSON.stringify(data)
    # console.log data
    visualize "graph", graph.width(), graph.height(), data

    setTimeout drawGraph, 1000


setTimeout drawGraph, 100

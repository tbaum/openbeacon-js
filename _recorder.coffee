fs = require "fs"
dgram = require "dgram"
server = dgram.createSocket "udp4"

results = []

server.on "message", (msg, rinfo)->
    results.push ( msg.readUInt8 i for i in [0..msg.length - 1] )
    if results.length > 100
        fs.writeFileSync 'dump.json', JSON.stringify(results)
        process.exit()

server.bind 2342

console.log "server started"

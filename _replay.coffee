fs = require "fs"
results = JSON.parse fs.readFileSync("dump-longer.json")

dgram = require "dgram"
socket = dgram.createSocket "udp4"


sendLater = (buffer, next)->
    () ->
        console.log buffer
        socket.send buffer, 0, buffer.length, 2342, "127.0.0.1", ()->
            setTimeout next, 100


next = ()->
    process.exit()

for i in results.reverse()
    next = sendLater(new Buffer(i), next)

next()

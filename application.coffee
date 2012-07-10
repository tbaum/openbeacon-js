dgram = require "dgram"
server = dgram.createSocket "udp4"
fs = require "fs"
io = require 'socket.io'
express = require 'express'

logFile = 'log-' + Date.now() + '.txt'
logFile2 = 'log-' + Date.now() + '-raw.txt'

console.log "writing to " + logFile


process.on 'uncaughtException', (err) ->
    console.log "Type: " + err.type
    console.log "Message: " + err.message
    console.log "Arguments: " + err.arguments
    console.log err.stack


key = [0x00112233, 0x44556677, 0x8899aabb, 0xccddeeff]

xxtea_decode = (input, key) ->
    v = (input.readUInt32BE i for i in [0..input.length - 1] by 4)

    ## xxtea_decode
    DELTA = 0x9e3779b9
    sum = Math.floor(6 + 52 / v.length) * DELTA
    y = v[0]
    while sum
        e = sum >>> 2 & 3
        for p in [v.length - 1..0]
            z = v[ (p || v.length ) - 1 ]
            y = v[p] -= (z >>> 5 ^ y << 2) + (y >>> 3 ^ z << 4) ^ (sum ^ y) + (key[p & 3 ^ e] ^ z)
        sum -= DELTA

    result = new Buffer(v.length * 4)
    result.writeInt32BE(i & 0xffffffff, j * 4) for i,j in v
    result


crctab = [ 0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50A5, 0x60C6, 0x70E7, 0x8108, 0x9129, 0xA14A, 0xB16B, 0xC18C,
    0xD1AD, 0xE1CE, 0xF1EF, 0x1231, 0x0210, 0x3273, 0x2252, 0x52B5, 0x4294, 0x72F7, 0x62D6, 0x9339, 0x8318, 0xB37B,
    0xA35A, 0xD3BD, 0xC39C, 0xF3FF, 0xE3DE, 0x2462, 0x3443, 0x0420, 0x1401, 0x64E6, 0x74C7, 0x44A4, 0x5485, 0xA56A,
    0xB54B, 0x8528, 0x9509, 0xE5EE, 0xF5CF, 0xC5AC, 0xD58D, 0x3653, 0x2672, 0x1611, 0x0630, 0x76D7, 0x66F6, 0x5695,
    0x46B4, 0xB75B, 0xA77A, 0x9719, 0x8738, 0xF7DF, 0xE7FE, 0xD79D, 0xC7BC, 0x48C4, 0x58E5, 0x6886, 0x78A7, 0x0840,
    0x1861, 0x2802, 0x3823, 0xC9CC, 0xD9ED, 0xE98E, 0xF9AF, 0x8948, 0x9969, 0xA90A, 0xB92B, 0x5AF5, 0x4AD4, 0x7AB7,
    0x6A96, 0x1A71, 0x0A50, 0x3A33, 0x2A12, 0xDBFD, 0xCBDC, 0xFBBF, 0xEB9E, 0x9B79, 0x8B58, 0xBB3B, 0xAB1A, 0x6CA6,
    0x7C87, 0x4CE4, 0x5CC5, 0x2C22, 0x3C03, 0x0C60, 0x1C41, 0xEDAE, 0xFD8F, 0xCDEC, 0xDDCD, 0xAD2A, 0xBD0B, 0x8D68,
    0x9D49, 0x7E97, 0x6EB6, 0x5ED5, 0x4EF4, 0x3E13, 0x2E32, 0x1E51, 0x0E70, 0xFF9F, 0xEFBE, 0xDFDD, 0xCFFC, 0xBF1B,
    0xAF3A, 0x9F59, 0x8F78, 0x9188, 0x81A9, 0xB1CA, 0xA1EB, 0xD10C, 0xC12D, 0xF14E, 0xE16F, 0x1080, 0x00A1, 0x30C2,
    0x20E3, 0x5004, 0x4025, 0x7046, 0x6067, 0x83B9, 0x9398, 0xA3FB, 0xB3DA, 0xC33D, 0xD31C, 0xE37F, 0xF35E, 0x02B1,
    0x1290, 0x22F3, 0x32D2, 0x4235, 0x5214, 0x6277, 0x7256, 0xB5EA, 0xA5CB, 0x95A8, 0x8589, 0xF56E, 0xE54F, 0xD52C,
    0xC50D, 0x34E2, 0x24C3, 0x14A0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405, 0xA7DB, 0xB7FA, 0x8799, 0x97B8, 0xE75F,
    0xF77E, 0xC71D, 0xD73C, 0x26D3, 0x36F2, 0x0691, 0x16B0, 0x6657, 0x7676, 0x4615, 0x5634, 0xD94C, 0xC96D, 0xF90E,
    0xE92F, 0x99C8, 0x89E9, 0xB98A, 0xA9AB, 0x5844, 0x4865, 0x7806, 0x6827, 0x18C0, 0x08E1, 0x3882, 0x28A3, 0xCB7D,
    0xDB5C, 0xEB3F, 0xFB1E, 0x8BF9, 0x9BD8, 0xABBB, 0xBB9A, 0x4A75, 0x5A54, 0x6A37, 0x7A16, 0x0AF1, 0x1AD0, 0x2AB3,
    0x3A92, 0xFD2E, 0xED0F, 0xDD6C, 0xCD4D, 0xBDAA, 0xAD8B, 0x9DE8, 0x8DC9, 0x7C26, 0x6C07, 0x5C64, 0x4C45, 0x3CA2,
    0x2C83, 0x1CE0, 0x0CC1, 0xEF1F, 0xFF3E, 0xCF5D, 0xDF7C, 0xAF9B, 0xBFBA, 0x8FD9, 0x9FF8, 0x6E17, 0x7E36, 0x4E55,
    0x5E74, 0x2E93, 0x3EB2, 0x0ED1, 0x1EF0]

crc16 = (buffer, crc = 0xffff)->
    crc = crctab[ crc >> 8 ^ v & 0xFF ] ^ crc << 8 & 0xFFFF for v in buffer
    crc

icrc16 = (buffer)-> 0xffff ^ crc16 buffer


TBeaconLogSighting = (msg)->
    hdr: TBeaconNetworkHdr(msg)
    sequence: msg.readUInt32BE(8)
    timestamp: msg.readUInt32BE(12)
    log: TBeaconEnvelope(msg)


TBeaconNetworkHdr = (msg)->
    icrc16: msg.readUInt16BE(0)
    protocol: msg[2]
    interface: msg[3]
    reader_id: msg.readUInt16BE(4)
    size: msg.readUInt16BE(6)
    icrc16_ok: msg.readUInt16BE(0) == icrc16(msg[2..31])


TBeaconEnvelopeLog = (msg)->
    timestamp: msg.readUInt32BE(16)
    ip: msg.readUInt32BE(20).toString(16)
    env: TBeaconEnvelope(msg)


TBeaconProx = (dMsg)->
    result =
    oid_prox: (dMsg.readUInt16BE(i) for i in [4..11] by 2)
    seq: dMsg.readUInt16BE(12)
    prox: {}

    for i in result.oid_prox
        #cnt = i >> 12 & 0x3
        #sgn = i >> 14 & 0x3

        result.prox[i & 0x0fff] = i >> 14 & 0x3 if i

    return result

TBeaconTracker = (dMsg)->
    strength: dMsg[4]
    oid_last_seen: dMsg.readUInt16BE(5)
    powerup_count: dMsg.readUInt16BE(7)
    reserved: dMsg[9]
    seq: dMsg.readUInt32BE(10)

TBeaconTrackerExt = (dMsg)->
    strength: dMsg[4]
    oid_last_seen: dMsg.readUInt16BE(5)
    time: dMsg.readUInt16BE(7)
    battery: dMsg[9]
    seq: dMsg.readUInt32BE(10)

TBeaconReaderCommand = (dMsg)->
    opcode: dMsg[4]
    res: dMsg[5]
    data: [ dMsg.readUInt32BE(6), dMsg.readUInt32BE(10)]

TBeaconReaderAnnounce = (dMsg)->
    opcode: dMsg[4]
    res: dMsg[5]
    uptime: dMsg.readUInt32BE(6)
    ip: dMsg.readUInt32BE(10).toString(16)

TBeaconEnvelope = (msg)->
    decrypted = xxtea_decode msg[16..31], key
    icrc_ok = decrypted.readUInt16BE(14) == crc16(decrypted[0..13])

    # decrypted = decrypt(msg.readUInt32BE i for i in [16..28] by 4)

    r = switch decrypted[0]
        when 69
            type: "TBeaconProx"
            data: TBeaconProx decrypted
        when 70
            type: "TBeaconProxExt"
            data: TBeaconProx decrypted
        when 24
            type: "TBeaconTracker"
            data: TBeaconTracker decrypted
            button: if decrypted[3] && 2 then true else false
        when 26
            type: "TBeaconTrackerExt"
            data: TBeaconTracker decrypted
        else
            type: "unkown " + decrypted[0]
    # TBeaconReaderCommand: JSON.stringify TBeaconReaderCommand(decrypted)
    # TBeaconReaderAnnounce: JSON.stringify TBeaconReaderAnnounce(decrypted)

    r['raw'] = decrypted.inspect()

    r['proto'] = decrypted[0]
    r['oid'] = decrypted.readUInt16BE(1)
    r['flags'] = decrypted[3]

    r['icrc'] = decrypted.readUInt16BE(14)
    r['icrc_ok'] = icrc_ok
    r


app = express.createServer()
io = io.listen(app)

app.listen(8080)

app.configure ()->
    app.set('view engine', 'jade')
    app.use(express.static(__dirname + '/public'))
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))

app.get '/', (req, res) ->
    res.redirect("/index.html")

consumer = {}
lastId = 0

io.set('log level', 1)
io.sockets.on 'connection', (socket) ->
    socketId = lastId++
    consumer[socketId] = -> socket
    socket.on 'disconnect', -> delete consumer[socketId]


writeLogText = (logFile, text)->
    log = fs.createWriteStream(logFile, {'flags': 'a'})
    log.write(text)
    log.end()

writeLog = (logFile, data)->
    x = {}
    x[Date.now()] = data
    writeLogText logFile, JSON.stringify(x) + ",\n"

writeLogText logFile, "{\n"
writeLogText logFile2, "{\n"

status = {}

server.on "message", (msg, rinfo)->
    writeLog logFile2, ( msg.readUInt8 i for i in [0..msg.length - 1])
    data = TBeaconLogSighting(msg)

    unless data.hdr.icrc16_ok || data.log.icrc_ok
        console.log "INVALID " + msg.inspect()
        return

    beaconInfo = ->
        seen: {}, strength: {}, button: false

    oid = data.log.oid

    if (data.log.type == 'TBeaconTracker')
        status[oid]?= beaconInfo()
        status[oid]['strength']['t' + data.hdr.interface] = data.log.data.strength
        status[oid]['button'] = data.log.button
    else if (data.log.type == 'TBeaconProxExt')
        status[oid]?= beaconInfo()
        for b,v of data.log.data.prox
            status[oid]['seen'][b] = {seen: Date.now(), strength: v}
    else
        console.log [data.log.type , JSON.stringify(data.log.raw) , data.hdr.interface , data.log.oid,
            data.log.flags.toString(16), JSON.stringify(data.log.data) ].join(" ")

    try
        delete data['hdr']['icrc16']
        delete data['hdr']['protocol']
        delete data['hdr']['icrc16_ok']
        delete data['log']['icrc']
        delete data['log']['icrc_ok']
    catch x

    writeLog logFile, data

    for p,i of status[oid]['seen']
        delete status[oid]['seen'][p] if i.seen < Date.now() - 5000

    for socketId,socket of consumer
        socket().emit('message', status)

server.bind 2342


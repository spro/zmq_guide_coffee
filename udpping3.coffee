crypto = require 'crypto'
udplib = require './udplib'

HEADER = 'ZRE'
VERSION = 1
UUID = crypto.randomBytes 16
PORT = 5893

build_beacon = ->
    beacon = new Buffer 22
    beacon.write HEADER, 0
    beacon.writeUInt8 VERSION, 3
    UUID.copy beacon, 4
    beacon.writeUInt16LE PORT, 20
    return beacon
BEACON = build_beacon()

read_beacon = (beacon) ->
    return null if beacon.length != 22
    return null if beacon.asciiSlice(0, 3) != 'ZRE'
    beacon_data =
        version: beacon.readUInt8 3
        uuid: beacon.slice 4, 20
        port: beacon.readUInt16LE 20
    return beacon_data

PEER_TIMEOUT = 5000

class PeerAgent
    constructor: ->
        @peers = {}
        @udp = new udplib.UDPBroadcaster()
        @udp.recv = => @recv_beacon arguments...
        setInterval (=> @send_beacon()), 1000
        setInterval (=> @reap_peers()), 1000
        
    recv_beacon: (beacon, sender) ->
        now = new Date().getTime()
        #return if sender.address == @udp.address
        beacon_data = read_beacon beacon
        return if !beacon_data?
        uuid = beacon_data.uuid.toString 'hex'
        if !@peers[uuid]?
            console.log "JOINED #{ uuid }"
        @peers[uuid] = now

    send_beacon: ->
        @udp.send BEACON

    reap_peers: ->
        now = new Date().getTime()
        for uuid, last_seen of @peers
            if now - last_seen > PEER_TIMEOUT
                console.log "LEFT #{ uuid }"
                delete @peers[uuid]

console.log "Starting up #{ UUID.toString 'hex' } at #{ udplib.local_ip() }"
new PeerAgent()


crypto = require 'crypto'
udplib = require './udplib'
zmq = require 'zmq'
util = require 'util'

HEADER = 'ZRE'
VERSION = 1
UUID = crypto.randomBytes 16
PORT = 5000 + Math.floor(Math.random()*5000)

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
    #console.log "1:(#{ beacon[20] }) 2: (#{ beacon[21] })"
    beacon_data =
        version: beacon.readUInt8 3
        uuid: beacon.slice 4, 20
        port: beacon.readUInt16LE 20
    return beacon_data

PEER_TIMEOUT = 5000

USERNAME = process.argv[2]

class PeerAgent
    constructor: ->
        @udp = new udplib.UDPBroadcaster()
        @udp.recv = => @recv_beacon arguments...
        @incoming = zmq.socket 'router'
        @incoming.bind "tcp://*:#{ PORT }"
        @incoming.on 'message', (=> @recv_message arguments...)
        @peer_last_seen = {}
        @peer_outgoing = {}
        @peer_usernames = {}
        process.stdin.resume()
        process.stdin.on 'data', (data) =>
            @broadcast data.toString().trim()
        setInterval (=> @send_beacon()), 1000
        setInterval (=> @reap_peers()), 1000
        
    recv_beacon: (beacon, sender) ->
        now = new Date().getTime()
        beacon_data = read_beacon beacon
        #console.log util.inspect beacon_data
        return if !beacon_data?
        uuid = beacon_data.uuid.toString 'hex'
        return if uuid == UUID.toString 'hex'
        if !@peer_last_seen[uuid]?
            console.log "JOINED #{ uuid } (#{ sender.address }:#{ beacon_data.port })"
            outgoing = zmq.socket 'dealer'
            outgoing.identity = UUID.toString 'hex'
            outgoing.connect "tcp://#{ sender.address }:#{ beacon_data.port }"
            outgoing.send JSON.stringify
                type: 'hello'
                username: USERNAME
            @peer_outgoing[uuid] = outgoing
        @peer_last_seen[uuid] = now

    broadcast: (message) ->
        for uuid, outgoing of @peer_outgoing
            outgoing.send JSON.stringify
                type: 'message'
                body: message

    send_beacon: ->
        @udp.send BEACON

    recv_message: (sender, message_data) ->
        #console.log "MESSAGE #{ sender.toString() } `#{ message.toString() }`"
        message = JSON.parse message_data.toString()
        if message.type == 'message'
            if username = @peer_usernames[sender]
                sender = username
            console.log "#{ sender.toString() }: #{ message.body }"
        else if message.type == 'hello'
            console.log "#{ sender.toString() } -> #{ message.username }"
            @peer_usernames[sender] = message.username

    reap_peers: ->
        now = new Date().getTime()
        for uuid, last_seen of @peer_last_seen
            if now - last_seen > PEER_TIMEOUT
                console.log "LEFT #{ uuid }"
                @peer_outgoing[uuid].close()
                delete @peer_outgoing[uuid]
                delete @peer_last_seen[uuid]

console.log "Starting up #{ UUID.toString 'hex' } at #{ udplib.local_ip() }:#{ PORT }"
new PeerAgent()


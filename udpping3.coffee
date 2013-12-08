udplib = require './udplib'

PEER_TIMEOUT = 5000

class PeerAgent
    constructor: ->
        @peers = {}
        @udp = new udplib.UDPBroadcaster()
        @udp.recv = => @recv_beacon arguments...
        setInterval (=> @send_beacon()), 1000
        setInterval (=> @reap_peers()), 1000
        
    recv_beacon: (message, sender) ->
        now = new Date().getTime()
        return if sender.address == @udp.address
        uuid = sender.address.toString()
        if !@peers[uuid]?
            console.log "JOINED #{ uuid }"
        @peers[uuid] = now

    send_beacon: ->
        @udp.send '!'

    reap_peers: ->
        now = new Date().getTime()
        for uuid, last_seen of @peers
            if now - last_seen > PEER_TIMEOUT
                console.log "LEFT #{ uuid }"
                delete @peers[uuid]

console.log 'Starting up at ' + udplib.local_ip()
new PeerAgent()


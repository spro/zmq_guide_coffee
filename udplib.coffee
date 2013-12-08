dgram = require 'dgram'
os = require 'os'

PING_PORT = 5670

local_ip = ->
    interfaces = os.networkInterfaces()
    for name, addresses of interfaces
        for address in addresses
            continue if address.family != 'IPv4'
            continue if address.address == '127.0.0.1'
            return address.address

class UDPBroadcaster
    constructor: (@port, @address, @broadcast='255.255.255.255') ->
        if !@address?
            @address = local_ip()
        socket = dgram.createSocket 'udp4'
        socket.bind PING_PORT, =>
            socket.setBroadcast true
        socket.on 'message', => @recv arguments...
        @socket = socket

    send: (message) ->
        message = new Buffer message if typeof message == 'string'
        @socket.send message, 0, message.length, PING_PORT, @broadcast

    recv: (message, sender) ->
        return if sender.address == @address
        console.log "Found peer: #{ sender.address }:#{ sender.port }"

module.exports =
    local_ip: local_ip
    UDPBroadcaster: UDPBroadcaster

dgram = require 'dgram'

PING_PORT = 9999

sock = dgram.createSocket('udp4')
sock.bind PING_PORT, ->
    sock.setBroadcast true

broadcastNew = ->
    message = new Buffer '!'
    sock.send message, 0, message.length, PING_PORT, '255.255.255.255'

sock.on 'message', (message, sender) ->
    console.log "Found peer: #{ sender.address }:#{ sender.port }"

setInterval broadcastNew, 1000


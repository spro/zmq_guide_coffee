dgram = require 'dgram'

PING_PORT = 9999

sock = dgram.createSocket('udp4')
sock.bind PING_PORT, '', ->
    sock.setBroadcast true

i = 5555
bip = '192.168.42.255'
broadcastNew = ->
    message = new Buffer (i++).toString()
    sock.send message, 0, message.length, PING_PORT, bip

sock.on 'message', (message, sender) ->
    console.log message.toString() + ' from ' + sender.address + ':' + sender.port

setInterval broadcastNew, 1000


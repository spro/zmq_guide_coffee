udplib = require './udplib'

udp = new udplib.UDPBroadcaster
setInterval (-> udp.send '!'), 1000

console.log 'Starting up at ' + udplib.local_ip()

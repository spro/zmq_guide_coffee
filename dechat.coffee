zmq = require 'zmq'

listen = (masked) ->
    listener = zmq.socket 'sub'
    for n in [80..90]
        console.log "connecting to #{ masked }.#{ n }"
        listener.connect "tcp://#{ masked }.#{ n }:9000"
    listener.subscribe ''

    listener.on 'message', (data) ->
        message = data.toString()
        console.log message

main = (broadcast = false) ->
    ip = process.argv[2]
    user = process.argv[3]
    masked = ip.split('.')[..2].join('.')
    listen masked

    if broadcast
        broadcaster = zmq.socket 'pub'
        broadcaster.bind "tcp://#{ ip }:9000"

        process.stdin.resume()
        process.stdin.on 'data', (data) ->
            broadcaster.send user + ': ' + data.toString().trim()

main(true)

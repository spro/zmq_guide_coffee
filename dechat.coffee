zmq = require 'zmq'

listen = (masked) ->
    listener = zmq.socket 'sub'
    for n in [1..20]
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

        setTimeout ->
            broadcaster.send 'testing ' + user
            broadcaster.close()
        , 500

main(true)

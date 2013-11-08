zmq = require 'zmq'

LRU_READY = 'ready'

BACKEND = 'tcp://0.0.0.0:5556'

random_identity = (len=5)->
    Math.random().toString(36).slice(2, len+2)

# Connect worker socket
worker = zmq.socket 'req'
worker.identity = random_identity()
worker.connect BACKEND

# Send readiness
console.log "[info] #{ worker.identity } ready"
worker.send LRU_READY

cycles = 0

# When the worker receives a message
worker.on 'message', ->
    # Get message as array
    message = Array::slice.call arguments
    console.log "[info] #{ worker.identity } received [#{ message }]"

    # After 3 messages start messing up ~20% of the time
    if cycles++ > 3
        # Randomly lag
        if Math.floor(Math.random()*10) == 0
            console.log "[debug] #{ worker.identity } simulating a lag"
            wait = 1000
        # Or randomly crash
        else if Math.floor(Math.random()*10) == 0
            console.log "[debug] #{ worker.identity } simulating a crash"
            worker.close()
            process.exit()

    # Send the same message back after 0-2s
    send_reply = ->
        console.log "[info] #{ worker.identity } sending [#{ message }]"
        worker.send message
    setTimeout send_reply, Math.random()*2000

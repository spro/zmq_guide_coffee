zmq = require 'zmq'

LRU_READY = 'ready'

FRONTEND = 'tcp://0.0.0.0:5555'
BACKEND = 'tcp://0.0.0.0:5556'

# Bind frontend and backend sockets
frontend = zmq.socket 'router'
frontend.bindSync FRONTEND
backend = zmq.socket 'router'
backend.bindSync BACKEND

# The Node.js ZMQ library doesn't have a blocking receive, so to
# match the behavior of the polling examples this queues both available
# workers and pending requests
workers = []
pending = []

# Handle requests from clients on the frontend
frontend.on 'message', ->
    # Get message as array
    message = Array::slice.call arguments
    console.log "[info] frontend received [#{ message }]"
    # Add to pending queue
    pending.push message

# "Polling" until a worker is available
flush_pending = ->
    if workers.length > 0 and pending.length > 0
        # Send oldest request to oldest worker
        request = pending.shift()
        worker_addr = workers.shift()
        # Insert empty frame to satisfy REQ socket
        message = [worker_addr, ''].concat request
        console.log "[info] backend sending [#{ message }]"
        backend.send message
setInterval flush_pending, 10

# Handle replies from workers on the backend
backend.on 'message', ->
    # Get message as array
    message = Array::slice.call arguments
    console.log "[info] backend received [#{ message }]"
    worker_addr = message[0]
    workers.push worker_addr
    reply = message.slice 2
    # If it isn't a worker saying hello
    if String(reply[0]) != LRU_READY
        console.log "[info] frontend sending [#{ reply }]"
        frontend.send reply


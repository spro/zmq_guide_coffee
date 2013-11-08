zmq = require 'zmq'

N_CLIENTS = 20
N_WORKERS = 3

FRONTEND = 'tcp://0.0.0.0:6666'
BACKEND = 'tcp://0.0.0.0:7777'

frontend = zmq.socket 'router'
frontend.bind FRONTEND
backend = zmq.socket 'router'
backend.bind BACKEND

create_worker = (n) ->
    worker = zmq.socket 'req'
    worker.identity = "worker#{ n }"
    worker.connect BACKEND

    worker.on 'message', ->
        # Get message as array
        message = Array::slice.call arguments
        console.log "[info] #{ worker.identity } received [#{ message }]"
        
        # Parse message
        client_addr = message[0]
        request = message[2]

        # Send reply after some time
        send_reply = ->
            # Add empty frame to satisfy REQ socket
            worker.send [client_addr, '', 'ok']
        work_time = 500+500*Math.random()
        setTimeout send_reply, work_time

    worker.send 'ready'

create_client = (n) ->
    client = zmq.socket 'req'
    client.identity = "client#{ n }"
    client.connect FRONTEND

    client.send 'hello'
    client.on 'message', ->
        # Get message as array
        message = Array::slice.call arguments
        console.log "[info] #{ client.identity } received [#{ message }]"

# The Node.js ZMQ library doesn't have a blocking receive, so to
# match the behavior of the polling examples this uses arrays for both
# available workers and pending requests.
workers = []
pending = []

# Frontend receives from clients
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

# Backend receives from workers
backend.on 'message', ->
    # Get message as array
    message = Array::slice.call arguments
    console.log "[info] backend received [#{ message }]"
    
    # Add the worker back to the queue
    worker_addr = arguments[0]
    workers.push worker_addr

    if arguments[2] != 'ready'
        # Forward reply to client
        client_addr = arguments[2]
        reply = arguments[4]
        response = [client_addr, '', reply]
        console.log "[info] frontend sending [#{ response }]"
        frontend.send response

for n in [0..N_CLIENTS-1]
    create_client n

for n in [0..N_WORKERS-1]
    create_worker n


zmq = require 'zmq'

N_WORKERS = 10
CLIENT_BINDING = 'tcp://0.0.0.0:6666'

finished_workers = 0

create_worker = (n) ->
    worker = zmq.socket 'req'
    worker.identity = "worker#{ n }"
    completed_tasks = 0

    send_ready = ->
        worker.send 'ready'

    # When the worker receives a message
    worker.on 'message', (message) ->
        # Check if this is an END and shut down
        if String(message) is 'END'
            console.log "[info] #{ worker.identity } finished #{ completed_tasks } tasks"
            worker.close()
            # Keep track of finished workers so we can exit
            if ++finished_workers == N_WORKERS
                process.exit()
        # Or get ready for another task
        else
            completed_tasks++
            work_time = Math.random()*(100 + 100*n)
            setTimeout send_ready, work_time

    worker.connect CLIENT_BINDING
    send_ready()

# Create all N workers
for n in [0..N_WORKERS]
    create_worker n

client = zmq.socket 'router'

sent_jobs = 0

# When the client receives a reply
client.on 'message', ->
    message = Array::slice.call arguments

    # Parse the message
    worker_identity = message[0]
    reply = message[2]

    console.log "[info] client received #{ reply }"

    # Check if we've reached our job limit
    if sent_jobs == N_WORKERS*10
        client.send [worker_identity, '', 'END']

    # Otherwise send the next job
    else
        client.send [worker_identity, '', 'Here is some work']
        sent_jobs++

client.bindSync CLIENT_BINDING


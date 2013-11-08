zmq = require 'zmq'

SERVER = 'tcp://0.0.0.0:5555'

server = zmq.socket 'rep'
server.bindSync SERVER

cycles = 0

# When the server receives a message
server.on 'message', ->
    # Get message as array
    message = Array::slice.call arguments
    console.log "[info] server received [#{ message }]"

    # Default "work time" is 100ms
    wait = 100
    
    # After 3 messages start messing up ~20% of the time
    if cycles++ > 3
        # Randomly lag
        if Math.floor(Math.random()*10) == 0
            console.log "[debug] server simulating a lag"
            wait = 1000
        # Or randomly crash
        else if Math.floor(Math.random()*10) == 0
            console.log "[debug] server simulating a crash"
            server.close()
            process.exit()

    # Send reply after working
    send_reply = ->
        console.log "[info] server sending [#{ message }]"
        server.send message
    setTimeout send_reply, wait


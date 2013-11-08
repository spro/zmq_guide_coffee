zmq = require 'zmq'

REQUEST_TIMEOUT = 2500
REQUEST_RETRIES = 3
SERVER_ENDPOINT = 'tcp://localhost:5555'

sequence = 0
retries_left = REQUEST_RETRIES
response_timeout = null

random_identity = (len=5)->
    Math.random().toString(36).slice(2, len+2)

# Client within a closure to allow proper re-socketing
create_client = ->
    client = zmq.socket 'req'
    client.identity = random_identity()
    client.connect SERVER_ENDPOINT

    # Sending a request to the server
    send_message = ->
        #request = String sequence
        request = sequence
        console.log "[info] #{ client.identity } sending #{ request }"
        client.send request
        
        # Set up callback for timing out response
        response_timeout = setTimeout ->
            if retries_left
                # Create new connection and try again
                console.log "[warning] #{ client.identity } retrying... (#{ REQUEST_RETRIES-retries_left+1 }/#{ REQUEST_RETRIES })"
                client.setsockopt zmq.ZMQ_LINGER, 0
                client.close()
                retries_left--
                create_client()
            else
                console.log "[error] #{ client.identity } abandoning."
                process.exit()
        , REQUEST_TIMEOUT

    # Receiving a reply from the server
    client.on 'message', (message) ->
        # Clear response timeout
        clearTimeout response_timeout
        
        # Check that reply was proper
        if Number(message) == sequence
            # All is well, increment the sequence and clear retries
            console.log "[info] #{ client.identity } received OK (#{ message })"
            retries_left = REQUEST_RETRIES
            sequence++
        else
            console.log "[warning] #{ client.identity } received malformed response: #{ message }"

        # Send another message now
        send_message()

    # Kick it off
    send_message()

create_client()

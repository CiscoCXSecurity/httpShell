##httpShell - obfuscated reverse shell that looks like HTTP
**Usage: httpshell.coffee [options] [command]**

##Commands:
**server** 
Start a fake HTTP server. This is the end sending commands to the client.
    
**client** 
Start a fake HTTP client. This is the end that receives and runs the command from the server.

##Options:
-h, --help                      output usage information  
-V, --version                   output the version number  
-a --host [address]             Server IP address or domain name \[127.0.0.1\](Client/Server)  
-b --port [port]                Server listening port \[80\] (Client/Server)  
-c --delay [delay-ms]           Miliseconds to delay between requests \[1000\](Client only)  
-e --secret [shared]            Shared secret to use for aes192 encryption \[supersecret\](Client/Server)  
-f --dict <filename>            Path to the dictionary file to use for both client and server (Client/Server)  
-g --clientdict <filename>      Path to the dictionary to use for client communication (Client/Server)  
-h --serverdict <filename>      Path to the dictionary to use for server communication (Client/Server)  
-i --clienttemplate <filename>  Path to the template file to use for client communication (Client/Server)  
-j --servertemplate <filename>  Path to the template file to use for server communication (Client/Server)  
-k --quiet                      Run quietly. (Client only)  

##Description:
This is an obfuscated client/server reverse shell. 

If running as client, this application will act like an HTTP client (web browser),
making HTTP requests to the server. These requests will be encoded using the dictionary
files specified by the user. These requests will contain the results of the bash commands
send in the HTTP responses.

If running as the server, this application will act like an HTTP server, answering HTTP requests
sent by the client or by actual web browsers. The HTTP responses will bash commands encoded
into the dictionary file specified by the user.

##Author:
**Written by Ben Toews (mastahyeti)**

##Copyright:
Copyright © 2011 Neohapsis Inc. License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.  There is NO WARRANTY, to the extent permitted by law.

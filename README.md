##httpShell - obfuscated reverse shell that looks like HTTP
**Usage: httpshell.coffee [options] [command]**

##Commands:
**server** 
Start a fake HTTP server. This is the end sending commands to the client.
    
**client** 
Start a fake HTTP client. This is the end that receives and runs the command from the server.

##Options:
###-h, --help
output usage information  
###-V, --version
output the version number  
###-a --host \[address\]
This is the address of the server. If this is specified on the server, it will indicate what address to listen on. If this is specified on the client it will tell it what address to conncet to the server on. This defaults to 127.0.0.1. If you are not running the server and client on the same machine (testing) you should specify this at least on the client.
###-b --port \[port\]
This specified what TCP port for the server to listen on and what port for the client to connect to the server on. If it is set on either, it should be set on both. This defaults to TCP port 80.
###-c --delay \[delay-ms\]
When the client (the one running the shell) receives data from the shell's stdout if sends a request to the server. Additionally, the client must periodically check in with the server to see if there are new commands to run. Using a lower number here will cause the client to check for commands more frequently which reduce the delay of running a command. This will also cause more network traffic though which will increase the chances of detection. This defaults to 1000 ms.
###-e --secret \[shared\]
Communications between the client and server is encrypted AES192. This option specifies the shared secret to use for this encryption. It should be noted that this encryption is not cryptographically secure and is vulnerable to replay attacks. This is due to the fact that each request/response is encrypted seperately without a nonce or other variation. This option should be set to improve the security of this application. The shared secret defaults to 'supersecret'.
###-f --dict <filename>
This application encodes traffic into the words specified in this dictionary files. There are seperate dictionaries used for data sent by the client and by the server. This option specifies a dictionary file to be used by both. This file is parsed, treating each line as a seperate dictionary element. It is advisable that different dictionaries be used by both client and server. It is necessary that both the client and server have the same dictionary options specified. This works as follows: A base is defined as the number of different strings in the dictionary (the number of lines). The strings to be sent by client or server are converted into arrays of integers of the base derived from the dictionary (the number of dictionary elements). These integers then correspond to the elements in the dictionary which are concatenated together. The following is an example:  

Dictionary: \[hello,world\]
Input String: 'A' = 0x41 = 0b1000001
Input Base: 256 
Output base: 2 (2 elements in the dictionary)
Output Integer Array (base 2): 1,0,0,0,0,0,1
Output String: 'world hello hello hello hello hello world'

###-g --clientdict <filename>
Path to the dictionary to use for client communication. See above for a better description of what this does. This defaults to \[hello,world\]
###-h --serverdict <filename>
Path to the dictionary to use for server communication. See above for a better description of what this does. This defaults to \[hello,world\] 
###-i --clienttemplate <filename>
Path to the template file to use for client communication. This only needs to be set on the client. In addition to encoding transmission data into dictionaries, the output is placed into a template for further obfuscation. In the template one should specify where to put the data. The string '##$$##' is replaced with the specified data. If the output string is encoded into the dictionary as 'world hello hello hello hello hello world' and the template is 'foo ##$$## bar' then the overall output will be 'foo world hello hello hello hello hello world bar'. This, for example, allows you to embed data that has been encoded to look like HTML into a larger HTML template to provide context and legitimacy. 
###-j --servertemplate <filename>
Path to the template file to use for server communication. This only needs to be set on the server. In addition to encoding transmission data into dictionaries, the output is placed into a template for further obfuscation. In the template one should specify where to put the data. The string '##$$##' is replaced with the specified data. If the output string is encoded into the dictionary as 'world hello hello hello hello hello world' and the template is 'foo ##$$## bar' then the overall output will be 'foo world hello hello hello hello hello world bar'. This, for example, allows you to embed data that has been encoded to look like HTML into a larger HTML template to provide context and legitimacy.  
###-k --quiet
This doesn't display and output (redefines stdout). This obviously should only ever be set on the client.

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

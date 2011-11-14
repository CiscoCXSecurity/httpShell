crypto = require 'crypto'

'''
A class to handle encoding/decoding strings into a dictionary.
in other words: take a dictionary of x strings and a string
you would like to encode. You convert the string into an array
of integers of base x and then build an output string from the 
dictionary elements corresponding to these indexes. 
'''
class exports.transcoder
	constructor: (@dict,@password) ->
		#base of the input string. We assume UTF8 for now. 
		@stringbase = 256
		#Output base will be determined by num of elts in dict
		@xbase = @dict.length
		#algorish specifies what to use for crypto
		@algorithm = 'aes192'
		
	encode: (string) ->
		#encode the string
		@a2s(@string_to_basex(@encrypt(string)))
	
	decode: (string) ->
		#decode the string
		@decrypt(@basex_to_string(@s2a(string)))

	a2s: (array) ->
		#Convert array of dict indexes to a string
		str = (@dict[i] for i in array).join(' ')

	s2a: (string) ->
		#Convert string to array of dictionary indexes
		tmpout = []
		out = []
		for i in [0...@dict.length]
			start = 0
			while (index = string.indexOf @dict[i],start) >= 0
				tmpout[index] = i
				start += @dict[i].length
		for elt in tmpout
			out.push(elt) if elt?
		out

	string_to_basex: (string) ->
		#Convert a string to an array of basex integers
		input = (string.charCodeAt(i) for i in [0...string.length])
		output = @convert_base input,@stringbase,@xbase
		output

	basex_to_string: (input) ->
		#Convert an array of basex integers to a string
		tmpout = @convert_base input,@xbase,@stringbase
		output = ""
		output += String.fromCharCode(e) for e in tmpout
		output

	convert_base: (input,input_base,output_base) ->
		#take an array of ints in base input_base and convert it to an
		#array of ints in base output_base
		input_len = input.length
		output_len = Math.ceil(input_len * (Math.log(input_base)/Math.log(output_base)))
		output = []
		output[i] = 0 for i in [0...output_len]
		for i in [0...input_len]
			n = input[i]
			o=0
			for j in [(output_len-1)..0]
				m = (output[j]*input_base)+o
				output[j] = m % output_base
				o = Math.floor(m / output_base)
			o = n
			for j in [(output_len-1)..0]
				if o == 0
					break
				m = output[j] + o
				output[j] = m % output_base
				o = Math.floor(m / output_base)
		#remove leading 0
		output = output[((output[0]==0)*1)...output.length]
		output

	encrypt: (plaintext) ->
		c = crypto.createCipher @algorithm, @password
		ciphertext = ''
		ciphertext += c.update plaintext, 'utf8', 'base64'
		ciphertext += c.final 'base64'		
		ciphertext

	decrypt: (ciphertext) ->
		d = crypto.createDecipher @algorithm, @password
		plaintext = ''
		plaintext += d.update ciphertext, 'base64', 'utf8'
		plaintext += d.final 'utf8'
		plaintext

class foo
	constructor: ->
		hello = 'world'
		process.stdin.resume()
		process.stdin.on 'data', ->
			console.log hello
		hello = "goodbye"
f = new foo
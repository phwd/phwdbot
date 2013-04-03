# Show current Facebook API status and calls
# 
# facebook api status - Returns the current Facebook status for the Platform
# facebook inspect <object> - Returns the id and name of the object
#


class Docs
	constructor: (@robot) ->
		@cache = []
		@robot.brain.on 'loaded', =>
			if @robot.brain.data.docs
				@cache = @robot.brain.data.docs
	add: (docTitle, docString) ->
		doc = {title: docTitle, doc: docString}
		@cache.push doc
		@robot.brain.data.docs = @cache
		doc
	showByTitle: (title) ->
		index = @cache.map((n) -> n.title).indexOf(title)
		if (index >= 0)
			sdoc = @cache[index]
			doc = {title: sdoc.title, doc: sdoc.doc}
			doc
	all: -> @cache
	deleteByTitle: (title) ->
		index = @cache.map((n) -> n.title).indexOf(title)
		doc = @cache.splice(index, 1)[0]
		@robot.brain.data.docs = @cache
		doc

module.exports = (robot) ->
	docs = new Docs robot

	robot.respond /facebook api status/i, (msg) ->
		msg.http("https://www.facebook.com/feeds/api_status.php")
            .header("User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.43 Safari/537.31")
			.get() (err, res, body) ->
				try
					json = JSON.parse(body)
					msg.send "Push: #{json['push']['status']} - " +
						           			   "#{json['push']['updated']} " +
								   			   "@ #{json['push']['id']} \n" +
							 "Current Status: #{json['current']['subject']}"
				catch error
					msg.send "The cake is a lie, I have no clue what's wrong with Facebook."

	
	robot.respond /facebook inspect (.*)/i, (msg) ->
		object = msg.match[1]
		msg.http("https://graph.facebook.com/#{object}")
			.headers(Accept: "application/json")
			.get() (err, res, body) ->
				if body == "false"
					msg.send "Not found"
					return
				object = JSON.parse(body)
				if object.error
					msg.send "#{object.error.type} Error: (#{object.error.code}) #{object.error.message}"
					return
				result = "id: #{object.id}, name: #{object.name}"

				msg.send result



	robot.respond /facebook stock/i, (msg) ->
		msg.http('http://finance.google.com/finance/info?client=ig&q=FB')
			.headers(Accept: "application/json")
			.get() (err, res, body) ->
				quote = JSON.parse(body.substr(3))
				msg.send "NASDAQ:FB #{quote[0].l} #{quote[0].c} (#{quote[0].cp})"

	robot.respond /(doc add|add doc) (.*): (.*)/i, (msg) ->
		if robot.Auth.hasRole('phwd','control')
			doc = docs.add(msg.match[2],msg.match[3])
			msg.send "Doc added"

#	robot.respond /(doc list|list docs)/i, (msg) ->
#		if docs.all().length > 0
#			response =  ""
#			for doc,title in docs.all()
#				response += "#{doc.title} \n"
#			msg.send response
#		else
#			msg.send "There are no docs"

	robot.hear /^[.] (.*)/i, (msg) ->
		docTitle = msg.match[1]
		doc = docs.showByTitle docTitle
		if doc
			msg.send "#{doc.doc}"		

	robot.respond /(doc delete|delete doc) (.*)/i, (msg) ->
		if robot.Auth.hasRole('phwd','admin')
			docTitle = msg.match[2]
			doc = docs.deleteByTitle docTitle
			msg.send "Doc deleted: #{doc.title}"


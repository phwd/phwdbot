# Show current Facebook API status and calls
# 
# facebook api status - Returns the current Facebook status for the Platform
# facebook inspect <object> - Returns the id and name of the object
#

module.exports = (robot) ->

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


require 'facebook/messenger'
require 'httparty' # you should require this one
require 'json' # and that one
include Facebook::Messenger
# NOTE: ENV variables should be set directly in terminal for testing on localhost

# Subcribe bot to your page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

API_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address='

Bot.on :message do |message|
  puts "Received '#{message.inspect}' from #{message.sender}" # debug purposes
  case message.text
  when /coord/i, /gps/i # We use regexp to react to any command that will have this combinations of symbols
    message.reply("Give me the address!")
    # process_coordinates # we call a separate function that will handle GPS look-up and talk to you back
  end
end

def process_coordinates
  Bot.on :message do |message|
    puts "Received '#{message.inspect}' from #{message.sender}" # debug purposes
    parsed_response = get_parsed_response(API_URL, message.text) # talk to Google API
    unless parsed_response # The input was unintelligible
      message.reply(text: "I did not quite get that. Bye!")
      return # bye bye
    end
    message.type # trick user into thinking we type something with our fingers, HA HA HA
    coord = extract_coordinates(parsed_response) # we have a separate method for that
    message.reply(text: "Latitude: #{coord['lat']}, Longitude: #{coord['lng']}. Bye!")
  end
end

def get_parsed_response(url, query)
  # Use HTTParty gem to make a get request
  response = HTTParty.get(url + query)
  # Parse the resulting JSON so it's now a Ruby Hash
  parsed = JSON.parse(response.body)
  # Return nil if we got no results from the API.
  parsed['status'] != 'ZERO_RESULTS' ? parsed : nil
end

# Look inside the hash to find coordinates
def extract_coordinates(parsed)
  parsed['results'].first['geometry']['location']
end

require 'facebook/messenger'
require 'httparty'
require 'json'
include Facebook::Messenger


# NOTE: ENV variables should be set directly in terminal for testing on localhost

# Subcribe bot to the page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

def ask_city
  Bot.on :message do |message|
    case message.text
    when /coordinates/i
      message.reply(text: "Which city?")
      process_coordinates
    end
  end
end

#https://maps.googleapis.com/maps/api/geocode/json?address=
# TODO: write custom classes with HTTParty mixins"
def process_coordinates
  Bot.on :message do |message|
    geocoder_response = HTTParty.get("https://maps.googleapis.com/maps/api/geocode/json?address=#{message.text}")
    parsed = JSON.parse(geocoder_response.body)
    coord = parsed['results'].first['geometry']['location']
    message.reply(text: "#{coord['lat']} : #{coord['lng']}")
    ask_city
  end

  ask_city

end

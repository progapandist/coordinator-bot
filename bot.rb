require 'facebook/messenger'
require 'httparty'
require 'json'
include Facebook::Messenger


# NOTE: ENV variables should be set directly in terminal for testing on localhost

# Subcribe bot to the page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

Bot.on :message do |message|
  #https://maps.googleapis.com/maps/api/geocode/json?address=
  # TODO: write custom classes with HTTParty mixins"

  case message.text
  when /Moscow/
    geocoder_response = HTTParty.get("https://maps.googleapis.com/maps/api/geocode/json?address=Moscow")
    parsed = JSON.parse(geocoder_response.body)
    coord = parsed['results'].first['geometry']['location']
    message.reply(text: "#{coord['lat']} : #{coord['lng']}")
  end

end

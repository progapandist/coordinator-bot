require 'facebook/messenger'
require 'httparty'
require 'json'
include Facebook::Messenger


# NOTE: ENV variables should be set directly in terminal for testing on localhost

# Subcribe bot to the page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

def wait_for_user_to_mention_coordinates
  Bot.on :message do |message|
    case message.text
    when /coordinates/i
      message.reply(text: "Which city?")
      process_coordinates
    end
  end
end

# TODO: write custom classes with HTTParty mixins"
def process_coordinates
  Bot.on :message do |message|
    geocoder_response = HTTParty.get("https://maps.googleapis.com/maps/api/geocode/json?address=#{message.text}")
    parsed_response = JSON.parse(geocoder_response.body)
    if parsed_response['status'] == 'ZERO_RESULTS'
      message.reply(text: "City not found. Ask me again!")
      wait_for_user_to_mention_coordinates
      break
    end
    coord = parsed_response['results'].first['geometry']['location']
    message.reply(text: "#{coord['lat']} : #{coord['lng']}")
    wait_for_user_to_mention_coordinates
  end
end

# launch the loop
wait_for_user_to_mention_coordinates

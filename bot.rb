require 'facebook/messenger'
require 'httparty'
require 'json'
include Facebook::Messenger
# NOTE: ENV variables should be set directly in terminal for localhost

# IMPORTANT! Subcribe your bot to your page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV['ACCESS_TOKEN'])

API_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address='.freeze

def wait_for_user_input
  Bot.on :message do |message|
    case message.text
    when /coord/i, /gps/i # we use regexp to match parts of strings
      message.reply(text: 'Enter destination')
      process_coordinates
    when /full ad/i # we got the user even if he misspells address
      message.reply(text: 'Enter destination')
      show_full_address
    end
  end
end

def process_coordinates
  Bot.on :message do |message|
    parsed_response = get_parsed_response(API_URL, message.text)
    if !parsed_response
      message.reply(text: 'There were no resutls. Ask me again, please')
      wait_for_user_input
      return
    end
    message.type # let user know we're doing something
    coord = extract_coordinates(parsed_response)
    message.reply(text: "Latitude: #{coord['lat']} / Longitude: #{coord['lng']}")
    wait_for_user_input
  end
end

def show_full_address
  Bot.on :message do |message|
    parsed_response = get_parsed_response(API_URL, message.text)
    if !parsed_response
      message.reply(text: 'There were no resutls. Ask me again, please')
      wait_for_user_input
      return
    end
    message.type # let user know we're doing something
    full_address = extract_full_address(parsed_response)
    message.reply(text: full_address)
    wait_for_user_input
  end
end


# Talk to API
def get_parsed_response(url, query)
  response = HTTParty.get(url + query)
  parsed = JSON.parse(response.body)
  parsed['status'] != 'ZERO_RESULTS' ? parsed : nil
end

def extract_coordinates(parsed)
  parsed['results'].first['geometry']['location']
end


def extract_full_address(parsed)
  parsed['results'].first['formatted_address']
end

# launch the loop
wait_for_user_input

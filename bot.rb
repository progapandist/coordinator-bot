require 'facebook/messenger'
require 'httparty'
require 'json'
include Facebook::Messenger
# NOTE: ENV variables should be set directly in terminal for localhost

# IMPORTANT! Subcribe your bot to your page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV['ACCESS_TOKEN'])

API_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address='.freeze

IDIOMS = {
  not_found: 'There were no resutls. Ask me again, please',
  ask_location: 'Enter destination',
  unknown_command: 'Sorry, I did not recognize your command'
}.freeze

MENU_REPLIES = [
  {
    content_type: 'text',
    title: 'Coordinates',
    payload: 'COORDINATES'
  },
  {
    content_type: 'text',
    title: 'Full address',
    payload: 'FULL_ADDRESS'
  }
]

# helper function to send messages declaratively
def say(recipient_id, text, quick_replies = nil)
  message_options = {
  recipient: { id: recipient_id },
  message: { text: text }
  }
  if quick_replies
    message_options[:message][:quick_replies] = quick_replies
  end
  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
end


def wait_for_any_input
  Bot.on :message do |message|
    show_replies_menu(message.sender['id'], MENU_REPLIES)
  end
end

def show_replies_menu(id, quick_replies)
  say(id, 'What would you like to know?', quick_replies)
  wait_for_command
end

def wait_for_command
  Bot.on :message do |message|
    puts "Received '#{message.inspect}' from #{message.sender}" # debug only
    case message.text
    when /coord/i, /gps/i
      message.reply(text: IDIOMS[:ask_location])
      process_coordinates
    when /full ad/i # we got the user even the address is misspelled
      message.reply(text: IDIOMS[:ask_location])
      show_full_address
    else
      message.reply(text: IDIOMS[:unknown_command])
      show_replies_menu(message.sender['id'], MENU_REPLIES)
    end
  end
end

def process_coordinates
  handle_api_request do |api_response, message|
    coord = extract_coordinates(api_response)
    message.reply(text: "Latitude: #{coord['lat']}, Longitude: #{coord['lng']}")
  end
end

def show_full_address
  handle_api_request do |api_response, message|
    full_address = extract_full_address(api_response)
    message.reply(text: full_address)
  end
end

# DRY-out the bot wrapper
def handle_api_request
  Bot.on :message do |message|
    parsed_response = get_parsed_response(API_URL, message.text)
    message.type # let user know we're doing something
    if parsed_response
      yield(parsed_response, message)
    else
      message.reply(text: IDIOMS[:not_found])
    end
    wait_for_command
  end
end

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
wait_for_any_input

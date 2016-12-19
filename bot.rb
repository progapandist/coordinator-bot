require 'facebook/messenger'
require 'httparty'
require 'json'
include Facebook::Messenger
# NOTE: ENV variables should be set directly in terminal for localhost

# IMPORTANT! Subcribe your bot to your page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV['ACCESS_TOKEN'])

API_URL = 'https://maps.googleapis.com/maps/api/geocode/json?address='.freeze

IDIOMS = {
  not_found: 'Did not quite get that. Come again, please!',
  ask_location: 'Where do you think you are?'
}.freeze

# Don't forget to enable messaging_postbacks in console
Bot.on :postback do |postback|
  sender_id = postback.sender['id']
  case postback.payload
  when 'COORDINATES'
    puts "processing coordinates"
    say(sender_id, IDIOMS[:ask_location], [{content_type: 'text', title: 'Moscow', payload: 'MOSCOW'}])
    process_coordinates
  when 'FULL_ADDRESS'
    show_full_address
  end
end

# helper function to send messages declaratively
def say(recipient_id, text, quick_replies = nil, attachment = nil)
  message_options = {
  recipient: { id: recipient_id },
  message: { text: text }
  }

  if quick_replies
    message_options[:message][:quick_replies] = quick_replies
  end

  if attachment
    message_options[:message][:attachment] = attachment
  end

  Bot.deliver(message_options, access_token: ENV['ACCESS_TOKEN'])
end

def wait_for_user_input
  Bot.on :message do |message|
    puts message.sender['id']
    case message.text
    # when 'hey'.downcase, 'hi'.downcase, /hello/i
    #   say(sender_id, 'What do you want to do?', attachment: {
    #     type: 'template',
    #     payload: {
    #       template_type: 'button',
    #       text: 'Hello! How can I help you',
    #       buttons: [
    #         { type: 'postback', title: 'Give me my coordinates',
    #                             payload: 'COORDINATES' },
    #         { type: 'postback', title: 'Give me my full postal address',
    #                             payload: 'FULL_ADDRESS' }
    #       ]
    #     }
    #   })
    when /coord/i, /gps/i
      message.reply(text: IDIOMS[:ask_location])
      process_coordinates
    when /full ad/i # we got the user even the address is misspelled
      message.reply(text: IDIOMS[:ask_location])
      show_full_address
    end
  end
end

def greet_human
  Bot.on :message do |message|
    message.reply(
      attachment: {
        type: 'template',
        payload: {
          template_type: 'button',
          text: 'Hello! How can I help you',
          buttons: [
            { type: 'postback', title: 'Give me my coordinates',
                                payload: 'COORDINATES' },
            { type: 'postback', title: 'Give me my full postal address',
                                payload: 'FULL_ADDRESS' }
          ]
        }
      }
    )
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
    puts "Received '#{message.inspect}' from #{message.sender}" # debug only
    parsed_response = get_parsed_response(API_URL, message.text)
    unless parsed_response
      message.reply(text: IDIOMS[:not_found])
      wait_for_user_input
      return
    end
    message.type # let user know we're doing something
    yield(parsed_response, message)
    wait_for_user_input
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
wait_for_user_input

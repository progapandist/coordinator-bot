require 'facebook/messenger'
require 'httparty'
include Facebook::Messenger


# NOTE: ENV variables should be set directly in terminal for testing on localhost

# Subcribe bot to the page
Facebook::Messenger::Subscriptions.subscribe(access_token: ENV["ACCESS_TOKEN"])

Bot.on :message do |message|
  message.reply(text: 'Hello, human!')
  message.reply(text: "Your sender no. is #{message.sender}")
  message.reply(text: 'Fuck yourself') if message.text == 'Fuck off'.downcase

  message.reply(
  text: 'Human, who is your favorite bot?',
  quick_replies: [
    {
      content_type: 'text',
      title: 'You are!',
      payload: 'HARMLESS'
    }
  ]
  )
end

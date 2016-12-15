require 'sinatra'
require_relative 'tester'

set :port, 5000
enable :logging

# NOTE: ENV variables should be set directly in terminal for testing on localhost

# Talk to Facebook
get '/webhook' do
  params['hub.challenge'] if ENV["VERIFY_TOKEN"] == params['hub.verify_token']
end

get "/" do
  Tester.say_hi
end

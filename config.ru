require 'sinatra'
require 'json'
require 'shellwords'

get "/" do
  `./mcrcon/mcrcon -H 45.56.109.14 -p #{ENV['RCON_PASSWORD']} list`.strip
end

post "/hook" do
  if params[:token] == ENV["SLACK_TOKEN"]
    user_name = escape(params[:user_name])
    text      = escape(params[:text])

    logger.info %|tellraw @a ["",{"text":"<#{user_name}> #{text}"}]|
    status 201
  else
    status 403
  end

  ""
end

def escape(text)
  Shellwords.escape(text.gsub("+", " ").to_json)
end

run Sinatra::Application

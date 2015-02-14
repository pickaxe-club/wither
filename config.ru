require 'sinatra'
require 'json'

get "/" do
  `./mcrcon/mcrcon -H 45.56.109.14 -p #{ENV['RCON_PASSWORD']} list`.strip
end

post "/hook" do
  if params[:token] == ENV["SLACK_TOKEN"]
    data = {text: "<#{params[:user_name]}> #{params[:text]}"}

    logger.info %|tellraw @a ["",#{data.to_json}]|
    status 201
  else
    status 403
  end

  ""
end

run Sinatra::Application

require 'sinatra'
require 'json'

get "/" do
  rcon "list"
end

post "/hook" do
  if params[:token] == ENV["SLACK_TOKEN"]
    data = {text: "<#{params[:user_name]}> #{params[:text]}"}

    command = %|tellraw @a ["",#{data.to_json}]|
    rcon command
    status 201
  else
    status 403
  end

  ""
end

def rcon(command)
  `./mcrcon/mcrcon -H 45.56.109.14 -p #{ENV['RCON_PASSWORD']} '#{command}'`.strip
end

run Sinatra::Application

require 'sinatra'
require 'json'

get "/" do
  `./mcrcon/mcrcon -H 45.56.109.14 -p #{ENV['RCON_PASSWORD']} 'list'`.strip
end

post "/hook" do
  return unless params[:text]

  if params[:token] == ENV["SLACK_TOKEN"]
    data = {text: "<#{params[:user_name]}> #{params[:text].gsub("'", "’").gsub('"', "”")}"}

    logger.info params.inspect
    logger.info data.to_json
    command = %|tellraw @a ["",#{data.to_json}]|
    `./mcrcon/mcrcon -H 45.56.109.14 -p #{ENV['RCON_PASSWORD']} '#{command}'`.strip
    status 201
  else
    status 403
  end

  ""
end

post "/minecraft/hook" do
  payload = JSON.parse(params[:payload])

  payload['events'].each do |event|
    logger.info event['message']
  end

  'ok'
end

run Sinatra::Application

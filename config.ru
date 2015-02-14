require 'sinatra'
require 'json'
require 'rest-client'

get "/" do
  `./mcrcon/mcrcon -H 45.56.109.14 -p #{ENV['RCON_PASSWORD']} 'list'`.strip
end

post "/hook" do
  text = params[:text]
  if text == nil || text == "" || text =~ /slackbot/
    return 'nope'
  end

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

  'ok'
end

post "/minecraft/hook" do
  logger.info request.body

  if request.body =~ /<(.*)> (.*)/
    user_name = $1
    text = $2

    RestClient.post ENV["ZAPIER_URL"], user_name: user_name, text: text
  end

  'ok'
end

run Sinatra::Application

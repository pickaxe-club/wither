require 'sinatra'
require 'json'
require 'rest-client'

get "/" do
  `./mcrcon/mcrcon -H 45.56.109.14 -p #{ENV['RCON_PASSWORD']} 'list'`.strip
end

post "/hook" do
  text = params[:text]
  user_name = params[:user_name]

  if text == nil || text == "" || user_name =~ /slackbot/
    return 'nope'
  end

  if params[:token] == ENV["SLACK_TOKEN"]
    data = {text: "<#{user_name}> #{text.gsub("'", "’").gsub('"', "”")}"}

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
  body = request.body.read
  logger.info body

  if body =~ /INFO\]: <(.*)> (.*)/
    user_name = $1
    text = $2

    RestClient.post ENV["SLACK_URL"], {username: user_name, text: text, icon_url: "https://crafatar.com/avatars/#{user_name}"}.to_json, content_type: :json, accept: :json
  elsif body !~ /entity/ && body =~ /\[Server thread\/INFO\]: (.*)/
    RestClient.post ENV["SLACK_URL"], {text: $1}.to_json, content_type: :json, accept: :json
  end

  'ok'
end

run Sinatra::Application

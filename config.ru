require 'sinatra'
require 'json'
require 'rest-client'
require 'chunky_png'

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

    RestClient.post ENV["SLACK_URL"], {username: user_name, text: text, icon_url: "https://pickaxechat.herokuapp.com/steve.png"}.to_json, content_type: :json, accept: :json
  end

  'ok'
end

get "/avatars/:user_name.png" do
  begin
    content_type :png
    skin = RestClient.get("http://s3.amazonaws.com/MinecraftSkins/#{params[:user_name]}.png")
    avatar = ChunkyPNG::Image.from_blob(skin)
    avatar.crop(8, 8, 8, 8).resample_nearest_neighbor(64, 64).to_blob
  rescue
    send_file File.join(settings.public_folder, 'steve.png')
  end
end

run Sinatra::Application

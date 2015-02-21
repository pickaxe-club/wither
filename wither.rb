class Wither < Sinatra::Application
  def rcon(command)
    rcon = RCON::Minecraft.new ENV['RCON_IP'], 25575
    rcon.auth ENV['RCON_PASSWORD']
    rcon.command(command).strip
  end

  get "/" do
    rcon "list"
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
      logger.info command
      command = %|tellraw @a ["",#{data.to_json}]|
      rcon command
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
    end

    'ok'
  end
end

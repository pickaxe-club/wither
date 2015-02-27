class Wither < Sinatra::Application
  def rcon(command)
    rcon = RCON::Minecraft.new ENV['RCON_IP'], ENV['RCON_PORT'] || 25575
    rcon.auth ENV['RCON_PASSWORD']
    rcon.command(command).strip
  end

  def say_in_game(user_name, text)
    data = {text: "<#{user_name.gsub(/\Aslackbot\z/, "Steve")}> #{text}"}
    rcon %|tellraw @a ["",#{data.to_json}]|
  end

  def say_in_slack(user_name, text)
    RestClient.post ENV["SLACK_URL"], {username: user_name, text: text, icon_url: "https://crafatar.com/avatars/#{user_name}"}.to_json, content_type: :json, accept: :json
  end

  get "/" do
    rcon "list"
  end

  post "/hook" do
    text = params[:text]
    user_name = params[:user_name]

    if text == nil || text == ""
      return 'nope'
    end

    if params[:token] == ENV["SLACK_TOKEN"]
      if text == "steve list"
        say_in_slack "Steve", rcon("list")
      else
        say_in_game user_name, text
      end
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
      say_in_slack $1, $2
    end

    'ok'
  end
end

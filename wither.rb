require 'cgi'
require 'active_support/core_ext'

class Say
  class << self
    def rcon(command)
      rcon = RCON::Minecraft.new ENV['RCON_IP'], ENV['RCON_PORT'] || 25575
      rcon.auth ENV['RCON_PASSWORD']
      rcon.command(command).strip
    end

    def game(user_name, text)
      # Replace curly single and double quotes with non-Unicode versions
      text.gsub!(/[\u201c\u201d]/, '"')
      text.gsub!(/[\u2018\u2019]/, "'")

      data = { text: "<#{user_name.gsub(/\Aslackbot\z/, 'Steve')}> #{CGI.unescapeHTML(text.gsub(/<(\S+)>/, "\\1"))}" }
      rcon %|tellraw @a ["",#{data.to_json}]|
    end

    def slack(user_name, text)
      RestClient.post ENV['SLACK_URL'], {
        username: user_name, text: text, icon_url: "https://minotar.net/avatar/#{user_name}?date=#{Date.today}"
      }.to_json, content_type: :json, accept: :json
    end
  end
end

class Command
  def initialize(who, line)
    @who = who
    @line = line
  end

  def run
    execute if allowed?
  end

  def execute
    raise NotImplementedError
  end

  def allowed?
    @who == "qrush"
  end

  def droplet_client
    @droplet_client ||= DropletKit::Client.new(access_token: ENV['DO_ACCESS_TOKEN'])
  end
end

class DnsCommand < Command
  def execute
    if @line =~ /^wither dns ([\w]+) ([\d\.]+)$/
      client = Dnsimple::Client.new(username: ENV['DNSIMPLE_USERNAME'], api_token: ENV['DNSIMPLE_TOKEN'])
      client.domains.update_record("pickaxe.club", 4395396, {name: $1, content: $2})

      Say.slack 'wither', "I've moved pickaxe to #{$1}.pickaxe.club, pointing at #{$2}. :pickaxe:"
    end
  end
end

class SayCommand < Command
  def execute
    Rcon.game @who, @line
  end

  def allowed?
    true
  end
end

class ListCommand < Command
  def execute
    list = Say.rcon('list')
    Say.slack 'wither', list
    Say.game 'wither', list
  end

  def allowed?
    true
  end
end

class StatusCommand < Command
  def execute
    droplet = droplet_client.droplets.all.find { |drop| drop.name == 'pickaxe.club' }

    Say.slack 'wither', "Pickaxe.club is online at #{droplet.public_ip}"
  end
end

class ShutdownCommand < Command
  def execute
    droplet = droplet_client.droplets.all.find { |drop| drop.name == 'pickaxe.club' }
    client.droplets.delete(id: droplet.id)

    Say.slack 'wither', "Pickaxe.club is shutting down. I hope it was backed up!"
  end
end

class Wither < Sinatra::Application
  COMMANDS = %w(list dns ip boot shutdown status backup generate)

  get '/' do
    'Wither!'
  end

  post '/hook' do
    text = params[:text]
    user_name = params[:user_name]

    if text == nil || text == '' || user_name == 'slackbot'
      return 'nope'
    end

    if params[:token] == ENV['SLACK_TOKEN']
      wither, command, * = text.split

      if wither == "wither" && COMMANDS.include?(command)
        command_class = "#{command}_command".camelize.safe_constantize
        command_class.new(user_name, text).execute
      end

      status 201
    else
      status 403
    end

    'ok'
  end

  post '/minecraft/hook' do
    body = request.body.read
    logger.info body

    if body =~ /INFO\]: <(.*)> (.*)/
      Say.slack $1, $2
    elsif body =~ %r{Server thread/INFO\]: ([^\d]+)}
      line = $1
      Say.slack 'wither', line if line !~ /the game/
    end

    'ok'
  end

  post '/cloud/booted/:instance_id' do
    logger.info params.inspect
    instance_id = params[:instance_id]
    Say.slack "wither", "I've finished booting #{instance_id}!"
  end
end

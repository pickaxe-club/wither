require 'cgi'
require 'open-uri'
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

  private
    def execute
      raise NotImplementedError
    end

    def allowed?
      @who == "qrush"
    end

    def slack(line)
      Say.slack 'wither', line
    end
end

class DnsCommand < Command
  def execute
    if @line =~ /^wither dns ([\w]+) ([\d\.]+)$/
      client = Dnsimple::Client.new(username: ENV['DNSIMPLE_USERNAME'], api_token: ENV['DNSIMPLE_TOKEN'])
      client.domains.update_record("pickaxe.club", 4395396, {name: $1, content: $2})

      slack "I've moved pickaxe to #{$1}.pickaxe.club, pointing at #{$2}. :pickaxe:"
    end
  end
end

class SayCommand < Command
  def execute
    Say.game @who, @line
  end

  def allowed?
    true
  end
end

class ListCommand < Command
  def execute
    list = Say.rcon('list')
    slack list
    Say.game 'wither', list
  end

  def allowed?
    true
  end
end

class DropletCommand < Command
  private
    def client
      @client ||= DropletKit::Client.new(access_token: ENV['DO_ACCESS_TOKEN'])
    end

    def droplet
      @droplet ||= client.droplets.all.find { |drop| drop.name == 'pickaxe.club' }
    end
end

class StatusCommand < DropletCommand
  def execute
    if droplet
      public_ip = droplet.public_ip

      Net::SSH.start(public_ip, "minecraft", :password => ENV['DO_SSH_PASSWORD'], :timeout => 10) do |ssh|
        output = ssh.exec!("uptime")
        slack "Pickaxe.club is online at #{public_ip}. `#{output.strip}`"
      end
    else
      slack "Pickaxe.club is offline!"
    end
  rescue Errno::ETIMEDOUT
    slack "Pickaxe.club is timing out. Maybe offline?"
  end

  def allowed?
    true
  end
end

class BootCommand < DropletCommand
  def execute
    if droplet
      Say.slack 'wither', 'Pickaxe.club is already running!'
    else
      droplet = DropletKit::Droplet.new(
        name: 'pickaxe.club',
        region: 'tor1',
        image: 'ubuntu-15-10-x64',
        size: '16gb',
        private_networking: true,
        user_data: open(ENV['DO_USER_DATA_URL']).read # ROFLMAO
      )
      client.droplets.create(droplet)
      slack "Pickaxe.club is booting up!"
    end
  end
end

class ShutdownCommand < DropletCommand
  def execute
    if droplet
      client.droplets.delete(id: droplet.id)

      slack "Pickaxe.club is shutting down. I hope it was backed up!"
    else
      slack "Pickaxe.club isn't running."
    end
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
        command_class.new(user_name, text).run
      else
        SayCommand.new(user_name, text).run
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

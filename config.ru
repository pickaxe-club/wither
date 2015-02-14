require 'sinatra'

get "/" do
  `./mcrcon/mcrcon -H 45.56.109.14 -p #{ENV['RCON_PASSWORD']} list`.strip
end

run Sinatra::Application

# pickaxe.club chat

A Slack to Minecraft chat gateway

![](https://raw.githubusercontent.com/qrush/pickaxechat/master/screenshot.png)

In action:

![](https://raw.githubusercontent.com/qrush/pickaxechat/master/gateway.gif)

## Install

* Push this to Heroku
* Point Slack outgoing webhooks to your Heroku URL
* Set `SLACK_URL` as Slack incoming webhook URL
* Make sure `RCON_IP`, `RCON_PASSWORD` are set in heroku configuration to your server's IP/hostname and RCON password

Run the following on your server hosting (in a screen, and make sure to replace your Heroku URL and your log directory location):

``` sh
tail -f /PATH_TO_MINECRAFT_INSTALL/logs/latest.log | grep --line-buffered ": <" | while read x ; do echo -ne $x | curl -X POST -d @- https://YOUR_HEROKU_URL.herokuapp.com/minecraft/hook ; done
```

## TODO

* Blurgh post
* Make a heroku buildpack for mcrcon or replace with a ruby only library to avoid shell commands/vulns
* Extract out of config.ru and into separate file
* Figure out how to restart the chat every day at 12:00AM UTC, as Minecraft rotates the log file then

## License

MIT. See `LICENSE`.

# pickaxe.club chat

A Slack to Minecraft chat gateway

![](https://raw.githubusercontent.com/qrush/pickaxechat/master/screenshot.png)

In action:

![](https://raw.githubusercontent.com/qrush/pickaxechat/master/gateway.gif)

## Install

* Push this to Heroku
* Point Slack outgoing webhooks to your Heroku URL
* Set `SLACK_URL` as Slack incoming webhook URL
* Make sure `RCON_IP`, `RCON_PASSWORD` are set in heroku configuration to your server's IP/hostname and RCON password. If `RCON_PORT` is not set it uses the default (25575).

Run the following on your server hosting (in a screen, and make sure to replace your Heroku URL and your log directory location):

``` sh
tail -F /PATH_TO_MINECRAFT_INSTALL/logs/latest.log | grep --line-buffered ": <" | while read x ; do echo -ne $x | curl -X POST -d @- https://YOUR_HEROKU_URL.herokuapp.com/minecraft/hook ; done
```

## TODO

* Blurgh post
* Tweet stuff
* Ask where people are in game
* On-the-fly mapgen
* Monitor farms / coords for status changes

## License

MIT. See `LICENSE`.

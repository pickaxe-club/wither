var system = require('system');

if (system.args.length < 3 || system.args.length > 4) {
    console.log('Usage: map.js zoom xpos ypos file.png');
    phantom.exit();
} else {
    url = system.args[1];
    file = system.args[2];

    var page = require('webpage').create();
    page.viewportSize = { width: 1024, height: 768 };
    page.open(url, function() {
      setTimeout(function() {
        page.evaluate(function() {
          // hide controls
          document.querySelectorAll("body > div")[1].style.display = "none";
          document.querySelectorAll(".leaflet-control-container")[0].style.display = "none";
        });

        page.render(file, {format: 'jpeg'});
        phantom.exit();
      }, 250);
    });
}

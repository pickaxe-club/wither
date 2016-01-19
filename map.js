var system = require('system');

if (system.args.length < 5 || system.args.length > 6) {
    console.log('Usage: map.js zoom xpos ypos file.png');
    phantom.exit();
} else {
    zoom = system.args[1];
    xpos = system.args[2];
    ypos = system.args[3];
    file = system.args[4];

    var page = require('webpage').create();
    page.viewportSize = { width: 1024, height: 768 };
    page.open('http://www.pickaxe.club/#overworld/0/' + zoom + '/' + xpos + '/' + ypos + '/64', function() {
      setTimeout(function() {
        page.evaluate(function() {
          // hide controls
          document.querySelectorAll("body > div")[1].style.display = "none";
          document.querySelectorAll(".leaflet-control-container")[0].style.display = "none";
        });

        page.render(file);
        phantom.exit();
      }, 100);
    });
}

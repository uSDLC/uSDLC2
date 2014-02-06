/* Copyright (C) 2014 paul@marrington.net, see GPL license */
(function() {
  var handle = location.host + location.pathname;
  if (!window.usdlc2) {
    window.usdlc2 = {
      host: "localhost"
    };
  }
  
  function open() {
    usdlc2.ws = new WebSocket(usdlc2.url);
    usdlc2.ws.onopen = function() {
      console.log("uSDLC2 connection open for "+handle);
    };
    usdlc2.ws.onmessage = function(event) {
      eval(event.data);
    };
    usdlc2.ws.onclose = function(event) {
      console.log("uSDLC2 connection closed for "+handle);
      setTimeout(open, 1000);
    };
  }
  
  if (!usdlc2.name) {
    var name = /usdlc2-name=([!&]+)/.exec(location.search);
    if (name === null || name.length != 2) {
      console.log("uSDCL2 Instrumentation requires a name");
      name = location.href;
    }
    usdc2.name = name;
  }
  var port = /usdlc2-port=(\d+)/.exec(location.search);
  if (port === null || port.length != 2) {
    console.log("uSDCL2 Instrumentation requires a port");
  } else {
    usdlc2.url = "ws://"+usdlc2.host+":"+port[1]+
      "/server/http/browser_manager.coffee?name="+usdc2.name;
    open();
  }
})();
/* Copyright (C) 2014 paul@marrington.net, see GPL license */
(function() {
  var handle = location.host + location.pathname;
  var retain = /usdlc2-retain-page/.exec(location.search);
  var opened = 0;
  if (!window.usdlc2) {
    window.usdlc2 = {
      host: "localhost"
    };
  }
  window.gwt = window.usdlc2;
  function open() {
    usdlc2.ws = new WebSocket(usdlc2.url);
    usdlc2.ws.onopen = function() {
      opened++;
      console.log("uSDLC2 connection open ("+opened+
                  ") for "+usdlc2.url);
    };
    usdlc2.ws.onmessage = function(event) {
      eval(event.data);
    };
    window.console = {
      assert: function() {
        var args = Array.prototype.slice.call(arguments, 0);
        if (!args[0]) console.error.apply(args.slice(1));
      },
      error: function() {
        var args = Array.prototype.slice.call(arguments, 0);
        args.push(new Error().stack);
        console.log.apply(this, args);
      },
      log: function() {
        var args = [];
        for (var i = 0; i < arguments.length; i++) {
          var arg = arguments[i];
          if (typeof arg == "object") {
            arg = JSON.stringify(arg);          
          }
          args.push(arg);
        }
        usdlc2.ws.send(args.join(' ')+'\n');
      },
      group: function() {}, groupEnd: function() {},
      groupCollapsed: function() {}
    };
    console.debug = console.dir = console.info = console.log;
    console.exception = console.error;
    usdlc2.ws.onclose = function(event) {
      setTimeout(open, 1000);
      if (opened) {
        opened--;
        console.log("uSDLC2 connection closed for "+handle);
        if (!retain) window.close();
      }
    };
    usdlc2.fail = function(msg) {
      console.log("Failed: "+(msg ? msg : ''));
    };
    usdlc2.pass = function(msg) {
      console.log("Passed: "+(msg ? msg : ''));
    };
    usdlc2.test = function(passed, msg) {
      if (passed) {
        usdlc2.pass();
      } else {
        usdlc2.fail(msg);
      }
    };
    usdlc2.check = function(left, right) {
      usdlc2.test(left != right, left+" isn't "+right);
    };
    usdlc2.wait_for = function(checker, interval) {
      if (!interval) interval = 2000;
      var full_check = function() {
        if (checker()) {
          usdlc2.pass();
        } else {
          setTimeout(full_check, interval);
        }
      };
      full_check();
    };
  }
  
  if (!usdlc2.name) {
    var name = /usdlc2-name=([^&]+)/.exec(location.search);
    if (name === null || name.length != 2) {
      console.log("uSDCL2 Instrumentation requires a name");
      name = ['', location.host+location.pathname];
      console.log("Using: "+name);
    }
    usdlc2.name = name[1];
  }
  var port = /usdlc2-port=(\d+)/.exec(location.search);
  if (port === null || port.length != 2) {
    console.log("uSDLC2 Instrumentation requires a port");
  } else {
    usdlc2.url = "ws://"+usdlc2.host+":"+port[1]+
      "/server/gwt/browser.coffee?name="+usdlc2.name;
    open();
  }
})();
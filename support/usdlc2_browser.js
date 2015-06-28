/* Copyright (C) 2014 paul@marrington.net, see GPL license */
(function() {
  function go() {
    if (!window.usdlc2) { window.usdlc2 = {}; }

    function param(name, def) {
      var re = new RegExp(name+"=([^&]+)");
      var value = re.exec(location.search);
      if (value !== null  &&  value.length == 2) return value[1];
      if (usdlc2[name]) return usdlc2[name];
      return def;
    }
    var retain = param('usdlc2-retain-page', false);
    var handle = param('usdlc2-name',location.host+location.pathname);
    var host = param('usdlc2-host', 'localhost');
    var port = param('usdlc2-port', 0);
    if (port === 0) return; // don't drive if no port specified

    var opened = 0;
    window.gwt = window.usdlc2;
    function open() {
      usdlc2.ws = new WebSocket(usdlc2.url);
      usdlc2.ws.onopen = function() {
        opened++;
        console.log("uSDLC2 connection open ("+opened+
                    ") for "+usdlc2.url);
      };
      usdlc2.ws.onmessage = function(event) {
        try { eval(event.data); }
        catch (err) { console.log(err); }
      };
      original_console = window.console;
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
          original_console.log.apply(original_console, arguments);
          for (var i = 0; i < arguments.length; i++) {
            var arg = arguments[i];
            if (typeof arg == "object" && !(arg instanceof Error)) {
              try { arg = JSON.stringify(arg); }
              catch (e) { arg = arg.toString(); }
            }
            args.push(arg);
          }
          args = args.join(' ')+'\n'
          try {
            if (usdlc2.ws.readyState !== usdlc2.ws.OPEN) throw new Error
            usdlc2.ws.send(args);
          } catch (e) {
            window.console = original_console;
            window.console.log(args);
          }
        },
        group: function() {}, groupEnd: function() {},
        groupCollapsed: function() {}
      };
      console.debug = console.dir = console.info = console.log;
      console.exception = console.error;
      usdlc2.ws.onclose = function(event) {
        if (!retain) return window.close();
        if (opened) {
          opened--;
          window.console = original_console;
          console.log("uSDLC2 connection closed for "+handle);
          setTimeout(open, 5000);
        }
      };
      usdlc2.fail = function(msg) {
        if (msg && msg.stack) msg = msg.message+'\n'+msg.stack;
        console.log("Failed: "+(msg ? msg : ''));
      };
      usdlc2.pass = function(msg) {
        console.log("Passed: "+(msg ? msg : ''));
      };
      usdlc2.test = function(passed, msg_or_timeout, interval) {
        if (passed instanceof Function) {
          return usdlc2.wait_for(passed, msg_or_timeout, interval)
        }
        if (passed) {
          usdlc2.pass();
        } else {
          usdlc2.fail(msg_or_interval);
        }
      };
      usdlc2.check = function(left, right) {
        usdlc2.test(left == right, left+" isn't "+right);
      };
      usdlc2.on_loaded = function(checker, timeout, interval) {
        if (!interval) interval = 200;
        if (!timeout) timeout = 10000;
        var waiter = 5; // Wait a few ticks the first time
        var full_check = function() {
          if (!checker()) {
            if ((timeout -= interval) > 0) {
              setTimeout(full_check, waiter);
              waiter = interval
            } else {
              checker(true);
            }
          }
        };
        full_check();
      };
      usdlc2.wait_for = function(checker, timeout, interval) {
        var pass_checker = function(timed_out) {
          if (timed_out) return usdlc2.fail("Timeout exceeded");
          if (checker()) { usdlc2.pass(); return true; }
          return false;
        }
        usdlc2.on_loaded(pass_checker, timeout, interval);
      };
    }
    usdlc2.url = "ws://"+host+":"+port+
      "/server/gwt/browser.coffee?name="+handle;
    open();
  }
  //window.addEventListener("load", go, false);
  go();
})();

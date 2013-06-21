// Generated by CoffeeScript 1.6.2
(function() {
  var Plugin, exec;

  exec = require('child_process').exec;

  Plugin = (function() {
    function Plugin() {
      this.app = app;
    }

    return Plugin;

  })();

  module.exports = {
    extend: function(obj) {
      Array.prototype.slice.call(arguments, 1).forEach(function(source) {
        var prop, _results;

        if (source) {
          _results = [];
          for (prop in source) {
            _results.push(obj[prop] = source[prop]);
          }
          return _results;
        }
      });
      return obj;
    },
    syscall: function(command, callback, throws) {
      if (throws == null) {
        throws = true;
      }
      return exec(command, function(error, stdout, stderr) {
        if (stdout) {
          console.log("stdout: " + stdout);
        }
        if (stderr && throws) {
          console.error(command);
          throw "stderr: " + stderr;
        }
        if (error && throws) {
          console.error(command);
          throw "exec error: " + error;
        }
        return typeof callback === "function" ? callback(stdout, error || stderr) : void 0;
      });
    },
    flash: function(req, message_type, message) {
      var m, _base, _ref, _ref1;

      if (message_type && message) {
        m = (_ref = (_base = req.session).messages) != null ? _ref : _base.messages = {};
        if ((_ref1 = m[message_type]) == null) {
          m[message_type] = [];
        }
        return m[message_type].push(message);
      }
    },
    Plugin: Plugin
  };

}).call(this);

// Generated by CoffeeScript 1.6.2
(function() {
  var exec;

  exec = require('child_process').exec;

  module.exports = {
    syscall: function(command, callback, throws) {
      var child;

      if (throws == null) {
        throws = true;
      }
      return child = exec(command, function(error, stdout, stderr) {
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
    }
  };

}).call(this);

/*
//@ sourceMappingURL=util.map
*/

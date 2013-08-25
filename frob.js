#!/usr/bin/env node

var fs = require("fs");
var lisp = require("lispyscript");
require("lispyscript/lib/require");
var file = require("file");
var sh = require("execSync");
var quote = require("shell-quote").quote;

var declare = require("./lib/declare");

var argv = require("optimist")
      .boolean("u")
      .alias("u", "update")
      .describe("u", "refetch remote assets")
      .boolean("f")
      .alias("f", "force")
      .describe("f", "apply changes even when not needed")
      .usage("Usage: $0 script-file")
      .argv;

if (argv._.length !== 1) {
  require("optimist").showHelp();
  process.exit(1);
}

declare.argv(argv);

var closureHeader = '(var invoke (function (declare)\n'
      + '(declare.pkg.apt "git" "curl")\n';
var closureFooter = '))\n(invoke declare)';

var script;

if (fs.existsSync(argv._[0])) {
  script = fs.readFileSync(argv._[0], "utf-8");
} else {
  var curl = sh.exec(quote(["curl", "--silent", argv._[0]]));
  if (curl.code > 0) {
    console.error("Could not read config file", argv._[0]);
    console.error(curl.stdout);
    process.exit(1);
  } else {
    script = curl.stdout;
  }
}

script = lisp._compile(closureHeader + script + closureFooter, argv._[0]);
try {
  eval(script);
} catch(e) {
  if (e.ohaiError) {
    console.error("ERROR:", e.message);
    process.exit(1);
  } else {
    throw e;
  }
}

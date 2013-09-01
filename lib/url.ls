(include "./lib/macros.ls")

(var context (require "./context"))
(var argv (require "./argv"))
(var sh (require "execSync"))
(var ansi (.set (require "ansi-color")))
(var print (.print (require "util")))
(var quote (.quote (require "shell-quote")))
(var file (require "./fs"))
(var path (require "path"))

(defn curl (url target)
  (var result null)
  (file.mkdir (path.dirname target))
  (print (ansi "HTTP get: " "magenta+bold")
         (ansi url "yellow+bold")
         (ansi " => " "green")
         (ansi target "yellow+bold") "\n")
  (set result (sh.run (quote (array "curl" "--progress-bar" "--output"
                                    target url))))
  (when (!= 0 result)
    (error "curl command failed.")))

(defn url (target url)
  (var url (context.expand url)
       target (context.processPath context.env.target target)
       stat (file.lstat target))
  (cond
   (! stat)
   (curl url target)

   (|| (! (stat.isFile)) (|| argv.update argv.force))
   (do
     (file.rm target)
     (curl url target)))
  target)

(set url.curl curl)
(set module.exports url)

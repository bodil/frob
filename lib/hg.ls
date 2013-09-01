(include "./lib/macros.ls")

(var argv (require "./argv"))
(var error (require "./error"))
(var context (require "./context"))
(var configParse (require "./config-parse"))
(var fs (require "fs"))
(var path (require "path"))
(var sh (require "execSync"))
(var ansi (.set (require "ansi-color")))
(var print (.print (require "util")))
(var quote (.quote (require "shell-quote")))
(var file (require "./fs"))

(defn hgClone (url target)
  (print (ansi "hg clone: " "magenta+bold")
         (ansi url "yellow+bold")
         (ansi " => " "green")
         (ansi target "yellow+bold") "\n")
  (var result (sh.run (quote (array "hg" "clone" url target))))
  (when (!= 0 result)
    (error "hg clone command failed.")))

(defn hgPull (target)
  (print (ansi "hg pull: " "magenta+bold")
         (ansi target "yellow+bold") "\n")
  (var result (sh.run (quote (array "cd" target ";" "hg" "pull" "-u"))))
  (when (!= 0 result)
    (error "hg pull command failed.")))

(defn hgRemote (repo remote)
  (var configPath (path.join repo ".hg" "hgrc")
       configFile ((.split (fs.readFileSync configPath "utf-8")) "\n")
       config (configParse configFile)
       paths config.paths)
  (if paths.default paths.default null))

(defn assertHg (url target)
  (var stat (file.lstat target))
  (cond
   (! stat)
   (hgClone url target)

   (stat.isDirectory)
   (if (|| (! (fs.existsSync (path.join target ".hg"))) argv.force)
     (do
       (file.rm target)
       (hgClone url target))
     (if (!= url (hgRemote target "origin"))
       (do
         (file.rm target)
         (hgClone url target))
       (when argv.update (hgPull target))))

   true
   (do
     (file.rm target)
     (hgClone url target))))

(defn hg (url target)
  (var url (context.expand url)
       target (context.processPath context.env.target target))
  (file.mkdir (path.dirname target))
  (assertHg url target)
  target)

(set module.exports hg)

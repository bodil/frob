(include "./lib/macros.ls")

(var fs (require "fs"))
(var path (require "path"))
(var sh (require "execSync"))
(var rimraf (.sync (require "rimraf")))
(var mkdirp (.sync (require "mkdirp")))
(var ansi (.set (require "ansi-color")))
(var print (.print (require "util")))
(var quote (.quote (require "shell-quote")))

(var argv (require "./argv"))
(var context (require "./context"))

(defn lstat (path)
  (try
    (fs.lstatSync path)
    (function (e) null)))

(defn symlink (linkpath value)
  (print (ansi "Symlink: " "magenta+bold")
         (ansi linkpath "yellow+bold")
         (ansi " => " "green")
         (ansi value "yellow+bold") "\n")
  (fs.symlinkSync value linkpath))

(defn rm (path)
  (print (ansi "Remove:  " "red")
         (ansi path "red+bold") "\n")
  (rimraf path))

(defn mkdir (path)
  (var stat (lstat path))
  (when (|| (! stat) (! (stat.isDirectory)))
    (when stat (rm path))
    (print (ansi "Mkdir:   " "magenta+bold")
           (ansi path "yellow+bold") "\n")
    (mkdirp path)))

(defn assertLink (target source)
  (var rel (path.relative (path.dirname target) source)
       stat (lstat target))
  (mkdir (path.dirname target))
  (cond
   (! stat)
   (symlink target rel)

   (&& (stat.isSymbolicLink) (! argv.force))
   (do
     (var link (fs.readlinkSync target))
     (when (!= link rel)
       (rm target)
       (symlink target rel)))

   true
   (do
     (rm target)
     (symlink target rel))))

(defn link (target source)
  (var t (context.processPath context.env.target target)
       s (context.processPath context.env.source source))
  (assertLink t s))

(defn perms (target perms)
  (var target (context.processPath context.env.target target)
       perms (context.expand perms))
  (sh.run (quote (array "chmod" "-R" perms target))))

(set module.exports
     (object lstat lstat
             rm rm
             mkdir mkdir
             link link
             perms perms))

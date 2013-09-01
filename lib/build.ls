(include "./lib/macros.ls")

(var _ (require "underscore"))
(var argv (require "./argv"))
(var error (require "./error"))
(var context (require "./context"))
(var sh (require "execSync"))
(var ansi (.set (require "ansi-color")))
(var print (.print (require "util")))
(var quote (.quote (require "shell-quote")))
(var fs (require "./fs"))

(defn mostRecent (stats)
  (reduce
   stats
   (function (t stat)
             (if (object? stat)
               (Math.max t ((.getTime (.mtime stat))))
               t))
   0))

(defn needsBuild (target deps)
  (var tstat (fs.lstat target)
       dstat (map deps fs.lstat))
  (if (! tstat)
    true
    (do
      (var r (mostRecent dstat))
      (< ((.getTime (.mtime tstat))) r))))

(defn build (target deps command)
  (var target (context.processPath context.env.target target)
       deps (if (_.isArray deps)
              (map deps (function (i)
                          (context.processPath context.env.source i)))
              (array (context.processPath context.env.source deps))))
  (set command (quote (map command context.expand)))
  (when (|| argv.force (needsBuild target deps))
    (print (ansi "Build:   " "magenta+bold")
           (ansi target "yellow+bold") "\n"
           (ansi "  => " "green")
           (ansi command "blue+bold") "\n")
    (when (!= 0 (sh.run command))
      (error (str "Build command failed: " command)))))

(set module.exports build)

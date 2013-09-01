(include "./lib/macros.ls")

(var _ (require "underscore"))
(var path (require "path"))
(var template (require "whiskers"))
(var argv (require "./argv"))

(var context
     (object source (process.cwd)
             target argv.target))

(defn expand (s)
  (template.render s (_.extend context process.env)))

(defn setvar (name value)
  (set name context (expand value)))

(defn withSource (path)
  (setvar "source" path))

(defn withTarget (path)
  (setvar "target" path))

(defn processPath (root p)
  (path.resolve root (expand p)))

(set module.exports
     (object expand expand
             setvar setvar
             withSource withSource
             withTarget withTarget
             processPath processPath
             env context))

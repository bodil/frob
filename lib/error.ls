(include "./lib/macros.ls")

(defn error (msg)
  (throw (object ohaiError true
                 message msg)))

(set module.exports error)

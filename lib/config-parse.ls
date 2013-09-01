(include "./lib/macros.ls")

(defn configParse (c)
  (var out {}
       current null)
  (each c
        (function (line)
                  (var line (line.trim)
                       match (line.match /\[(.*)\]/))
                  (if match
                    (do
                      (var key (get 1 match))
                      (set current {})
                      (set key out current))
                    (do
                      (var match (line.match /\s*(\S+)\s*=\s*(\S+)\s*/))
                      (when match
                        (var key (get 1 match)
                             value (get 2 match))
                        (set key current value))))))
  out)

(set module.exports configParse)

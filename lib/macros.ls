(macro defn (name args rest...)
       (var ~name (function ~args ~rest...)))

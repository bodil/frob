(set module.exports
     (.argv
      (-> (require "optimist")
          (.demand 1)
          (.option "u" (object alias "update"
                               describe "refetch remote assets"))
          (.boolean "u")
          (.option "f" (object alias "force"
                               describe "apply changes even when not needed"))
          (.boolean "f")
          (.option "o" (object alias "target"
                               describe "specify target directory"
                               default process.env.HOME))
          (.usage "Usage: $0 script-file"))))

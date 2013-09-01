(var context (require "./context"))

(set module.exports
  (object withSource context.withSource
          withTarget context.withTarget
          var context.setvar
          fs (require "./fs")
          npm (require "./npm")
          git (require "./git")
          hg (require "./hg")
          url (require "./url")
          pkg (object apt (require "./apt")
                      pacman (require "./pacman"))))

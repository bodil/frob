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

(defn gitClone (url target)
  (print (ansi "git clone: " "magenta+bold")
         (ansi url "yellow+bold")
         (ansi " => " "green")
         (ansi target "yellow+bold") "\n")
  (var result (sh.run (quote (array "git" "clone" url target))))
  (when (!= 0 result)
    (error "git clone command failed."))
  (set result (sh.run (quote (array "cd" target ";"
                                    "git" "submodule" "update" "--init"))))
  (when (!= 0 result)
    (error "git submodule update command failed.")))

(defn gitPull (target)
  (print (ansi "git pull: " "magenta+bold")
         (ansi target "yellow+bold") "\n")
  (var result (sh.run (quote (array "cd" target ";" "git" "pull"))))
  (when (!= 0 result)
    (error "git pull command failed.")))

(defn gitRemote (repo remote)
  (var configPath (path.join repo ".git" "config")
       configFile ((.split (fs.readFileSync configPath "utf-8")) "\n")
       config (configParse configFile)
       key (str "remote \"" remote "\"")
       remote (get key config))
  (if remote remote.url null))

(defn assertGit (url target)
  (var stat (file.lstat target))
  (cond
   (! stat)
   (gitClone url target)

   (stat.isDirectory)
   (if (|| (! (fs.existsSync (path.join target ".git"))) argv.force)
     (do
       (file.rm target)
       (gitClone url target))
     (if (!= url (gitRemote target "origin"))
       (do
         (file.rm target)
         (gitClone url target))
       (when argv.update (gitPull target))))

   true
   (do
     (file.rm target)
     (gitClone url target))))

(defn git (url target)
  (var url (context.expand url)
       target (context.processPath context.env.target target))
  (file.mkdir (path.dirname target))
  (assertGit url target)
  target)

(set module.exports git)

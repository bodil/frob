(var file (require "file"))
(var fs (require "fs"))
(var path (require "path"))
(var sh (require "execSync"))
(var rimraf (.sync (require "rimraf")))
(var template (require "whiskers"))
(var ansi (.set (require "ansi-color")))
(var _ (require "underscore"))
(var print (.print (require "util")))
(var quote (.quote (require "shell-quote")))

(macro defn (name args rest...)
       (var ~name (function ~args ~rest...)))

(defn error (msg)
  (throw (object ohaiError true
                 message msg)))

(var argv null)

(defn setArgv (a)
  (set argv a))

;; Context variables
(var context
     (object source (process.cwd)
             target process.env.HOME))

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
    (file.mkdirsSync path)))

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
  (var t (processPath context.target target)
       s (processPath context.source source))
  (assertLink t s))

(defn perms (target perms)
  (var target (processPath context.target target)
       perms (expand perms))
  (sh.run (quote (array "chmod" "-R" perms target))))

(defn npmSet (key value)
  (var key (expand key)
       value (expand value)
       current (sh.exec (quote (array "npm" "config" "--local" "get" key))))
  (if (!= 0 current.code)
    (error current.stdout)
    (do
      (var c (current.stdout.trim))
      (when (!= c value)
        (print (ansi "NPM set: " "magenta+bold")
               (ansi (str key " ") "cyan+bold")
               (ansi c "yellow+bold")
               (ansi " => " "green")
               (ansi value "yellow+bold") "\n")
        (sh.exec (quote (array "npm" "config" "--local" "set" key value)))))))

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

(defn gitConfigParse (c)
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

(defn gitRemote (repo remote)
  (var configPath (path.join repo ".git" "config")
       configFile ((.split (fs.readFileSync configPath "utf-8")) "\n")
       config (gitConfigParse configFile)
       key (str "remote \"" remote "\"")
       remote (get key config))
  (if remote remote.url null))

(defn assertGit (url target)
  (var stat (lstat target))
  (cond
   (! stat)
   (gitClone url target)

   (stat.isDirectory)
   (if (|| (! (fs.existsSync (path.join target ".git"))) argv.force)
     (do
       (rm target)
       (gitClone url target))
     (if (!= url (gitRemote target "origin"))
       (do
         (rm target)
         (gitClone url target))
       (when argv.update (gitPull target))))

   true
   (do
     (rm target)
     (gitClone url target))))

(defn git (url target)
  (var url (expand url)
       target (processPath context.target target))
  (mkdir (path.dirname target))
  (assertGit url target)
  target)

(defn curl (url target)
  (var result null)
  (mkdir (path.dirname target))
  (print (ansi "HTTP get: " "magenta+bold")
         (ansi url "yellow+bold")
         (ansi " => " "green")
         (ansi target "yellow+bold") "\n")
  (set result (sh.run (quote (array "curl" "--progress-bar" "--output"
                                    target url))))
  (when (!= 0 result)
    (error "curl command failed.")))

(defn url (target url)
  (var url (expand url)
       target (processPath context.target target)
       stat (lstat target))
  (cond
   (! stat)
   (curl url target)

   (|| (! (stat.isFile)) (|| argv.update argv.force))
   (do
     (rm target)
     (curl url target)))
  target)

(defn isAptSystem ()
  (var result (sh.exec "dpkg --version"))
  (= 0 result.code))

(defn aptInstalled (pkg)
  (var result (sh.exec (quote (array "dpkg-query" "-W" pkg))))
  (= 0 result.code))

(defn aptInstall (pkgs)
  (print (ansi "Install: " "magenta+bold")
         (ansi (pkgs.join " ") "yellow+bold") "\n")
  (var args (array "sudo" "apt-get" "install" "-y"))
  (when argv.force (args.push "--reinstall"))
  (set args (args.concat pkgs))
  (when (sh.run (quote args))
    (error "apt-get install failed.")))

(defn aptGet ()
  (var pkgs (map (_.toArray arguments) expand))
  (when (isAptSystem)
    (set pkgs (pkgs.filter (function (i) (! (aptInstalled i)))))
    (when pkgs.length
      (aptInstall pkgs))))

(defn isPacmanSystem ()
  (var result (sh.exec "which pacman"))
  (= 0 result.code))

(defn pacmanInstalledPackage (pkg)
  (var result (sh.exec (quote (array "pacman" "-Q" pkg))))
  (= 0 result.code))

(defn pacmanInstalledGroup (pkg)
  (var result (sh.exec (quote (array "pacman" "-Qg" pkg))))
  (= 0 result.code))

(defn pacmanInstalled (pkg)
  (|| (pacmanInstalledPackage pkg)
      (pacmanInstalledGroup pkg)))

(defn pacmanInstall (pkgs)
  (print (ansi "Install: " "magenta+bold")
         (ansi (pkgs.join " ") "yellow+bold") "\n")
  (var args (array "sudo" "pacman" "-S"))
  (set args (args.concat pkgs))
  (when (sh.run (quote args))
    (error "apt-get install failed.")))

(defn pacmanSync ()
  (var pkgs (map (_.toArray arguments) expand))
  (when (isPacmanSystem)
    (set pkgs (pkgs.filter (function (i) (! (pacmanInstalled i)))))
    (when pkgs.length
      (pacmanInstall pkgs))))

(set module.exports
  (object argv setArgv
          withSource withSource
          withTarget withTarget
          var setvar
          mkdir mkdir
          link link
          perms perms
          npm (object set npmSet)
          git git
          url url
          pkg (object apt aptGet
                      pacman pacmanSync)))

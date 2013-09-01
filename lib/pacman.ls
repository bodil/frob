(include "./lib/macros.ls")

(var _ (require "underscore"))
(var path (require "path"))
(var os (require "os"))
(var sh (require "execSync"))
(var quote (.quote (require "shell-quote")))
(var print (.print (require "util")))
(var rimraf (.sync (require "rimraf")))
(var argv (require "./argv"))
(var error (require "./error"))
(var context (require "./context"))
(var file (require "./fs"))
(var curl (.curl (require "./url")))

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
  (var args (array "sudo" "pacman" "--noconfirm" "-S"))
  (set args (args.concat pkgs))
  (when (sh.run (quote args))
    (error "apt-get install failed.")))

(defn pacmanSync ()
  (var pkgs (map (_.toArray arguments) context.expand))
  (when (isPacmanSystem)
    (set pkgs (pkgs.filter (function (i) (! (pacmanInstalled i)))))
    (when pkgs.length
      (pacmanInstall pkgs))))

(defn pacmanAurUrl (pkg)
  (var chop (pkg.slice 0 2))
  (str "https://aur.archlinux.org/packages/"
       chop "/" pkg "/" pkg ".tar.gz"))

(defn pacmanAurBuild (pkg)
  (var origCwd (process.cwd)
       tmpPath (path.join (os.tmpdir) "frob" pkg)
       buildPath (path.join tmpPath pkg)
       archivePath (path.join tmpPath (str pkg ".tar.gz")))
  (rimraf tmpPath)
  (file.mkdir tmpPath)
  (curl (pacmanAurUrl pkg) archivePath)
  (when (sh.run (quote (array "cd" tmpPath ";" "tar" "xvf" archivePath)))
    (error "Package extraction failed."))
  (when (sh.run (quote (array "cd" buildPath ";"
                              "makepkg" "-i" "-s" "--noconfirm")))
    (error "makepkg failed."))
  (rimraf tmpPath))

(defn pacmanAur ()
  (each (_.toArray arguments)
    (function (pkg)
      (when (|| (! (pacmanInstalled pkg)) (|| argv.force argv.update))
        (pacmanAurBuild pkg)))))

(set pacmanSync.aur pacmanAur)
(set module.exports pacmanSync)

(include "./lib/macros.ls")

(var _ (require "underscore"))
(var sh (require "execSync"))
(var quote (.quote (require "shell-quote")))
(var print (.print (require "util")))
(var ansi (.set (require "ansi-color")))
(var fs (require "fs"))
(var path (require "path"))

(var context (require "./context"))
(var error (require "./error"))
(var argv (require "./argv"))

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
  (var pkgs (map (_.toArray arguments) context.expand))
  (when (isAptSystem)
    (set pkgs (pkgs.filter (function (i) (! (aptInstalled i)))))
    (when pkgs.length
      (aptInstall pkgs))))

(defn ppaMangle (s)
  (s.replace /\./g "_"))

(defn parsePPA (ppa)
  (var m (ppa.match /^ppa:([^\/]*)\/(.*)/))
  (when m
    (object user (ppaMangle (get 1 m))
            path (ppaMangle (get 2 m)))))

(defn releaseCodeName ()
  (var r (sh.exec "lsb_release -cs"))
  (if r (r.stdout.trim)
      (error "Could not determine Ubuntu release.")))

(defn isPPAInstalled (ppa)
  (var ppa (parsePPA ppa)
       release (releaseCodeName))
  (when ppa
    (fs.existsSync (path.join "/etc/apt/sources.list.d"
                              (str ppa.user "-" ppa.path "-"
                                   release ".list")))))

(defn aptInstallPPA ()
  (var ppas (map (_.toArray arguments) context.expand)
       dirty false)
  (when (isAptSystem)
    (each ppas
          (function (ppa)
                    (unless (isPPAInstalled ppa)
                            (set dirty true)
                            (when (!= 0
                                      (sh.run
                                       (quote (array "sudo" "add-apt-repository" "-y" ppa))))
                              (error "add-apt-repository command failed.")))))
    (when dirty
      (when (!= 0 (sh.run "sudo apt-get update"))
        (errpr "apt-get update command failed.")))))

(set aptGet.ppa aptInstallPPA)

(set module.exports aptGet)

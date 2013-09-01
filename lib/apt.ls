(var _ (require "underscore"))
(var sh (require "execSync"))
(var quote (.quote (require "shell-quote")))
(var print (.print (require "util")))
(var ansi (.set (require "ansi-color")))

(var context (require "./context"))
(var error (require "./error"))

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

(set module.exports aptGet)

;; Example frobfile for setting up an environment from my
;; personal dotfiles repo.

;; First, check out the dotfiles repo and set it as the source root.

;; The system operates with the idea of source and target roots.
;; The target root defaults to your home directory. Most file paths
;; are relative to this directory.

;; The source root is typically your dotfiles repo.
;; The source root defaults to the current working directory,
;; although you usually want to set it explicitly. Here, we declare
;; a git repository to be cloned into $HOME/.dotfiles, and
;; set the source root to be the fresh clone.

;; Note the template syntax: keywords inside braces will be expanded
;; into either their corresponding environment variables, as with
;; `{HOME}` in this case, or into variables from the local context.
;; Only {source} and {target} exist by default, but you can use
;; `declare.var` to define more if you need to.

(declare.withSource (declare.git "git@caturday.me:dotfiles" "{target}/.dotfiles"))

;; Declare packages that need to be installed on a Debian based system.
;; `declare.pkg.apt` will be silently ignored on a system without
;; a dpkg installation.

(declare.pkg.apt.ppa "ppa:vincent-c/ppa"
                     "ppa:chris-lea/node.js")

(declare.pkg.apt
 ;; Editors
 "joe"

 ;; Tools
 "build-essential" "libtool" "devscripts" "dput" "tmux" "gnupg" "openssh-client"
 "htop" "isoquery" "w3m" "nodejs" "nodejs-dev" "openjdk-7-jre" "ruby"

 ;; Ponies
 "ponysay" "fortune-mod"

 ;; X11
 "i3" "xcompmgr" "fonts-liberation" "fonts-droid" "x11-xserver-utils"
 "xdotool" "python-pyudev" "python-dbus" "xbindkeys"

 ;; Apps
 "firefox" "chromium-browser" "deluge-gtk" "gimp" "inkscape")

;; Declare packages to install using Pacman. As with `declare.pkg.apt`,
;; these will be ignored on systems where Pacman is not installed.

(declare.pkg.pacman
 "base-devel" "tmux" "pulseaudio" "alsa-utils" "w3m" "openssh" "git"

 "xorg" "xdotool" "unclutter" "python-pyudev" "python-dbus"
 "python-gobject2" "onboard"

 "ttf-liberation" "ttf-ubuntu-font-family" "ttf-droid"

 "gnome" "gnome-settings-daemon-compat" "gnome-tweak-tool"
 "notify-osd"

 "firefox" "gimp" "inkscape" "chromium"

 "deluge" "python2-notify" "pygtk"

 "ponysay" "fortune-mod")

;; You can also install packages from AUR.

(declare.pkg.pacman.aur
 "package-query" "yaourt" "i3-gnome" "awesome-gnome" "bittorrent-sync")

;; Declare symlinks to the dotfiles repo in the home directory.
;; The link declaration takes the path to the symlink, relative to
;; the target root, as its first argument, and the symlink destination,
;; relative to the source root, as its second. Note that there's no
;; need to explicitly create parent directories for these symlinks;
;; they will be created as necessary.

;; Crypto dotfiles:
(declare.fs.link ".ssh" "ssh")
(declare.fs.link ".gnupg" "gnupg")

;; These contain private keys, so we declare them to be inaccessible
;; to others. For ssh, this is even mandatory.

(declare.fs.perms ".ssh" "go-rwx")
(declare.fs.perms ".gnupg" "go-rwx")

;; Bash
(declare.fs.link ".profile" "profile")
(declare.fs.link ".bashrc" "bashrc")

;; I keep my tmux setup in a public git repo rather than my
;; dotfiles repo, so this will need to be cloned separately.
;; We declare a git repo in ~/.tmux, and link .tmux.conf
;; to the config file inside the repo.

;; Tmux
(declare.git "git@github.com:bodil/tmuxified.git" ".tmux")
(declare.fs.link ".tmux.conf" "{target}/.tmux/tmux.conf")

;; Misc X11
(declare.fs.link ".fonts" "fonts")
(declare.fs.link ".Xmodmap" "Xmodmap")
(declare.fs.link ".xmonad" "xmonad")
(declare.fs.link ".i3" "i3")
(declare.fs.link ".i3status.conf" "i3/i3status.conf")

;; GNOME
(declare.fs.link ".config/autostart/tabletd.desktop"
              "autostart/tabletd.desktop")

;; Dev
(declare.fs.link ".gitconfig" "gitconfig")
(declare.fs.link ".lein" "lein")

;; Set up $HOME/bin with useful scripts.

;; We'll install the hub and lein commands directly from the
;; internets by using the url declaration. It takes the path
;; relative to the target root to download to, and the URL to
;; download from. The URL is passed as is to curl, so all protocols
;; supported by your curl build are supported.

(declare.url "bin/hub" "http://hub.github.com/standalone")
(declare.fs.perms "bin/hub" "+x")
(declare.fs.link "man/man1/hub.1" "man/hub.1")

(declare.url "bin/lein"
             "https://raw.github.com/technomancy/leiningen/stable/bin/lein")
(declare.fs.perms "bin/lein" "+x")

(declare.fs.link "bin/window-focus" "bin/window-focus")

;; The `npm.set` declaration is used to configure user local NPM settings.
;; In this case, we tell NPM to use $HOME/node as its global installation
;; directory. This corresponds to calling `npm config --local set`.

(declare.npm.set "prefix" "{target}/node")

;; Checkout the GNOME3 Maximus extension using Mercurial.

(declare.hg "https://bitbucket.org/mathematicalcoffee/maximus-gnome-shell-extension"
            "workspace/ext/maximus")
(declare.var
 "maximus"
 "{target}/.local/share/gnome-shell/extensions/maximus@mathematical.coffee.gmail.com")
(declare.fs.link
 "{maximus}"
 "{target}/workspace/ext/maximus/maximus@mathematical.coffee.gmail.com")

;; GNOME3 extensions usually need to have their schemas compiled.
;; We use `declare.build` to declare a makefile like rule for rebuilding
;; a target file when its dependencies have changed.

(declare.build
 "{maximus}/schemas/gschemas.compiled"
 "{maximus}/schemas/org.gnome.shell.extensions.maximus.gschema.xml"
 (array "glib-compile-schemas" "{maximus}/schemas"))

;; Check out the .emacs.d from Github.

(declare.git "git@github.com:bodil/emacs.d.git" ".emacs.d")

;; Check out typescript-tools and install it using npm.

(declare.git "https://github.com/clausreinke/typescript-tools.git"
             "workspace/ext/typescript-tools")

(declare.build "node/bin/tss"
               "workspace/ext/typescript-tools/bin/tss"
               (array "cd" "{target}/workspace/ext/typescript-tools" ";"
                      "npm" "install" "-g"))


;; Now for something more ambitious: checkout Emacs from Github and build
;; it from source.

(declare.var "emacs" "{target}/workspace/ext/emacs")
(declare.var "emacsSrc" "{emacs}/source")
(declare.var "emacsBin" "{emacs}/build")

(declare.git "git@github.com:emacsmirror/emacs.git" "{emacsSrc}")

;; Ensure Emacs build dependencies are installed.

(declare.pkg.pacman "base-devel" "gtk2")

;; Checkout the `master` branch—this repo starts in the `about` branch
;; after cloning.

(declare.build "{emacsSrc}/README" []
               (array "cd" "{emacsSrc}" ";" "git" "checkout" "master"))

;; Now build and install Emacs.

(declare.build "{emacsSrc}/configure"
               (array "{emacsSrc}/configure.ac" "{emacsSrc}/autogen.sh")
               (array "cd" "{emacsSrc}" ";" "./autogen.sh"))

(declare.build "{emacsBin}/Makefile"
               (array "{emacsSrc}/configure")
               (array "mkdir" "-p" "{emacsBin}" ";"
                      "cd" "{emacsBin}" ";"
                      "{emacsSrc}/configure"
                      "--with-x-toolkit=gtk3"
                      "--with-xft" "--with-xim"
                      "--with-gconf" "--with-dbus"
                      "--with-gif=no"
                      "--prefix" "{target}/emacs"))

(declare.build "{emacsBin}/src/emacs" "{emacsSrc}"
                (array "cd" "{emacsBin}" ";" "make" "-j5" "bootstrap"))

(declare.build "{target}/emacs/bin" "{emacsBin}"
               (array "cd" "{emacsBin}" ";" "make" "install"))

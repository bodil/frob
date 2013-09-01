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

(declare.withSource (declare.git "git@caturday.me:dotfiles" "{HOME}/.dotfiles"))

;; Declare packages that need to be installed on a Debian based system.
;; `declare.pkg.apt` will be silently ignored on a system without
;; a dpkg installation.

(declare.pkg.apt
 ;; Editors
 "emacs24" "emacs24-el" "joe"

 ;; Tools
 "build-essential" "libtool" "devscripts" "dput" "tmux" "gnupg" "openssh-client"
 "htop" "isoquery" "w3m" "nodejs" "nodejs-dev" "openjdk-7-jre" "ruby"

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

 "firefox" "emacs"

 "deluge" "python2-notify" "pygtk")

;; You can also install packages from AUR.

(declare.pkg.aur
 "package-query" "yaourt" "i3-gnome" "awesome-gnome")

;; Declare symlinks to the dotfiles repo in the home directory.
;; The link declaration takes the path to the symlink, relative to
;; the target root, as its first argument, and the symlink destination,
;; relative to the source root, as its second. Note that there's no
;; need to explicitly create parent directories for these symlinks;
;; they will be created as necessary.

;; Crypto dotfiles:
(declare.link ".ssh" "ssh")
(declare.link ".gnupg" "gnupg")

;; These contain private keys, so we declare them to be inaccessible
;; to others. For ssh, this is even mandatory.

(declare.perms ".ssh" "go-rwx")
(declare.perms ".gnupg" "go-rwx")

;; Bash
(declare.link ".profile" "profile")
(declare.link ".bashrc" "bashrc")

;; I keep my tmux setup in a public git repo rather than my
;; dotfiles repo, so this will need to be cloned separately.
;; We declare a git repo in ~/.tmux, and link .tmux.conf
;; to the config file inside the repo.

;; Tmux
(declare.git "git@github.com:bodil/tmuxified.git" ".tmux")
(declare.link ".tmux.conf" "{target}/.tmux/tmux.conf")

;; Misc X11
(declare.link ".fonts" "fonts")
(declare.link ".Xmodmap" "Xmodmap")
(declare.link ".xmonad" "xmonad")
(declare.link ".i3" "i3")
(declare.link ".i3status.conf" "i3/i3status.conf")

;; GNOME
(declare.link ".config/autostart/tabletd.desktop"
              "autostart/tabletd.desktop")

;; Dev
(declare.link ".gitconfig" "gitconfig")
(declare.link ".lein" "lein")

;; Set up $HOME/bin with useful scripts.

;; We'll install the hub and lein commands directly from the
;; internets by using the url declaration. It takes the path
;; relative to the target root to download to, and the URL to
;; download from. The URL is passed as is to curl, so all protocols
;; supported by your curl build are supported.

(declare.url "bin/hub" "http://hub.github.com/standalone")
(declare.perms "bin/hub" "+x")
(declare.link "man/man1/hub.1" "man/hub.1")

(declare.url "bin/lein"
             "https://raw.github.com/technomancy/leiningen/stable/bin/lein")
(declare.perms "bin/lein" "+x")

(declare.link "bin/window-focus" "bin/window-focus")

;; The `npm.set` declaration is used to configure user local NPM settings.
;; In this case, we tell NPM to use $HOME/node as its global installation
;; directory. This corresponds to calling `npm config --local set`.

(declare.npm.set "prefix" "{target}/node")

;; Finally, check out the .emacs.d from Github.

(declare.git "git@github.com:bodil/emacs.d.git" ".emacs.d")

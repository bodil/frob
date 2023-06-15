#!/usr/bin/env -S deno run --allow-read --allow-write --allow-env

import * as frob from "../frob.ts";

frob.root.home();

frob.link(".dotfiles", "Sync/Dotfiles");
frob.link(".fonts", ".dotfiles/fonts");
frob.link(".gitconfig", ".dotfiles/gitconfig");
frob.link(".gitignore", ".dotfiles/gitignore");
frob.link(".gnupg", ".dotfiles/gnupg");
frob.link(".ssh", ".dotfiles/ssh");

frob.root.config();

frob.link("fish", "../.dotfiles/fish");
frob.link("omf", "../.dotfiles/omf");

frob.file.script(
    "plasma-workspace/env/ssh-agent.sh",
    `
#!/bin/bash

export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket
export SSH_ASKPASS=/usr/bin/ksshaskpass
export SSH_ASKPASS_REQUIRE=prefer
export GIT_ASKPASS=$SSH_ASKPASS
`
);

frob.file.text("environment.d/firefox-wayland.conf", "MOZ_ENABLE_WAYLAND=1");

frob.apply();

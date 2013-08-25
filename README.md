# Frob

Frob is a configuration management tool designed for personal use.

Given a simple declarative config file (actually [LispyScript](http://lispyscript.com) with a declarative API provided), Frob can quickly and reliably set up your home directory and workstation environment just the way you like it.

Frob also makes it easy to keep all your dotfiles in a Git repo, and to keep it in sync across machines.

## Installation

Frob needs a working Node installation in order to run. If that's in order, you simply run the following to install Frob:

```sh
$ npm install frob
```

## Usage

Run Frob on your config file to get going:

```sh
$ frob my-setup.ls
```

Note that unless specifically told to (using the `--force` flag), Frob will only make the necessary changes to bring your system into the order described in the config file. Thus, running it twice should result in the second run having no effect at all.

## Config files

See the exhaustively commented [example config](examples/bodil.ls).

# License

Copyright 2013 Bodil Stokke

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at
[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0).

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing
permissions and limitations under the License.

#! /bin/bash
#
# bootstrap.sh
# Copyright (C) 2014 josh <josh@ubuntu>
#
# Distributed under terms of the MIT license.
#

ensure_installed() {
	type $1 >/dev/null 2>&1 || { echo >&2 "$1 is required to use shaddox. Please install it manually."; exit 1;  }
}

ensure_installed(ruby)
ensure_installed(gem)

if ! gem list shaddox -i; then
	gem install shaddox
fi

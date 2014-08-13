#! /bin/sh
#
# install.sh
# Copyright (C) 2014 joshglendenning <joshglendenning@Q.local>
#
# Distributed under terms of the MIT license.
#


gem build shaddox.gemspec
gem push shaddox-*
sudo gem install shaddox-*
rm shaddox-*

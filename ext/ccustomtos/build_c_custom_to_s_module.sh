#!/bin/bash

# compile and install the C module
# from: http://www.rubyinside.com/how-to-create-a-ruby-extension-in-c-in-under-5-minutes-100.html
ruby extconf.rb
export DESTDIR=`pwd`
make clean
RUBY_VERSION_DIR=`rbenv prefix`
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$RUBY_VERSION_DIR/lib
make
#make install
echo --------------------------- makefile ldflags
grep -i ldflags Makefile
echo ---------------------------

# cleanup
rm -rf Makefile extconf.h usr .sitearchdir.time > /dev/null 2>&1
rm -f bench_file > /dev/null 2>&1

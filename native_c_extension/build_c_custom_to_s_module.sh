#!/bin/bash

# compile and install the C module
# from: http://www.rubyinside.com/how-to-create-a-ruby-extension-in-c-in-under-5-minutes-100.html
ruby c_custom_to_s_module.rb
export DESTDIR=`pwd`
make clean
pkg-config --cflags ruby --libs ruby
cat Makefile
make
#make install

# cleanup
rm -rf Makefile extconf.h usr .sitearchdir.time > /dev/null 2>&1
rm -f bench_file > /dev/null 2>&1

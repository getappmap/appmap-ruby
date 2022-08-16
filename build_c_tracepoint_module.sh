#!/bin/bash

# compile and install the C module
# from: http://www.rubyinside.com/how-to-create-a-ruby-extension-in-c-in-under-5-minutes-100.html
ruby c_tracepoint_module.rb
export DESTDIR=`pwd`
make clean
make
#make install

# there should be a better way to copy this, and without hardcoding version numbers
cp ccustomtracepoint.so \
   $HOME/.rbenv/versions/3.0.1/lib/ruby/site_ruby/3.0.0/appmap/.

# cleanup
rm -rf Makefile extconf.h usr .sitearchdir.time > /dev/null 2>&1
rm -f bench_file > /dev/null 2>&1

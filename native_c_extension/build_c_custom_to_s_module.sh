#!/bin/bash

# compile and install the C module
# from: http://www.rubyinside.com/how-to-create-a-ruby-extension-in-c-in-under-5-minutes-100.html
ruby c_custom_to_s_module.rb
export DESTDIR=`pwd`
make clean
LDFLAGS=`pkg-config --libs ruby`
echo LDFLAGS is $LDFLAGS
# force the Makefile to have these LDFLAGS
sed -ie "s/ldflags\(.*\)/ldflags\1AA $LDFLAGS/g" Makefile
make
#make install

# cleanup
rm -rf Makefile extconf.h usr .sitearchdir.time > /dev/null 2>&1
rm -f bench_file > /dev/null 2>&1

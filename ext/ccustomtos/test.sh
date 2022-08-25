#!/bin/bash

# ./build_c_custom_to_s_module.sh

#gcc c_custom_to_s.c c_custom_to_s_test.c -I/usr/include/x86_64-linux-gnu/ruby-2.7.0 -I/usr/include/ruby-2.7.0 -lruby-2.7 -lm
# pkg-config --cflags --libs ruby

# don't keep this file name .C else `bundle exec rake compile`
# attempts to compile it too and it conflicts with the extension
cp c_custom_to_s_test.c.disabled c_custom_to_s_test.c
gcc c_custom_to_s_test.c -I/usr/include/x86_64-linux-gnu/ruby-2.7.0 -I/usr/include/ruby-2.7.0 -lruby-2.7 -lm
rm -f c_custom_to_s_test.c

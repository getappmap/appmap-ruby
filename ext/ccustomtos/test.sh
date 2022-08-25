#!/bin/bash

# ./build_c_custom_to_s_module.sh

#gcc c_custom_to_s.c c_custom_to_s_test.c -I/usr/include/x86_64-linux-gnu/ruby-2.7.0 -I/usr/include/ruby-2.7.0 -lruby-2.7 -lm
# pkg-config --cflags --libs ruby

gcc c_custom_to_s_test.cpp -I/usr/include/x86_64-linux-gnu/ruby-2.7.0 -I/usr/include/ruby-2.7.0 -lruby-2.7 -lm

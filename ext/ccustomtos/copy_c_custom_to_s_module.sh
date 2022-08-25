#!/bin/bash

TARGET=~/devel/sample_app_6th_ed/vendor/bundle/ruby/2.7.0/gems/appmap-0.86.0/lib/appmap/

FILES="build_c_custom_to_s_module.sh c_custom_to_s.c c_custom_to_s_module.rb"

for file in $FILES; do
    cp $file $TARGET/.
done

cd $TARGET
./build_c_tracepoint_module.sh

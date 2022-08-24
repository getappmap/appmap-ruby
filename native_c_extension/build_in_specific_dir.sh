#!/bin/bash

# used to debug


TARGET_DIR=$HOME/devel/sample_app_6th_ed/vendor/bundle/ruby/3.0.0/bundler/gems/appmap-ruby-61177cc3accd/lib/appmap
#TARGET_DIR=$HOME/devel/sample_app_6th_ed/vendor/bundle/ruby/3.0.0/gems/appmap-0.87.0/lib/appmap
TARGET_DIR=$HOME/devel/solidus/vendor/bundle/ruby/3.0.0/gems/appmap-0.87.0/lib/appmap
TARGET_DIR=$HOME/devel/appmap-server/vendor/bundle/ruby/3.0.0/bundler/gems/appmap-ruby-970d5f8f2f39/lib/appmap

TARGET_DIR_INPUT=$1
if [ "$TARGET_DIR_INPUT" != "" ]; then
    TARGET_DIR=$TARGET_DIR_INPUT
fi

FILES="c_custom_to_s.c c_custom_to_s_module.rb build_c_custom_to_s_module.sh ../lib/appmap/event.rb"
for file in $FILES; do
    cp $file $TARGET_DIR/.
done

cd $TARGET_DIR
./build_c_custom_to_s_module.sh

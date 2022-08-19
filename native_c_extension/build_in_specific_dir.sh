#!/bin/bash

# used to debug

# TARGET_DIR=$1

# if [ "$TARGET_DIR" == "" ]; then
#     echo "usage:   $0 <target_dir>"
#     echo "example: $0 ~/sample_app_6th_ed"
#     exit 0
# fi

TARGET_DIR=$HOME/devel/sample_app_6th_ed/vendor/bundle/ruby/3.0.0/bundler/gems/appmap-ruby-61177cc3accd/lib/appmap/
TARGET_DIR=$HOME/devel/sample_app_6th_ed/gems/gems/appmap-0.86.0/lib/appmap/
TARGET_DIR=$HOME/devel/sample_app_6th_ed/vendor/bundle/ruby/3.0.0/gems/appmap-0.86.0/lib/appmap
#TARGET_DIR=$HOME/devel/sample_app_6th_ed/gems/gems/appmap-0.86.0/lib/appmap

FILES="c_custom_to_s.c c_custom_to_s_module.rb build_c_custom_to_s_module.sh ../lib/appmap/event.rb"
for file in $FILES; do
    cp $file $TARGET_DIR/.
done

cd $TARGET_DIR
./build_c_custom_to_s_module.sh

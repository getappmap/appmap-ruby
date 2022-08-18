#!/bin/bash

if [ ! -e "gems/gems" ]; then
    gem install --install-dir=gems tabulate
fi

./build_c_custom_to_s_module.sh
export DESTDIR=`pwd`
make install

# run the benchmark
export GEM_HOME=gems
ruby bench.rb
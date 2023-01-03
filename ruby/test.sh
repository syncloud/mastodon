#!/bin/bash -ex
DIR=$( cd "$( dirname "$0" )" && pwd )
cd $DIR/../build/snap/ruby
./bin/ruby.sh -e 'puts "Hello"'
./bin/node.sh -e 'console.log("test")'
./bin/file file -b --mime $DIR/../integration/csv/following.csv

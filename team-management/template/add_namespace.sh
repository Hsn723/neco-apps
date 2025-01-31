#!/bin/sh
# usage: ./add_namespace.sh team namespace
#
# yq eval "x *+ y" merges two objects, while it deeply merges arrays.
./bin/yq eval ". *+ {\"namespaces\": {\"$1\": {\"$2\": {\"accurate.cybozu.com/template\": \"init-template\", \"accurate.cybozu.com/type\": \"root\"}}}}" settings.json -j > /tmp/settings.json
mv /tmp/settings.json settings.json
make format-settings > /dev/null

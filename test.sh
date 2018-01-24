#!/usr/bin/env bash

set -e
set -x
MODE=atomic
echo "mode: $MODE" > coverage.txt

# All packages.
PKG=$(go list ./...)
staticcheck $PKG
unused $PKG

# Fetch and build perf_data_converter
git clone --recursive git://github.com/google/perf_data_converter third_party/perf_data_converter
make perf_to_profile -C third_party/perf_data_converter
cp third_party/perf_data_converter/perf_to_profile ~/. && rm -rf third_party/perf_data_converter/*

# Packages that have any tests.
PKG=$(go list -f '{{if .TestGoFiles}} {{.ImportPath}} {{end}}' ./...)

go test -v $PKG

for d in $PKG; do
  go test -race -coverprofile=profile.out -covermode=$MODE $d
  if [ -f profile.out ]; then
    cat profile.out | grep -v "^mode: " >> coverage.txt
    rm profile.out
  fi
done


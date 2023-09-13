#!/bin/bash

LUA=lua5.1

for script in $(ls compress-*.lua)
do
	perf stat -d $LUA $script
done

stat -c '%n - %s' compressed-*.txt

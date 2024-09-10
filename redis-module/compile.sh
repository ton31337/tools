#!/bin/bash

gcc -fPIC -std=gnu99 -c -o module.o hproxy.c
ld -o module.so module.o -shared -Bsymbolic -lc
cp ./module.so /tmp/module.so
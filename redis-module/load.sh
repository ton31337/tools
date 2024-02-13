#!/bin/bash

redis-cli debug set-disable-deny-scripts 1
redis-cli function delete h5g
redis-cli -x function load < h5g_flushdb.lua

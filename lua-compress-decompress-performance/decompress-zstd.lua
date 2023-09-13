local zstd = require "zstd"

local file_i = io.open("compressed-zstd.txt", "r")
local file_o = io.open("decompressed-zstd.txt", "w")
io.input(file_i)
io.output(file_o)
local input = file_i:read("*all")
local output = zstd.decompress(input)
io.write(output)
io.close(file_i)
io.close(file_o)


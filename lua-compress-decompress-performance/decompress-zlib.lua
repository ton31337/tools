local lz = require "zlib"

local file_i = io.open("compressed-zlib.txt", "r")
local file_o = io.open("decompressed-zlib.txt", "w")
io.input(file_i)
io.output(file_o)
local input = file_i:read("*all")
local output = lz.inflate()(input, "finish")
io.write(output)
io.close(file_i)
io.close(file_o)

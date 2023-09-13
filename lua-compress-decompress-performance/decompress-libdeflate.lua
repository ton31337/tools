local deflate = require "LibDeflate"

local file_i = io.open("compressed-libdeflate.txt", "r")
local file_o = io.open("decompressed-libdeflate.txt", "w")
io.input(file_i)
io.output(file_o)
local input = file_i:read("*all")
local output = deflate:DecompressDeflate(input)
io.write(output)
io.close(file_i)
io.close(file_o)


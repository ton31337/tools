local lzo = require "luaLZO"

local file_i = io.open("compressed-lzo.txt", "r")
local file_o = io.open("decompressed-lzo.txt", "w")
io.input(file_i)
io.output(file_o)
local input = file_i:read("*all")
local output = lzo.decompress(input)
io.write(output)
io.close(file_i)
io.close(file_o)

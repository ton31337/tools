local lz = require "zlib"

function decompress(input)
  return lz.inflate()(input, "finish")
end

local file_i = io.open("compressed-zlib.txt", "r")
local file_o = io.open("decompressed-zlib.txt", "w")
io.input(file_i)
io.output(file_o)
local input = file_i:read("*all")
local ok, output = pcall(decompress, input)
if not ok then
  print(intput)
  return
else
  print(output)
end
io.write(output)
io.close(file_i)
io.close(file_o)

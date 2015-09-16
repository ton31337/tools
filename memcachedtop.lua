--[[
memcachetop.lua - show most used memcached keys.

USAGE: sysdig -c memcachetop <refresh> <count>
  eg,

  sysdig -c memcachetop    # show memcached utilization every second and stop after 10 seconds
  sysdig -c 5              # show memcached utilization every 5 second and stop after 10 seconds
  sysdig -c '2 20'         # show memcached utilization every 2 second and stpo after 20 seconds

By default it will run as sysdig -c '1 10'.

Copyright (C) 2015 Donatas Abraitis.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

-- Chisel description
description = "memcached keys utilization"
short_description = "memcached keys utilization"
category = "misc"

-- Chisel argument list
args =
{
  {
    name = "refresh",
    description = "refresh interval",
    optional = true
  },
  {
    name = "stop",
    description = "stop tracing after N seconds",
    optional = true
  },
}

-- Helpers --
terminal = require "ansiterminal"

function split(s, delimiter)
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
    table.insert(result, match);
  end
  return result;
end

function sort(t)
  local tmp = {}
  for key, val in pairs(t) do
    table.insert(tmp, val)
  end
  table.sort(tmp, function(a, b) return a<b end)
  return tmp
end

function results(stack, origin)
  local tmp = {}
  for i=0,9 do
    local pop = table.remove(stack)
    for key, val in pairs(origin) do
      if val == pop then
        tmp[key] = val
      end
    end
  end
  return tmp
end

-- Argument notification callback
function on_set_arg(name, val)
    if name == "stop" then
      stop_after = tonumber(val)
      return true
    elseif name == "refresh" then
      refresh = tonumber(val)
      return true
    end
    return false
end

-- Initialization callback
function on_init()
    util = {}
    start_time = os.time()
    sysdig.set_filter("proc.name=memcached and evt.type=read")
    sysdig.set_snaplen(4096)
    data = chisel.request_field("evt.arg[1]")
    return true
end

-- Capture start callback
function on_capture_start()
  islive = sysdig.is_live()
  local refresh = refresh or 1
  if islive then
    chisel.set_interval_s(refresh)
  end
  terminal.clearscreen()
  print("COUNT\t\tBYTES\t\tKEY")
  return true
end

-- Interval callback
function on_interval(ts_s, ts_ns, delta)
  local stop_after = stop_after or 10
  if (os.time() - start_time) > stop_after then sysdig.end_capture() end
  local sum = {}
  local bytes = {}
  local i = 0
  for key,v in pairs(util) do
    local list = v
    sum[key] = 0
    bytes[key] = 0
    while list do
      sum[key] = sum[key] + 1
      bytes[key] = list.bytes
      list = list.next
    end
  end

  local res = results(sort(sum), sum)
  for key, count in pairs(res) do
    local bytes = bytes[key] or 'get'
    print(count.."\t\t"..bytes.."\t\t"..key)
  end

  util = {}
  return true
end

-- Event callback
function on_event()
  local data = evt.field(data)
  local line = split(data, " ")
  if string.match(line[1], '^[gs]et') ~= nil then
    local key = line[2]
    local bytes = line[5]
    if key ~= nil then
      util[key] = { next = util[key], bytes = bytes }
    end
  end
  return true
end

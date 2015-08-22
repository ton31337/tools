--[[
backlogs.lua - inspect every port utilization.

USAGE: sysdig -c backlogs <refresh> <count>
  eg,

  sysdig -c backlogs    # show ports utilization every second and stop after 10 seconds
  sysdig -c 5           # show ports utilization every 5 second and stop after 10 seconds
  sysdig -c '2 20'      # show ports utilization every 2 second and stpo after 20 seconds

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
description = "queue (backlog) utilization"
short_description = "queue utilization"
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
    sport = chisel.request_field("fd.sport")
    queuelen = chisel.request_field("evt.arg[3]")
    queuemax = chisel.request_field("evt.arg[4]")
    syscall = chisel.request_field("evt.type")
    return true
end

-- Capture start callback
function on_capture_start()
  islive = sysdig.is_live()
  local refresh = refresh or 1
  if islive then
    chisel.set_interval_s(refresh)
  end
  print("PORT\t\tBACKLOG\t\tBACKLOGMAX")
  return true
end

-- Interval callback
function on_interval(ts_s, ts_ns, delta)
  local stop_after = stop_after or 10
  local sum = {}
  local num = {}
  if (os.time() - start_time) > stop_after then sysdig.end_capture() end
  for port,v in pairs(util) do
    local list = v
    sum[port] = 0
    num[port] = 0
    local queuemax = list.queuemax
    while list do
      sum[port] = sum[port] + list.queuelen
      num[port] = num[port] + 1
      list = list.next
    end
    if num[port] ~= 0 then
      local avg = math.floor(sum[port] / num[port])
      local pct = math.floor(((avg * 100) / queuemax)) or 0
      print(port.."\t\t"..avg.." ("..pct.."%)\t\t"..queuemax)
    end
  end
  util = {}
  return true
end

-- Event callback
function on_event()
  idx = evt.field(sport)
  local syscall = evt.field(syscall)
  if idx ~= nil and syscall == "accept" then
    util[idx] = { next = util[idx], queuelen = evt.field(queuelen), queuemax = evt.field(queuemax) }
  end
  return true
end

description = "queue (backlog) utilization"
short_description = "queue utilization"
category = "misc"

terminal = require "ansiterminal"

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

function on_init()
    util = {}
    start_time = os.time()
    sport = chisel.request_field("fd.sport")
    queue = chisel.request_field("evt.arg[2]")
    syscall = chisel.request_field("evt.type")
    return true
end

function on_capture_start()
  islive = sysdig.is_live()
  local refresh = refresh or 1
  if islive then
    chisel.set_interval_s(refresh)
  end
  return true
end

function on_interval(ts_s, ts_ns, delta)
  local stop_after = stop_after or 10
  local sum = {}
  local num = {}
  if (os.time() - start_time) > stop_after then sysdig.end_capture() end
  for port,v in pairs(util) do
    local list = v
    sum[port] = 0
    num[port] = 0
    while list do
      sum[port] = sum[port] + list.queue
      num[port] = num[port] + 1
      list = list.next
    end
    if num[port] ~= 0 then
      terminal.clearscreen()
      print("Utilization for port "..port.." is "..(sum[port] / num[port]).."%")
    end
  end
  util = {}
  return true
end

function on_event()
  idx = evt.field(sport)
  local syscall = evt.field(syscall)
  if idx ~= nil and syscall == "accept" then
    util[idx] = { next = util[idx], queue = evt.field(queue) }
  end
  return true
end

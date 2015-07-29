description = "queue (backlog) utilization"
short_description = "queue utilization"
category = "misc"

args =
{
  {
    name = "stop",
    description = "stop tracing after N seconds",
    optional = false
  }
}

function on_set_arg(name, val)
    stop_after = tonumber(val)
    return true
end

function on_init()
    util = {}
    start_time = os.time()
    sport = chisel.request_field("fd.sport")
    queue = chisel.request_field("evt.arg[2]")
    sysdig.set_filter("evt.type=accept")
    chisel.set_interval_s(1)
    return true
end

function on_interval(ts_s, ts_ns, delta)
  if (os.time() - start_time) > stop_after then sysdig.end_capture() end
  local sum = {}
  local num = {}
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
      print("Utilization for port "..port.." is "..(sum[port] / num[port]).."%")
    end
  end
  util = {}
  return true
end

function on_event()
  idx = evt.field(sport)
  if idx ~= nil then
    util[idx] = { next = util[idx], queue = evt.field(queue) }
  end
  return true
end

description = "queue (backlog) utilization"
short_description = "queue utilization"
category = "misc"

args =
{
  {
    name = "port",
    description = "port to monitor",
    argtype = "int"
  },
}

function on_set_arg(name, val)
  port = tonumber(val)
  return true
end

function on_init()
  util = nil
  sport = chisel.request_field("fd.sport")
  queue = chisel.request_field("evt.arg[2]")
  sysdig.set_filter("fd.sport="..port.." and evt.type=accept")
  chisel.set_interval_s(5)
  return true
end

function on_interval(ts_s, ts_ns, delta)
  local list = util
  local sum = 0
  local num = 0
  while list do
    sum = sum + list.queue
    num = num + 1
    list = list.next
  end
  if num ~= 0 then
    print("Utilization for port "..port.." is "..(sum / num).."%")
  end
  util = nil
  return true
end

function on_event()
  util = { next = util, queue = evt.field(queue) }
  return true
end

description = "queue (backlog) utilization"
short_description = "queue utilization"
category = "misc"

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
    queuelen = chisel.request_field("evt.arg[3]")
    queuemax = chisel.request_field("evt.arg[4]")
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
    local queuemax = list.queuemax
    while list do
      sum[port] = sum[port] + list.queuelen
      num[port] = num[port] + 1
      list = list.next
    end
    if num[port] ~= 0 then
      local avg = math.floor(sum[port] / num[port])
      local pct = math.floor(((avg * 100) / queuemax)) or 0
      print("Utilization for port "..port.." is "..avg..":"..queuemax.." ("..pct.."%)")
    end
  end
  util = {}
  return true
end

function on_event()
  idx = evt.field(sport)
  local syscall = evt.field(syscall)
  if idx ~= nil and syscall == "accept" then
    util[idx] = { next = util[idx], queuelen = evt.field(queuelen), queuemax = evt.field(queuemax) }
  end
  return true
end

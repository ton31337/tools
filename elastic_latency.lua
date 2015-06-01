--[[
~$ sysdig -s 110 -c latency.lua 10
15:14:10.480095775  <29.3908> read  [HTTP/1.1 200 OK..Content-Type: application/json; charset=UTF-8..Content-Length: 2341....{\"took\":30,\"timed_out\"] = 2429
15:14:13.076961963  <40.356315> read  [HTTP/1.1 200 OK..Content-Type: application/json; charset=UTF-8..Content-Length: 2339....{\"took\":40,\"timed_out\"] = 2427
15:14:14.716163401  <33.485128> read  [HTTP/1.1 200 OK..Content-Type: application/json; charset=UTF-8..Content-Length: 2341....{\"took\":33,\"timed_out\"] = 2429
15:14:14.909615790  <29.150978> read  [HTTP/1.1 200 OK..Content-Type: application/json; charset=UTF-8..Content-Length: 2785....{\"took\":29,\"timed_out\"] = 2873
--]]

description = "show latencies of syscalls in ms"
short_description = "syscall latencies"
category = "misc"

args =
{
  {
    name = "latency",
    description = "filter by latency in ms",
    argtype = "int"
  },
}

function on_set_arg(name, val)
    latency = tonumber(val)
    return true
end

function on_init()
    fbuf = chisel.request_field("evt.buffer")
    buflen = chisel.request_field("evt.buflen")
    etime = chisel.request_field("evt.latency")
    ctime = chisel.request_field("evt.time")
    syscall = chisel.request_field("evt.type")
    return true
end

function on_event()
    local buf = evt.field(fbuf) or ""
    local len = evt.field(buflen) or 0
    local etime_ms = evt.field(etime) / 1000000

    if tonumber(etime_ms) > latency and len > 32 and string.find(buf, "took") then
      print(evt.field(ctime).."\t<"..etime_ms..">\t"..evt.field(syscall).."\t["..buf.."] = "..len)
    end
    return true
end

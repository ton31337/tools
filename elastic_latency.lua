--[[
~$ sysdig -c elastic_latency.lua 10
13:23:44.451085892  <32.353684> 10.0.11.26  read  2874
13:23:45.200981014  <54.425005> 10.0.11.26  read  2435
13:23:45.590186469  <34.046411> 10.0.11.19  read  2429
13:23:46.718227244  <33.360298> 10.0.11.27  read  2873
13:23:47.456463127  <32.888553> 10.0.11.26  read  2430
13:23:48.463144448  <11.782027> 10.0.11.27  read  2874
13:23:50.750361240  <33.203089> 10.0.11.27  read  2875
13:23:50.914548239  <35.488211> 10.0.11.19  read  2432
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
    server_ip = chisel.request_field("fd.sip")
    sysdig.set_snaplen(110)
    sysdig.set_filter("fd.sport=9200")
    return true
end

function on_event()
    local buf = evt.field(fbuf) or ""
    local len = evt.field(buflen) or 0
    local etime_ms = evt.field(etime) / 1000000
    local syscall = evt.field(syscall)
    local server_ip = evt.field(server_ip) or "null"

    if tonumber(etime_ms) > latency and len > 32 then
      print(evt.field(ctime).."\t<"..etime_ms..">\t"..server_ip.."\t"..syscall.."\t"..len)
    end
    return true
end

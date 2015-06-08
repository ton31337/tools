description = "total connections to es"
short_description = "total connections to es"
category = "misc"

args =
{
  {
    name = "refresh",
    description = "",
    argtype = "int"
  },
}

function on_set_arg(name, val)
    refresh = tonumber(val)
    return true
end

function on_init()
    _accepts = {}
    _total = 0
    etime = chisel.request_field("evt.latency")
    ctime = chisel.request_field("evt.time")
    src_ip = chisel.request_field("fd.cip")
    sysdig.set_filter("fd.sport=9200 and evt.type=accept")
    chisel.set_interval_s(refresh)
    return true
end

function on_interval(ts_s, ts_ns, delta)
    table.sort(_accepts)
    for k,v in pairs(_accepts) do
      print(k.."\t".._accepts[k])
    end
    print("Total connections: ".._total.."/"..refresh.."s\n")
    _accepts = {}
    _total = 0
    return true
end

function on_event()
    local src_ip = evt.field(src_ip)
    _accepts[src_ip] = (_accepts[src_ip] or 0) + 1
    _total = _total + 1
    return true
end

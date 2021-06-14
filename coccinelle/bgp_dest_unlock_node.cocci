// Check for missing bgp_dest_unlock_node.
// bgp_node_lookup/bgp_node_get advances locks.

@r@
identifier dest;
position p;
@@

dest =
(
  bgp_node_lookup@p(...)
|
  bgp_node_get@p(...)
)
...
when != bgp_dest_unlock_node

@script:python@
p << r.p;
@@

coccilib.report.print_report(p[0],"Missing bgp_dest_unlock_node")

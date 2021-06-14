// Check for missing bgp_dest_unlock_node.
// bgp_node_lookup/bgp_node_get advances locks.

@r1@
identifier dest;
position p1;
@@

dest =
(
  bgp_node_lookup@p1(...)
|
  bgp_node_get@p1(...)
)
...
when != bgp_dest_unlock_node

@r2@
identifier dest;
position p1;
statement S1,S;
@@

dest = bgp_node_lookup(...)
...
  when != if (...) bgp_dest_unlock_node(dest);
  when != if (!dest) S1
bgp_dest_unlock_node(dest@p1);

@script:python@
//x1 << r1.p1;
x2 << r2.p1;
@@

//coccilib.report.print_report(x1[0],"Missing bgp_dest_unlock_node")
coccilib.report.print_report(x2[0],"Missing NULL check before bgp_dest_unlock_node")

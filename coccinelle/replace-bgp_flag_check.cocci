// Replace bgp_flag_* to [UN]SET/CHECK_FLAG macros.
// Copyright: (C) 2020 Donatas Abraitis. GPLv2.

@@
expression E1, E2;
@@

(
- bgp_flag_check(E1, E2)
+ CHECK_FLAG(E1->flags, E2)
|
- bgp_flag_set(E1, E2)
+ SET_FLAG(E1->flags, E2)
|
- bgp_flag_unset(E1, E2)
+ UNSET_FLAG(E1->flags, E2)
)

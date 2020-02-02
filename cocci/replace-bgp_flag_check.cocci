// Replace bgp_flag_check() to CHECK_FLAG macro.
// Copyright: (C) 2020 Donatas Abraitis. GPLv2.

@bgp_flag_check@
type T;
T *E;
constant C;
@@

- bgp_flag_check(E, C)
+ CHECK_FLAG(E, C)

@bgp_flag_set@
type T;
T *E;
constant C;
@@

- bgp_flag_set(E, C)
+ SET_FLAG(E, C)

@bgp_flag_unset@
type T;
T *E;
constant C;
@@

- bgp_flag_unset(E, C)
+ UNSET_FLAG(E, C)

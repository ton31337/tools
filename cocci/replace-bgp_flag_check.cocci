// Replace bgp_flag_check() to CHECK_FLAG macro.
// Copyright: (C) 2020 Donatas Abraitis. GPLv2.

@@
type T;
T *E;
constant C;
@@

- bgp_flag_check(E, C)
+ CHECK_FLAG(E, C)

// No more magic numbers for s_addr
// Copyright: (C) 2020 Donatas Abraitis. GPLv2.

@@
expression E;
@@

(
- E.s_addr == 0
+ E.s_addr == INADDR_ANY
|
- E.s_addr != 0
+ E.s_addr != INADDR_ANY
|
- E.s_addr = 0
+ E.s_addr = INADDR_ANY
)

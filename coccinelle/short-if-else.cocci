// Drop parentheses in short-if-else branches
// Copyright: (C) 2020 Donatas Abraitis. GPLv2.

@@
expression e, t;
@@

- if (e) {
+ if (e)
    XFREE(t, e);
- e = NULL;
- }

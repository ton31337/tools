// Double NULL is not needed. It's already handled in XFREE.
// Copyright: (C) 2020 Donatas Abraitis. GPLv2.

@@
type T;
T *pointer;
@@

XFREE(..., pointer);
- pointer = NULL;

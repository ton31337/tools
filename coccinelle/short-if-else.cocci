// Drop parentheses in short-if-else branches
// Copyright: (C) 2020 Donatas Abraitis. GPLv2.

@@
expression E;
@@

(
if (...)
- {
    E;
- }
|
if (...)
{
  E;
} else
- {
    E;
- }
|
if (...)
  E;
else
- {
    E;
- }
)

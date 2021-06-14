// Remove double test

@expression@
expression E;
@@

* E
  || ... || E

@expression@
expression E;
@@

* E
  && ... && E

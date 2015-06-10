redistop.rb
============

### Without any performance impact
```
$ redis-benchmark -p 6380 -c 10 -n 10000 -q -t set,get,mset,expire
SET: 22727.27 requests per second
GET: 23201.86 requests per second
MSET (10 keys): 16528.93 requests per second
```

### With MONITOR
```
$ redis-cli -p 6380 monitor >/dev/null
```
Another console:
```
$ redis-benchmark -p 6380 -c 10 -n 10000 -q -t set,get,mset,expire
SET: 17793.60 requests per second
GET: 16447.37 requests per second
MSET (10 keys): 13698.63 requests per second
```

### With Systemtap
```
Probing...Type CTRL+C to stop probing.
7584  232 <0.000007>  zrangebyscore
7584  46  <0.000569>  zrevrangebyscore
7584  28  <0.000006>  zcard
7584  28  <0.000012>  zrange
7584  19  <0.000022>  zincrby
7584  12  <0.000270>  zadd
7584  12  <0.000004>  zremrangebyrank
7584  12  <0.000003>  expire
7584  10  <0.000005>  del
7584  4 <0.000010>  zrem
```
Another console:
```
$ redis-benchmark -p 6380 -c 10 -n 10000 -q -t set,get,mset,expire
SET: 19685.04 requests per second
GET: 18691.59 requests per second
MSET (10 keys): 15772.87 requests per second
```

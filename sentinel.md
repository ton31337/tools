Every time Redis is doing failover, it calls `sentinelStartFailover()`. Sentinels exchange hello messages using Pub/Sub and updates `last_pub_time` variable. So, let's dig more into this. Here is the snippet ([Systemtap](https://sourceware.org/systemtap/)) I used to probe user-space:
```
probe process("/usr/local/bin/redis-server").function("sentinelStartFailover")
{
        elapsed = gettimeofday_ms() - $master->last_pub_time
        printf("%d.%03ds\n",
                (elapsed / 1000), (elapsed % 1000));
}
```

### Manual failover using redis-cli
```
127.0.0.1:16380> sentinel failover sentinel_de
OK
```
Another console:
```
[root@redis-node1 ~]# stap sentinel.stp
0.835s
```

### /etc/init.d/redis-de stop
```
[root@redis-node1 ~]# /etc/init.d/redis-de stop
Stopping ...
Redis stopped
```
Another console:
```
[root@redis-node1 ~]# stap sentinel.stp
5.843s
```

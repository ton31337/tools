## What are these sysctl parameters?
* tcp_slow_start_after_idle

If set, provide RFC2861 behavior and time out the congestion window after an idle period.  An idle period is defined at the current RTO.  If unset, the congestion window will not be timed out after an idle period.   Default: 1

* tcp_no_metrics_save

By default, TCP saves various connection metrics in the route cache when the connection closes, so that connections established in the near future can use these to set initial conditions.  Usually, this increases overall performance, but may sometimes cause performance degradation.  If set, TCP will not cache metrics on closing connections.

## Tests
### Test #1 (net.ipv4.tcp_slow_start_after_idle=0 / net.ipv4.tcp_no_metrics_save=0)
```
count: 16531, min: 5, max: 383, avg: 31
```

### Test #2 (net.ipv4.tcp_slow_start_after_idle=1 / net.ipv4.tcp_no_metrics_save=0)
```
count: 15250, min: 5, max: 383, avg: 10
```

### Test #3 (net.ipv4.tcp_slow_start_after_idle=0 / net.ipv4.tcp_no_metrics_save=1)
```
count: 15327, min: 5, max: 383, avg: 24
```

### Test #4 (net.ipv4.tcp_slow_start_after_idle=1 / net.ipv4.tcp_no_metrics_save=1)
```
count: 15862, min: 5, max: 383, avg: 10
```

## Results
![](http://donatas.net/slow_start_no_metrics.png)
Looks like the first case has the best performance, while the second has the worst performance. Even if you have tcp_slow_start_after_idle disabled, enabling tcp_no_metrics_save will win some performance. 

## Debug
```
/*
  Show how these tcp-sysctl parameters can boost TCP performance:
    net.ipv4.tcp_slow_start_after_idle
    net.ipv4.tcp_no_metrics_save
  Every time ACK is received, congestion window size is increased acording tcp_abc ip-sysctl parameter.

  @ton31337
*/

%{
#include <linux/tcp.h>
%}

global cwnd;
global counter;
global graph = 0;

function get_cwnd:long(sk:long)
%{
        struct tcp_sock *tp = tcp_sk((struct sock *)STAP_ARG_sk);
        if (tp->snd_cwnd)
                THIS->__retvalue = tp->snd_cwnd;
%}

probe kernel.function("tcp_ack").return
{
        cwnd <<< get_cwnd($sk);
        printf("%d\n", get_cwnd($sk));
        if (graph)
                if (counter++ > 500)
                        exit();
}

probe timer.s(30)
{
        printf("count: %d, min: %d, max: %d, avg: %d\n",
                @count(cwnd), @min(cwnd), @max(cwnd), @avg(cwnd));
        exit();
}
```

## What is tcp_abort_on_overflow?
If listening service is too slow to accept new connections, reset them. Default state is FALSE. It means that if overflow occurred due to a burst, connection will recover. Enable this option _only_ if you are really sure that listening daemon cannot be tuned to accept connections faster. Enabling this option can harm clients of your server.

## More details #1
After some analyzing kernel's [source](http://lxr.free-electrons.com/source/net/ipv4/tcp_minisocks.c#L757) I figured out what this [function](http://lxr.free-electrons.com/source/net/ipv4/tcp_minisocks.c#L559) actually do. If it can't create the child socket it just goes to [listen_overflow](http://lxr.free-electrons.com/source/net/ipv4/tcp_minisocks.c#L768). It returns [NULL](http://lxr.free-electrons.com/source/net/ipv4/tcp_minisocks.c#L790) if `tcp_abort_on_overflow` is disabled (default value), else it sets this packet as [ACK](http://lxr.free-electrons.com/source/net/ipv4/tcp_minisocks.c#L770) and returns NULL. 

## More details #2
I decided to verify how it's really works. I've setup custom web server with [listen](http://linux.die.net/man/2/listen) maximum backlog 5 and ran [ab](https://httpd.apache.org/docs/2.2/programs/ab.html) tool to generate traffic (to overflow backlog). 

### Test #1 (sysctl -w net.ipv4.tcp_abort_on_overflow=0)
```
% ab -n 300 -c 100 http://X.X.X.X/
This is ApacheBench, Version 2.3 <$Revision: 1604373 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking X.X.X.X (be patient)
Completed 100 requests
Completed 200 requests
apr_pollset_poll: The timeout specified has expired (70007)
Total of 294 requests completed
```

### Test #2 (sysctl -w net.ipv4.tcp_abort_on_overflow=1)
```
% ab -n 300 -c 100 http://X.X.X.X/
This is ApacheBench, Version 2.3 <$Revision: 1604373 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking X.X.X.X (be patient)
Completed 100 requests
Completed 200 requests
Completed 300 requests
Finished 300 requests


Server Software:
Server Hostname:        X.X.X.X
Server Port:            80

Document Path:          /
Document Length:        13 bytes

Concurrency Level:      100
Time taken for tests:   4.630 seconds
Complete requests:      300
Failed requests:        61
   (Connect: 0, Receive: 0, Length: 61, Exceptions: 0)
Total transferred:      23183 bytes
HTML transferred:       3107 bytes
Requests per second:    64.80 [#/sec] (mean)
Time per request:       1543.185 [ms] (mean)
Time per request:       15.432 [ms] (mean, across all concurrent requests)
Transfer rate:          4.89 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0  823 1100.2    116    4437
Processing:     4  100 273.5     46    3337
Waiting:        0   42  57.4     15     246
Total:         66  923 1128.7    317    4555
```

As you noticed first test just failed, due to overflowed backlog queue, the second passed without any burst. 

## Debug
As always I've used my favorite tool [Systemtap](https://sourceware.org/systemtap/). With this code I just probe function `tcp_check_req` at the exit point and check for two values: 
* `if return == NULL`
* `if (inet_rsk(req)->acked == 1)`

It means, that if these conditions are met, then `tcp_abort_on_overflow` is disabled and you should take some actions: increase backlog size or enable `tcp_abort_on_overflow` (carefully).

```
%{
#include <net/tcp.h>
%}

function listen_overflow:long(req:long)
%{
        struct request_sock *req = (struct request_sock *)STAP_ARG_req;
        if (inet_rsk(req)->acked == 1)
                THIS->__retvalue = 1;
%}

probe kernel.function("tcp_check_req").return
{
        if (!$return && listen_overflow($req)) {
                printf("listen overflow\n");
                exit();
        }
}
```

## Conclusion
This post was made only to better understand what it is and how it works. 

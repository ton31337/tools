rubytop.rb
==============
```
$ /root/bin/rubytop.rb -h
Usage: rubytop.rb [options]
    -g, --greater <integer>          Filter if latency is greater than X ms
    -n, --num <integer>              Show only X entries
    -p, --path <string>              Ruby path
    -r, --refresh <integer>          Refresh interval
    -s, --sort_time                  Sort by time
    -c, --class <string>             Filter only by class
    -h, --help                       Displays Help
```

### Example
```
$ /root/bin/rubytop.rb -r 3 -n 20 -g 20 -c Catalog
Compiling, please wait...
Probing...Type CTRL+C to stop probing.
<0.023239> tid:26779    count:2        [Catalog#parent_ids] /opt/../catalog.rb:331
<0.264188> tid:26779    count:1        [Catalog#localize] /opt/../catalog.rb:315
```

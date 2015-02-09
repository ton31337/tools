# print socket memory stats in addition to /proc/meminfo
# ruby meminfo.rb
# @ton31337

x = []
ss_output = []
keys = ['Socket_rmem_alloc', 'Socket_wmem_queued', 'Socket_forward_alloc', \
        'Socket_wmem_alloc', 'Socket_rcv_space']

meminfo = File.read('/proc/meminfo')

`/usr/sbin/ss -meipn`.each_line do |line|
        next if not line.start_with?("\t")

        data = line.match(/mem:\(r(\d+),w(\d+),f(\d+),t(\d+)\).+rcv_space:(\d+)/)
        x << data[1..(data.length-1)].map(&:to_i)
end

data = x.transpose.map { |j| j.reduce(:+) }

print meminfo
data.each_with_index { |count,i|
        printf "%s:\t%s kB\n", keys[i], count/1024
}


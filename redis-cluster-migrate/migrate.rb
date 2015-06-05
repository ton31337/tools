=begin
127.0.0.1:6379> cluster slots
1) 1) (integer) 5500
   2) (integer) 10928
   3) 1) "172.17.0.20"
      2) (integer) 6380
   4) 1) "172.17.0.19"
      2) (integer) 6379
2) 1) (integer) 0
   2) (integer) 5499
   3) 1) "172.17.0.20"
      2) (integer) 6379
   4) 1) "172.17.0.19"
      2) (integer) 6380
3) 1) (integer) 10929
   2) (integer) 16383
   3) 1) "172.17.0.18"
      2) (integer) 6379
=end

require './crc16'

slots = 16384
nodes = {
  "1172.17.0.20" => {
    :range => 0..5499,
    :port => 6379
  },
  "2172.17.0.20" => {
    :range => 5500..10928,
    :port => 6380
  },
  "3172.17.0.18" => {
    :range => 10929..16383,
    :port => 6379
  }
}

key = ARGV[0]
slot = RedisClusterCRC16.crc16(key) % slots

nodes.each { |host,val|
  node = host[1..-1]
  port = val[:port]
  if (val[:range]) === slot
    print "redis-cli MIGRATE #{node} #{port} #{key} 0 5000\n"
  end
}

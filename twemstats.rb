#!/opt/rbenv/shims/ruby

require 'socket'
require 'json'

stats = {}
s_stats = []
total = 0

exit! if ARGV[0].nil?

conn = TCPSocket.new '0.0.0.0', 22222
while stream = conn.gets
  stats = JSON.parse(stream)
end

stats.map { |x|
  x.map { |cluster|
    if cluster.instance_of? Hash
      if cluster['client_connections'].to_i > 0
        cluster.map { |s_key,s_val|
          if s_val.instance_of? Hash
            num_of_times_server_was_ejected = ((s_val['server_err'] + s_val['server_timedout'] + s_val['server_eof']) / ARGV[0].to_i)
            print "Server: #{s_key} was ejected #{num_of_times_server_was_ejected} times.\n"
            s_stats << num_of_times_server_was_ejected
          end
        }
      end
    end
  }
}

s_stats.map { |x| total += x }
print "Total ejection count: #{total}\n"

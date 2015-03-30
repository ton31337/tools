#!/opt/rbenv/shims/ruby

require 'socket'
require 'json'

stats = {}
s_stats = {}
req_stats = {}
total = 0

exit! if ARGV[0].nil?

conn = TCPSocket.new '0.0.0.0', 22222
while stream = conn.gets
  stats = JSON.parse(stream)
end

# Collect stats
stats.map { |x|
  x.map { |cluster|
    if cluster.instance_of? Hash
      if cluster['client_connections'].to_i > 0
        cluster.map { |s_key,s_val|
          if s_val.instance_of? Hash
            num_of_times_server_was_ejected = ((s_val['server_err'] + s_val['server_timedout'] + s_val['server_eof']) / ARGV[0].to_i)
            s_stats.merge!(s_key => num_of_times_server_was_ejected)
            req_stats.merge!(s_key => (s_val['request_bytes'] / s_val['requests']))
          end
        }
      end
    end
  }
}

# Print stats
max_size = s_stats.max_by { |k,v| v }.last
s_stats.map { |srv,count|
  print "#{srv.split('.').first} E=#{count} (#{(100 * count) / max_size}%), ReqS=#{req_stats[srv]}\n"
  total += count
}
print "Total ejection count: #{total}\n"

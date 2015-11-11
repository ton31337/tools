NODES = [
  "node1",
  "node2",
  "node3"
]

commands = []
`curl -s localhost:9200/_cat/shards | grep UNASSIGNED`.each_line do |shard|
  res = shard.split(' ')
  idx = res[0]
  shrd = res[1]

  current_hosts = []
  `curl -s localhost:9200/_cat/shards | grep STARTED`.each_line do |line|
    res = line.split(' ')
    if res[0] == idx && res[1] == shrd
      current_hosts << res[7]
    end
  end

  (NODES - current_hosts).each do |host|
    commands << "curl -XPOST -d '{ \"commands\" : [ { \"allocate\" : { \"index\" : \"#{idx}\", \"shard\": #{shrd}, \"node\": \"#{host}\" } } ] }'"
  end

end

commands.uniq.each do |cmd|
  print "#{cmd}\n"
  `#{cmd} 'http://localhost:9200/_cluster/reroute?pretty' &>/dev/null`
end

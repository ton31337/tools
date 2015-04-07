server_list = []

# get server list
File.open('/etc/nutcracker.yml').each_line do |line|
        x = /- (.+):(\d+):(\d+)$/.match(line)
        server_list << "#{x[1]}:#{x[2]}" unless x.nil?
end
server_list.uniq!

# iterate over every server and print if slab is full
server_list.each { |srv|
        print "#{srv}\n"
        print "   #  Item_Size  Max_age   Pages   Count   Full?  Evicted Evict_Time OOM\n"
        `memcached-tool #{srv}`.each_line do |line|
                print line if line.include?('yes')
        end
}


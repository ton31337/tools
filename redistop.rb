#!/opt/rbenv/shims/ruby
# prints mostly used functions
# @ton31337 <donatas.abraitis@gmail.com>

require 'optparse'

options = {:count => 20,
           :refresh => 1,
           :sort => nil,
           :include => nil,
           :exclude => nil,
           :gt => 0}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: rubytop.rb [options]"

  opts.on('-g', '--greater <integer>', 'Filter if latency is greater than X ms') do |gt|
    options[:gt] = gt.to_i * 1000
  end

  opts.on('-e', '--exclude <string>', 'Exclude cmd') do |exclude|
    options[:exclude] = exclude
  end

  opts.on('-i', '--include <string>', 'Include cmd') do |inc|
    options[:include] = inc
  end

  opts.on('-n', '--num <integer>', 'Show only X entries') do |count|
    options[:count] = count
  end

  opts.on('-r', '--refresh <integer>', 'Refresh interval') do |refresh|
    options[:refresh] = refresh
  end

  opts.on('-s', '--sort_time', 'Sort by time') do |sort|
    options[:sort] = true
  end

  opts.on('-h', '--help', 'Displays Help') do
    puts opts
    exit
  end

end

parser.parse!

content = <<EOF
global cmds;
global times;

@define SKIP(x,y) %( if(isinstr(@x, @y)) next; %)
@define INCLUDE(x,y) %( if(!isinstr(@x, @y)) next; %)

probe process("/usr/local/bin/redis-server").function("call").return
{
        etime = gettimeofday_us() - @entry(gettimeofday_us());
        cmd = user_string($c->cmd->name);
EOF
content += <<EOF if options[:exclude]
        @SKIP(cmd, \"#{options[:exclude]}\");
EOF
content += <<EOF if options[:include]
        @INCLUDE(cmd, \"#{options[:include]}\");
EOF
content += <<EOF
        cmds[tid(), cmd]++;
        times[tid(), cmd] = etime;
}

probe timer.s(#{options[:refresh]}) {
        ansi_clear_screen();
        println("Probing...Type CTRL+C to stop probing.");
        foreach([tid, cmd] in #{options[:sort] ? 'times' : 'cmds'}- limit #{options[:count]}) {
                etime = times[tid, cmd];
                printf("%d\\t%d\\t<%d.%06d>\\t%s\\n",
                        tid,
                        cmds[tid, cmd],
                        (etime / 1000000),
                        (etime % 1000000),
                        cmd);
        }
        delete cmds;
        delete times;
}
EOF

print "Compiling, please wait...\n"
IO.popen("echo '#{content}' | stap -DMAXMAPENTRIES=102400 -g --suppress-time-limits -") do |cmd|
  print $_ while cmd.gets
end
